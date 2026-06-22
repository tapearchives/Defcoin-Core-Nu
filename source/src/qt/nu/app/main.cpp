#include "NuPlatformIntegration.h"
#include "NuRpcService.h"
#include "NuVelopackUpdater.h"
#if defined(__APPLE__)
#include "MacHelp.h"
#endif

#include <QApplication>
#include <QColor>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QHash>
#include <QIODevice>
#include <QIcon>
#include <QImage>
#include <QLinearGradient>
#include <QLockFile>
#include <QMessageBox>
#include <QMetaObject>
#include <QPainter>
#include <QPixmap>
#include <QProcess>
#include <QPushButton>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QScreen>
#include <QSettings>
#include <QSplashScreen>
#include <QStyleHints>
#include <QTextStream>
#include <QThread>
#include <QTimer>
#include <QUrl>
#include <QVariant>
#include <QWidget>
#include <QWindow>
#include <QtQml/qqml.h>

#include <cstdio>
#include <cstdlib>
#include <memory>

#if defined(Q_OS_WIN)
#include <windows.h>
#endif

namespace {
constexpr bool kNuHelpEnabled = DEFCOIN_NU_HELP_ENABLED != 0;

QFile* gLaunchLogFile = nullptr;
QtMessageHandler gPreviousMessageHandler = nullptr;

QString productName()
{
    return QStringLiteral("Defcoin Core Nu");
}

QString productBundleIdentifier()
{
    return QStringLiteral("org.defcoincore.DefcoinCoreNu");
}

void writeLaunchLogLine(const QString& message)
{
    if (!gLaunchLogFile || !gLaunchLogFile->isOpen())
        return;

    QTextStream out(gLaunchLogFile);
    out << QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss.zzz t")) << ' '
        << message.trimmed() << '\n';
    out.flush();
    gLaunchLogFile->flush();
}

void loadBundledNuFonts(const QString& resourceRoot)
{
    const QStringList fontFiles{
        QStringLiteral("AtkinsonHyperlegibleMono-Regular.ttf"),
        QStringLiteral("AtkinsonHyperlegibleMono-Bold.ttf"),
        QStringLiteral("AtkinsonHyperlegibleMono-Italic.ttf"),
        QStringLiteral("AtkinsonHyperlegibleMono-BoldItalic.ttf"),
    };

    for (const QString& fontFile : fontFiles) {
        const QString fontPath = QDir(resourceRoot).filePath(QStringLiteral("assets/fonts/%1").arg(fontFile));
        const int fontId = QFontDatabase::addApplicationFont(fontPath);
        if (fontId < 0) {
            qWarning() << "Unable to load bundled Nu font" << fontPath;
        }
    }
}

void nuQtMessageHandler(QtMsgType type, const QMessageLogContext& context, const QString& message)
{
    QString level;
    switch (type) {
    case QtDebugMsg:
        level = QStringLiteral("debug");
        break;
    case QtInfoMsg:
        level = QStringLiteral("info");
        break;
    case QtWarningMsg:
        level = QStringLiteral("warning");
        break;
    case QtCriticalMsg:
        level = QStringLiteral("critical");
        break;
    case QtFatalMsg:
        level = QStringLiteral("fatal");
        break;
    }

    QString line = QStringLiteral("[%1] %2").arg(level, message);
    if (context.file && context.line > 0) {
        line += QStringLiteral(" (%1:%2)").arg(QString::fromUtf8(context.file), QString::number(context.line));
    }
    writeLaunchLogLine(line);

    if (gPreviousMessageHandler) {
        gPreviousMessageHandler(type, context, message);
    } else {
        std::fprintf(stderr, "%s\n", qPrintable(line));
    }

    if (type == QtFatalMsg)
        std::abort();
}

bool tryAcquireSingleInstanceLock(QLockFile& lock)
{
    if (lock.tryLock(100)) {
        return true;
    }
    if (lock.removeStaleLockFile()) {
        return lock.tryLock(100);
    }
    return false;
}

enum class SingleInstanceAction { CheckAgain, CloseOther, Quit };

QString singleInstanceOwnerText(QLockFile& lock)
{
    qint64 pid = 0;
    QString hostname;
    QString appname;
    if (!lock.getLockInfo(&pid, &hostname, &appname)) {
        return QStringLiteral("Nu could not read the other window's process details.");
    }

    QStringList details;
    if (pid > 0) {
        details << QStringLiteral("PID %1").arg(pid);
    }
    if (!appname.isEmpty()) {
        details << appname;
    }
    if (!hostname.isEmpty()) {
        details << QStringLiteral("host %1").arg(hostname);
    }
    return details.isEmpty() ? QStringLiteral("Nu could not read the other window's process details.") :
                               details.join(QStringLiteral(" • "));
}

bool requestSingleInstanceOwnerClose(QLockFile& lock)
{
    qint64 pid = 0;
    QString hostname;
    QString appname;
    if (!lock.getLockInfo(&pid, &hostname, &appname) || pid <= 0 || pid == QCoreApplication::applicationPid()) {
        return false;
    }

#if defined(Q_OS_WIN)
    return QProcess::execute(QStringLiteral("taskkill"),
                             {QStringLiteral("/PID"), QString::number(pid), QStringLiteral("/T")}) == 0;
#else
    return QProcess::execute(QStringLiteral("/bin/kill"), {QStringLiteral("-TERM"), QString::number(pid)}) == 0;
#endif
}

SingleInstanceAction promptSingleInstanceConflict(QLockFile& lock, const QString& name, const QString& dataDir)
{
    QMessageBox box(QMessageBox::Warning,
                    QStringLiteral("%1 is already open").arg(name),
                    QStringLiteral("Another %1 window is still using this data directory.").arg(name));
    box.setInformativeText(QStringLiteral("%1\n\nClose the other window, then press OK to check again. "
                                          "You can also ask Nu to close the other instance for you.")
                               .arg(singleInstanceOwnerText(lock)));
    box.setDetailedText(QStringLiteral("Data directory:\n%1").arg(dataDir));
    QPushButton* checkAgainButton = box.addButton(QStringLiteral("OK"), QMessageBox::AcceptRole);
    QPushButton* closeOtherButton = box.addButton(QStringLiteral("Close Other Instance"), QMessageBox::DestructiveRole);
    box.addButton(QStringLiteral("Quit"), QMessageBox::RejectRole);
    box.setDefaultButton(checkAgainButton);
    box.exec();

    if (box.clickedButton() == closeOtherButton) {
        return SingleInstanceAction::CloseOther;
    }
    if (box.clickedButton() == checkAgainButton) {
        return SingleInstanceAction::CheckAgain;
    }
    return SingleInstanceAction::Quit;
}

QHash<QString, QString> readBuildInfoProperties(const QString& resourceRoot)
{
    QHash<QString, QString> values;
    QFile file(QDir(resourceRoot).filePath(QStringLiteral("BUILD_INFO.properties")));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return values;
    }
    while (!file.atEnd()) {
        const QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) {
            continue;
        }
        const int equals = line.indexOf(QLatin1Char('='));
        if (equals <= 0) {
            continue;
        }
        values.insert(line.left(equals).trimmed(), line.mid(equals + 1).trimmed());
    }
    return values;
}

void drawNuBrandSplash(QPixmap& pixmap, const QString& resourceRoot)
{
    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
    painter.setRenderHint(QPainter::TextAntialiasing, true);

    const QRect panel(0, 0, pixmap.width(), pixmap.height());
    QLinearGradient panelGradient(panel.topLeft(), panel.bottomLeft());
    panelGradient.setColorAt(0.0, QColor("#0e0418"));
    panelGradient.setColorAt(0.34, QColor("#08030f"));
    panelGradient.setColorAt(1.0, QColor("#05080a"));
    painter.fillRect(panel, panelGradient);

    painter.setPen(QColor(84, 42, 132, 40));
    for (int y = panel.top(); y < panel.bottom(); y += 12) {
        painter.drawLine(panel.left(), y, panel.right(), y);
    }
    painter.setPen(QColor(246, 246, 242, 7));
    for (int x = panel.left(); x < panel.right(); x += 12) {
        painter.drawLine(x, panel.top(), x, panel.bottom());
    }

    const QPixmap lockup(resourceRoot + QStringLiteral("/assets/brand/defcoin-core-nu-lockup.png"));
    if (!lockup.isNull()) {
        constexpr double kBaseWordmarkSize = 256.0;
        constexpr double kSplashWordmarkSize = 58.0;
        const QSize targetSize(qRound(lockup.width() * (kSplashWordmarkSize / kBaseWordmarkSize)),
                               qRound(lockup.height() * (kSplashWordmarkSize / kBaseWordmarkSize)));
        const int heroBottom = pixmap.height() - 74;
        const QRect targetRect((panel.width() - targetSize.width()) / 2,
                               qMax(12, (heroBottom - targetSize.height()) / 2),
                               targetSize.width(),
                               targetSize.height());
        painter.setOpacity(0.96);
        painter.drawPixmap(targetRect, lockup);
        painter.setOpacity(1.0);
        return;
    }
}

#if defined(Q_OS_WIN)
void holdTopmostBriefly(QWidget* context, HWND hwnd)
{
    if (!context || !hwnd)
        return;
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
    QTimer::singleShot(2200, context, [context] {
        HWND current_hwnd = reinterpret_cast<HWND>(context->winId());
        if (!current_hwnd)
            return;
        SetWindowPos(current_hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        BringWindowToTop(current_hwnd);
        SetForegroundWindow(current_hwnd);
    });
}

void holdTopmostBriefly(QWindow* context, HWND hwnd)
{
    if (!context || !hwnd)
        return;
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
    QTimer::singleShot(2200, context, [context] {
        HWND current_hwnd = reinterpret_cast<HWND>(context->winId());
        if (!current_hwnd)
            return;
        SetWindowPos(current_hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        BringWindowToTop(current_hwnd);
        SetForegroundWindow(current_hwnd);
        context->raise();
        context->requestActivate();
    });
}
#endif

bool platformSupportsWindowActivation()
{
    const QString platform = QGuiApplication::platformName().toLower();
    return !platform.contains(QStringLiteral("offscreen")) && !platform.contains(QStringLiteral("minimal"));
}

void activateWindowForUser(QQuickWindow* window)
{
    if (!window)
        return;
#if defined(Q_OS_MACOS)
    ActivateDefcoinNuMacApplication();
#endif
    if (QScreen* screen = QGuiApplication::primaryScreen()) {
        window->setScreen(screen);
        const QRect available = screen->availableGeometry();
        QRect geometry = window->geometry();
        if (geometry.width() <= 0 || geometry.height() <= 0) {
            geometry.setSize(QSize(1280, 820));
        }
        if (!available.intersects(geometry)) {
            const int x = available.x() + qMax(0, (available.width() - geometry.width()) / 2);
            const int y = available.y() + qMax(0, (available.height() - geometry.height()) / 2);
            window->setPosition(x, y);
        }
    }
    window->setVisibility(QWindow::Windowed);
    window->showNormal();
    if (window->windowState() == Qt::WindowMinimized) {
        window->setWindowState(Qt::WindowNoState);
    }
    if (platformSupportsWindowActivation()) {
        window->raise();
        window->requestActivate();
    }
#if defined(Q_OS_WIN)
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (hwnd) {
        const DWORD foreground_thread = GetWindowThreadProcessId(GetForegroundWindow(), nullptr);
        const DWORD current_thread = GetCurrentThreadId();
        if (foreground_thread != 0 && foreground_thread != current_thread) {
            AttachThreadInput(current_thread, foreground_thread, TRUE);
        }
        AllowSetForegroundWindow(ASFW_ANY);
        ShowWindow(hwnd, SW_RESTORE);
        BringWindowToTop(hwnd);
        SetForegroundWindow(hwnd);
        holdTopmostBriefly(window, hwnd);
        if (foreground_thread != 0 && foreground_thread != current_thread) {
            AttachThreadInput(current_thread, foreground_thread, FALSE);
        }
    }
#endif
}

void activateTopLevelWindowsForUser()
{
#if defined(Q_OS_MACOS)
    ActivateDefcoinNuMacApplication();
#endif
    for (QWindow* window : QGuiApplication::topLevelWindows()) {
        if (!window || !window->isVisible())
            continue;
        if (auto* quickWindow = qobject_cast<QQuickWindow*>(window)) {
            activateWindowForUser(quickWindow);
            continue;
        }
        window->setVisibility(QWindow::Windowed);
        window->showNormal();
        if (platformSupportsWindowActivation()) {
            window->raise();
            window->requestActivate();
        }
    }
}

void activateSplashForUser(QSplashScreen* splash)
{
    if (!splash)
        return;
    splash->show();
    if (platformSupportsWindowActivation()) {
        splash->raise();
        splash->activateWindow();
    }
#if defined(Q_OS_WIN)
    HWND hwnd = reinterpret_cast<HWND>(splash->winId());
    if (hwnd) {
        AllowSetForegroundWindow(ASFW_ANY);
        ShowWindow(hwnd, SW_RESTORE);
        BringWindowToTop(hwnd);
        SetForegroundWindow(hwnd);
        holdTopmostBriefly(splash, hwnd);
    }
#endif
}

QString nuDefaultDataDir()
{
    if (!qEnvironmentVariableIsEmpty("DEFCOIN_DATADIR")) {
        return QString::fromLocal8Bit(qgetenv("DEFCOIN_DATADIR"));
    }
#if defined(Q_OS_WIN)
    return QDir(QString::fromLocal8Bit(qgetenv("APPDATA"))).filePath(QStringLiteral("Defcoin"));
#elif defined(Q_OS_MACOS)
    return QDir(QDir::homePath()).filePath(QStringLiteral("Library/Application Support/Defcoin"));
#else
    return QDir(QDir::homePath()).filePath(QStringLiteral(".defcoin"));
#endif
}

void initializeLaunchLog(const QString& dataDir)
{
    QDir().mkpath(dataDir);
    const QString path = QDir(dataDir).filePath(QStringLiteral("nu-gui-launch.log"));
    gLaunchLogFile = new QFile(path);
    if (!gLaunchLogFile->open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        delete gLaunchLogFile;
        gLaunchLogFile = nullptr;
        return;
    }
    writeLaunchLogLine(
        QStringLiteral("===== %1 %2 launch log started =====").arg(productName(), QStringLiteral(DEFCOIN_NU_VERSION)));
    writeLaunchLogLine(QStringLiteral("Launch log path: %1").arg(QDir::toNativeSeparators(path)));
}

class StartupReporter
{
public:
    explicit StartupReporter(bool show_splash_status_indicator)
        : m_show_splash_status_indicator(show_splash_status_indicator)
    {
    }

    void start()
    {
        m_elapsed.start();
    }

    void setSplash(QSplashScreen* splash)
    {
        m_splash = splash;
    }

    void step(const QString& message)
    {
        const QString clean = message.trimmed();
        writeLaunchLogLine(
            QStringLiteral("Startup phase at %1s: %2").arg(QString::number(elapsedSeconds(), 'f', 1), clean));
        if (!m_splash)
            return;
        if (!m_show_splash_status_indicator)
            return;

        m_splash->showMessage(QStringLiteral("\n\n%1  |  %2s").arg(clean, QString::number(elapsedSeconds(), 'f', 1)),
                              Qt::AlignHCenter | Qt::AlignTop,
                              QColor("#f6f6f2"));
        QApplication::processEvents(QEventLoop::AllEvents, 25);
    }

private:
    double elapsedSeconds() const
    {
        return m_elapsed.isValid() ? static_cast<double>(m_elapsed.elapsed()) / 1000.0 : 0.0;
    }

    QElapsedTimer m_elapsed;
    bool m_show_splash_status_indicator = false;
    QSplashScreen* m_splash = nullptr;
};

QString uiSelfTestScreenshotDir()
{
    if (qEnvironmentVariableIsEmpty("DEFCOIN_NU_UI_SELF_TEST_SCREENSHOTS"))
        return QString();
    return QString::fromLocal8Bit(qgetenv("DEFCOIN_NU_UI_SELF_TEST_SCREENSHOTS")).trimmed();
}

QString uiSelfTestFileName(QString label)
{
    label = label.trimmed().toLower();
    QString out;
    out.reserve(label.size());
    bool lastDash = false;
    for (const QChar ch : label) {
        if (ch.isLetterOrNumber()) {
            out.append(ch);
            lastDash = false;
        } else if (!lastDash) {
            out.append(QLatin1Char('-'));
            lastDash = true;
        }
    }
    while (out.startsWith(QLatin1Char('-')))
        out.remove(0, 1);
    while (out.endsWith(QLatin1Char('-')))
        out.chop(1);
    return out.isEmpty() ? QStringLiteral("screen") : out;
}

void uiSelfTestSettle(QApplication& app, int milliseconds = 500)
{
    QElapsedTimer timer;
    timer.start();
    while (timer.elapsed() < milliseconds) {
        app.processEvents(QEventLoop::AllEvents, 50);
        QThread::msleep(15);
    }
}

QQuickWindow* uiSelfTestVisibleWindow(QQuickWindow* rootWindow)
{
    QQuickWindow* target = rootWindow;
    for (QWindow* window : QGuiApplication::topLevelWindows()) {
        auto* quick = qobject_cast<QQuickWindow*>(window);
        if (quick && quick->isVisible()) {
            target = quick;
        }
    }
    return target;
}

bool uiSelfTestSaveScreenshot(QQuickWindow* rootWindow, const QString& dir, const QString& label)
{
    if (dir.isEmpty())
        return true;
    QDir().mkpath(dir);
    QQuickWindow* target = uiSelfTestVisibleWindow(rootWindow);
    if (!target)
        return false;
    const QString path = QDir(dir).filePath(uiSelfTestFileName(label) + QStringLiteral(".png"));
    const QImage image = target->grabWindow();
    const bool saved = !image.isNull() && image.save(path) && QFileInfo(path).size() > 0;
    writeLaunchLogLine(
        QStringLiteral("UI self-test screenshot %1: %2")
            .arg(saved ? QStringLiteral("saved") : QStringLiteral("failed"), QDir::toNativeSeparators(path)));
    return saved;
}

void uiSelfTestClosePopups(QApplication& app, QObject* rootObject)
{
    if (rootObject) {
        QMetaObject::invokeMethod(rootObject, "uiSelfTestClosePopups");
    }
    uiSelfTestSettle(app, 220);
}

int runQtQuickUiSelfTest(QApplication& app, QObject* rootObject, QQuickWindow* rootWindow, NuRpcService& service)
{
    const QString screenshotDir = uiSelfTestScreenshotDir();
    bool ok = rootObject && rootWindow;
    if (!ok) {
        writeLaunchLogLine(QStringLiteral("UI self-test failed: root window missing."));
        return 3;
    }

    if (!qEnvironmentVariableIsEmpty("DEFCOIN_NU_PAPER_WALLET_PDF") &&
        !qEnvironmentVariableIsEmpty("DEFCOIN_NU_PAPER_WALLET_RENDER_ONLY")) {
        service.installPaperWalletSelfTestData();
        const bool hide_art = qEnvironmentVariableIntValue("DEFCOIN_NU_PAPER_WALLET_HIDE_ART") > 0;
        service.printPaperWallet(0, 3, 3, hide_art);
        uiSelfTestSettle(app, 250);
        writeLaunchLogLine(QStringLiteral("UI self-test paper wallet PDF render-only requested."));
        return 0;
    }

    QStringList routes = QStringList() << QStringLiteral("home") << QStringLiteral("send") << QStringLiteral("receive")
                                       << QStringLiteral("activity") << QStringLiteral("wallet")
                                       << QStringLiteral("mining") << QStringLiteral("rpc") << QStringLiteral("node")
                                       << QStringLiteral("settings");
    const QString route_filter = qEnvironmentVariable("DEFCOIN_NU_UI_SELF_TEST_ROUTE").trimmed();
    if (!route_filter.isEmpty())
        routes = {route_filter};

    writeLaunchLogLine(QStringLiteral("UI self-test begin."));
    for (const QString& route : routes) {
        if (route == QLatin1String("mining") || route == QLatin1String("rpc") || route == QLatin1String("node") ||
            route == QLatin1String("settings")) {
            service.setProperty("advancedToolsVisible", true);
        }
        rootObject->setProperty("currentRoute", route);
        uiSelfTestSettle(app, route == QLatin1String("paper") ? 900 : 650);
        if (route == QLatin1String("wallet") && !qEnvironmentVariableIsEmpty("DEFCOIN_NU_UI_SELF_TEST_PAPER_WALLET")) {
            const bool opened = QMetaObject::invokeMethod(rootObject, "uiSelfTestOpenPaperWalletTab");
            if (!opened) {
                ok = false;
                writeLaunchLogLine(QStringLiteral("UI self-test failed: Paper Wallet tab hook missing."));
            }
            uiSelfTestSettle(app, 900);
        } else if (route == QLatin1String("settings") &&
                   !qEnvironmentVariableIsEmpty("DEFCOIN_NU_UI_SELF_TEST_SETTINGS_TAB")) {
            const QString settingsTab = qEnvironmentVariable("DEFCOIN_NU_UI_SELF_TEST_SETTINGS_TAB").trimmed();
            const bool opened = QMetaObject::invokeMethod(
                rootObject, "uiSelfTestOpenSettingsTab", Q_ARG(QVariant, QVariant(settingsTab)));
            if (!opened) {
                ok = false;
                writeLaunchLogLine(QStringLiteral("UI self-test failed: Settings tab hook missing."));
            }
            uiSelfTestSettle(app, 450);
        } else if (route == QLatin1String("mining") &&
                   !qEnvironmentVariableIsEmpty("DEFCOIN_NU_UI_SELF_TEST_MINING_TAB")) {
            const QString miningTab = qEnvironmentVariable("DEFCOIN_NU_UI_SELF_TEST_MINING_TAB").trimmed();
            const bool opened =
                QMetaObject::invokeMethod(rootObject, "uiSelfTestOpenMiningTab", Q_ARG(QVariant, QVariant(miningTab)));
            if (!opened) {
                ok = false;
                writeLaunchLogLine(QStringLiteral("UI self-test failed: Mining tab hook missing."));
            }
            uiSelfTestSettle(app, 450);
        }
        writeLaunchLogLine(QStringLiteral("UI self-test route: %1").arg(route));
        ok = uiSelfTestSaveScreenshot(rootWindow, screenshotDir, QStringLiteral("route-%1").arg(route)) && ok;
    }

    if (!qEnvironmentVariableIsEmpty("DEFCOIN_NU_PAPER_WALLET_PDF")) {
        service.installPaperWalletSelfTestData();
        const bool hide_art = qEnvironmentVariableIntValue("DEFCOIN_NU_PAPER_WALLET_HIDE_ART") > 0;
        service.printPaperWallet(0, 3, 3, hide_art);
        uiSelfTestSettle(app, 250);
        writeLaunchLogLine(QStringLiteral("UI self-test paper wallet PDF render requested."));
    }

    const QStringList dialogs = QStringList()
                                << QStringLiteral("about") << QStringLiteral("build-notes") << QStringLiteral("help")
                                << QStringLiteral("create-wallet") << QStringLiteral("create-recovery-wallet")
                                << QStringLiteral("restore-recovery-wallet") << QStringLiteral("open-uri")
                                << QStringLiteral("sign-message") << QStringLiteral("verify-message");

    for (const QString& dialogName : dialogs) {
        uiSelfTestClosePopups(app, rootObject);
        const bool opened =
            QMetaObject::invokeMethod(rootObject, "uiSelfTestOpenMenuDialog", Q_ARG(QVariant, QVariant(dialogName)));
        if (!opened) {
            ok = false;
            writeLaunchLogLine(QStringLiteral("UI self-test failed: dialog hook missing for %1.").arg(dialogName));
            continue;
        }
        uiSelfTestSettle(app, 650);
        writeLaunchLogLine(QStringLiteral("UI self-test dialog/menu action: %1").arg(dialogName));
        ok = uiSelfTestSaveScreenshot(rootWindow, screenshotDir, QStringLiteral("dialog-%1").arg(dialogName)) && ok;
        uiSelfTestClosePopups(app, rootObject);
    }

    writeLaunchLogLine(ok ? QStringLiteral("UI self-test done.") : QStringLiteral("UI self-test completed with gaps."));
    return ok ? 0 : 3;
}

} // namespace

int main(int argc, char* argv[])
{
#if defined(Q_OS_MACOS)
    PrepareDefcoinNuMacLaunchState();
#endif
    QApplication app(argc, argv);
    QApplication::setApplicationName(productName());
    QApplication::setApplicationDisplayName(productName());
    QApplication::setOrganizationName("Defcoin Core");
    QApplication::setOrganizationDomain("defcoincore.org");
    QApplication::setFont(QFont(QStringLiteral("Arial")));
    QGuiApplication::styleHints()->setTabFocusBehavior(Qt::TabFocusAllControls);
    initializeLaunchLog(nuDefaultDataDir());
    gPreviousMessageHandler = qInstallMessageHandler(nuQtMessageHandler);
    StartupReporter startup(QSettings().value(QStringLiteral("ShowStartupSplashStatusIndicator"), false).toBool());
    startup.start();
    startup.step(QStringLiteral("Preparing application startup."));

    QQuickStyle::setStyle("Basic");

#ifdef Q_OS_MACOS
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString pluginDir = QDir(appDir).filePath("../PlugIns");
    if (QDir(pluginDir).exists())
        QCoreApplication::setLibraryPaths({pluginDir});
    const QString resourceRoot = QDir(appDir).filePath("../Resources/nu");
    const QString deployedQmlRoot = QDir(appDir).filePath("../Resources/qml");
#else
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString pluginDir = QDir(appDir).filePath("plugins");
    if (QDir(pluginDir).exists())
        QCoreApplication::setLibraryPaths({pluginDir});
    const QString resourceRoot = QDir(appDir).filePath("nu");
    const QString deployedQmlRoot = QDir(appDir).filePath("qml");
#endif
    loadBundledNuFonts(resourceRoot);
    const QStringList arguments = app.arguments();
    const bool allowDebugEnvironment = arguments.contains(QStringLiteral("--debug-use-env")) ||
                                       !qEnvironmentVariableIsEmpty("DEFCOIN_NU_ALLOW_DEBUG_ENV");
    if (!allowDebugEnvironment) {
        qunsetenv("DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC");
        qunsetenv("DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC");
        qunsetenv("DEFCOIN_NU_DEBUG_DISABLE_FAST_SYNC");
        qunsetenv("DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE");
        qunsetenv("DEFCOIN_NU_DEBUG_FAST_SYNC_LAN_ONLY");
        qunsetenv("DEFCOIN_NU_QUICK_CLONE_NOW");
    }
    const bool buildSmokeTest = !qEnvironmentVariableIsEmpty("DEFCOIN_NU_SMOKE_TEST");
    const bool smokeTest = arguments.contains(QStringLiteral("--smoke-test")) || buildSmokeTest;
    const bool uiSelfTest =
        arguments.contains(QStringLiteral("--ui-self-test")) || !qEnvironmentVariableIsEmpty("DEFCOIN_NU_UI_SELF_TEST");
    if (uiSelfTest) {
        qputenv("DEFCOIN_NU_NO_BACKEND_AUTOSTART", "1");
        qputenv("DEFCOIN_NU_UI_SELF_TEST_ACTIVE", "1");
    }
    startup.step(QStringLiteral("Parsed launch arguments."));
    if (buildSmokeTest && !uiSelfTest) {
        return 0;
    }
    const bool allowMultiple = arguments.contains(QStringLiteral("--allow-multiple"));
    const bool quickCloneNow = arguments.contains(QStringLiteral("--quick-clone-now")) ||
                               !qEnvironmentVariableIsEmpty("DEFCOIN_NU_QUICK_CLONE_NOW");
    if (arguments.contains(QStringLiteral("--debug-disable-core-tcp-sync"))) {
        qputenv("DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC", "1");
    }
    if (arguments.contains(QStringLiteral("--debug-disable-core-sync"))) {
        qputenv("DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC", "1");
    }
    if (arguments.contains(QStringLiteral("--debug-disable-fast-sync"))) {
        qputenv("DEFCOIN_NU_DEBUG_DISABLE_FAST_SYNC", "1");
    }
    if (arguments.contains(QStringLiteral("--debug-disable-quick-clone"))) {
        qputenv("DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE", "1");
    }
    if (arguments.contains(QStringLiteral("--debug-fast-sync-lan-only"))) {
        qputenv("DEFCOIN_NU_DEBUG_FAST_SYNC_LAN_ONLY", "1");
    }

    std::unique_ptr<QLockFile> singleInstanceLock;
    if (!smokeTest && !uiSelfTest && !allowMultiple) {
        startup.step(QStringLiteral("Checking single-instance data-directory lock."));
        const QString dataDir = nuDefaultDataDir();
        QDir().mkpath(dataDir);
        singleInstanceLock =
            std::make_unique<QLockFile>(QDir(dataDir).filePath(QStringLiteral("defcoin-core-nu-gui.lock")));
        singleInstanceLock->setStaleLockTime(30000);
        bool hasSingleInstanceLock = tryAcquireSingleInstanceLock(*singleInstanceLock);
        while (!hasSingleInstanceLock) {
            const SingleInstanceAction action =
                promptSingleInstanceConflict(*singleInstanceLock, productName(), dataDir);
            if (action == SingleInstanceAction::Quit) {
                return 2;
            }
            if (action == SingleInstanceAction::CloseOther) {
                requestSingleInstanceOwnerClose(*singleInstanceLock);
            }
            for (int attempt = 0; attempt < 20 && !hasSingleInstanceLock; ++attempt) {
                QApplication::processEvents(QEventLoop::AllEvents, 50);
                hasSingleInstanceLock = tryAcquireSingleInstanceLock(*singleInstanceLock);
                if (!hasSingleInstanceLock) {
                    QThread::msleep(250);
                }
            }
        }
        startup.step(QStringLiteral("Single-instance lock acquired."));
    }

    bool velopackHookLaunch =
        !qEnvironmentVariableIsEmpty("VELOPACK_FIRSTRUN") || !qEnvironmentVariableIsEmpty("VELOPACK_RESTART");
    for (const QString& argument : arguments) {
        if (argument.startsWith(QStringLiteral("--veloapp-"))) {
            velopackHookLaunch = true;
            break;
        }
    }
    if (!smokeTest && !uiSelfTest && velopackHookLaunch) {
        startup.step(QStringLiteral("Running update startup hook."));
        NuVelopackUpdater::runStartupHook(appDir);
    }

    QIcon appIcon;
    appIcon.addFile(resourceRoot + "/assets/brand/defcoin-nu-icon-1024.png", QSize(256, 256));
    appIcon.addFile(resourceRoot + "/assets/brand/defcoin-nu-icon-1024.png", QSize(1024, 1024));
    appIcon.addFile(resourceRoot + "/assets/brand/DefcoinCoreNu.ico");
    QApplication::setWindowIcon(appIcon);

    const bool forceRaise = arguments.contains(QStringLiteral("--raise"));
    const int grabIndex = arguments.indexOf("--grab-screenshot");
    const int grabSplashIndex = arguments.indexOf("--grab-splash");
    const QHash<QString, QString> buildInfo = readBuildInfoProperties(resourceRoot);
    const QString buildId = buildInfo.value(QStringLiteral("build_id"));
    const QString buildTimestamp = buildInfo.value(QStringLiteral("build_timestamp_utc"));
    const QString gitCommit = buildInfo.value(QStringLiteral("git_commit"));
    QSplashScreen* splash = nullptr;
    {
        QPixmap displaySplash(720, 405);
        displaySplash.fill(QColor("#05080a"));
        drawNuBrandSplash(displaySplash, resourceRoot);
        const QString splashText =
            QStringLiteral(
                "%1 v%2 • Core Memories • Backend derives from Litecoin Core v0.21.5.5 + Defcoin parameters\n"
                "© 2014-2026 Defcoin Core developers • © 2011-2026 Litecoin Core developers • © 2009-2026 Bitcoin Core "
                "developers")
                .arg(productName(), QStringLiteral(DEFCOIN_NU_VERSION));
        QPainter painter(&displaySplash);
        painter.setRenderHint(QPainter::TextAntialiasing, true);
        const QRect textRect(18, displaySplash.height() - 60, displaySplash.width() - 36, 50);
        painter.fillRect(QRect(0, displaySplash.height() - 74, displaySplash.width(), 74), QColor(5, 8, 10, 222));
        QFont splashFont = QApplication::font();
        splashFont.setPixelSize(11);
        painter.setFont(splashFont);
        painter.setPen(QColor("#f6f6f2"));
        painter.drawText(textRect, Qt::AlignLeft | Qt::AlignVCenter | Qt::TextWordWrap, splashText);
        painter.end();

        if (grabSplashIndex >= 0 && grabSplashIndex + 1 < arguments.size()) {
            return displaySplash.save(arguments.at(grabSplashIndex + 1)) ? 0 : 3;
        }

        splash = new QSplashScreen(displaySplash);
        if (forceRaise) {
            splash->setWindowFlag(Qt::WindowStaysOnTopHint, true);
        }
        activateSplashForUser(splash);
        startup.setSplash(splash);
        startup.step(QStringLiteral("Showing startup window."));
        app.processEvents();
        if (forceRaise) {
            QTimer::singleShot(250, splash, [splash] { activateSplashForUser(splash); });
        }
    }

    startup.step(QStringLiteral("Constructing wallet service."));
    NuRpcService service;
    startup.step(QStringLiteral("Constructing platform integration."));
    NuPlatformIntegration platform;
    platform.setService(&service);
    platform.setTrayIcon(appIcon);
    qmlRegisterSingletonInstance("Defcoin.Nu", 1, 0, "NuService", &service);
    qmlRegisterSingletonInstance("Defcoin.Nu", 1, 0, "NuPlatform", &platform);

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app, [](const QList<QQmlError>& warnings) {
        for (const QQmlError& warning : warnings) {
            writeLaunchLogLine(QStringLiteral("QML warning: %1").arg(warning.toString()));
        }
    });
    engine.rootContext()->setContextProperty(QStringLiteral("NuBuildVersion"), QStringLiteral(DEFCOIN_NU_VERSION));
    engine.rootContext()->setContextProperty(QStringLiteral("NuBuildId"), buildId);
    engine.rootContext()->setContextProperty(QStringLiteral("NuBuildTimestamp"), buildTimestamp);
    engine.rootContext()->setContextProperty(QStringLiteral("NuGitCommit"), gitCommit);
    engine.rootContext()->setContextProperty(QStringLiteral("NuHelpEnabled"), kNuHelpEnabled);
    if (QDir(deployedQmlRoot).exists())
        engine.addImportPath(deployedQmlRoot);
    engine.addImportPath(resourceRoot + "/qml");
    engine.addImportPath(resourceRoot);

    const QUrl mainUrl = QUrl::fromLocalFile(resourceRoot + QStringLiteral("/qml/Main.qml"));
#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0)
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [] { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
#else
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [mainUrl](QObject* object, const QUrl& url) {
            if (!object && url == mainUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
#endif
    startup.step(QStringLiteral("Loading Qt Quick interface."));
    engine.load(mainUrl);
    startup.step(engine.rootObjects().isEmpty() ? QStringLiteral("Qt Quick interface failed to load.") :
                                                  QStringLiteral("Qt Quick interface loaded."));

    if (smokeTest && !uiSelfTest && grabIndex < 0) {
        if (splash) {
            splash->close();
            splash->deleteLater();
        }
        return engine.rootObjects().isEmpty() ? 1 : 0;
    }

    QQuickWindow* rootWindow = nullptr;
    QObject* rootObject = nullptr;
    if (!engine.rootObjects().isEmpty()) {
        rootObject = engine.rootObjects().constFirst();
        startup.step(QStringLiteral("Activating main window."));
        platform.setRootObject(rootObject);
        platform.installMacApplicationMenu();
        const int routeIndex = arguments.indexOf("--route");
        if (routeIndex >= 0 && routeIndex + 1 < arguments.size()) {
            rootObject->setProperty("currentRoute", arguments.at(routeIndex + 1));
        }
        const int openAddressIndex = arguments.indexOf("--open-address");
        const int openTxIndex = arguments.indexOf("--open-transaction");
        const int openBlockIndex = arguments.indexOf("--open-block");
        const int searchIndex = arguments.indexOf("--search");
        if (openAddressIndex >= 0 && openAddressIndex + 1 < arguments.size()) {
            QTimer::singleShot(450, &service, [&service, value = arguments.at(openAddressIndex + 1)] {
                service.openAddressInExplorer(value);
            });
        } else if (openTxIndex >= 0 && openTxIndex + 1 < arguments.size()) {
            QTimer::singleShot(450, &service, [&service, value = arguments.at(openTxIndex + 1)] {
                service.openTransactionInExplorer(value);
            });
        } else if (openBlockIndex >= 0 && openBlockIndex + 1 < arguments.size()) {
            QTimer::singleShot(450, &service, [&service, value = arguments.at(openBlockIndex + 1)] {
                service.openBlockInExplorer(value);
            });
        } else if (searchIndex >= 0 && searchIndex + 1 < arguments.size()) {
            QTimer::singleShot(
                450, &service, [&service, value = arguments.at(searchIndex + 1)] { service.searchExplorer(value); });
        }
        const int nodeTabIndex = arguments.indexOf("--node-tab");
        if (nodeTabIndex >= 0 && nodeTabIndex + 1 < arguments.size()) {
            rootObject->setProperty("nodeInitialTab", arguments.at(nodeTabIndex + 1).toInt());
        }
        const int peerViewIndex = arguments.indexOf("--peer-view");
        if (peerViewIndex >= 0 && peerViewIndex + 1 < arguments.size()) {
            const QString peerView = arguments.at(peerViewIndex + 1).toLower();
            rootObject->setProperty("peerInitialView", peerView == QLatin1String("detailed") ? 1 : peerView.toInt());
        }
        rootObject->setProperty("visible", true);
        QMetaObject::invokeMethod(rootObject, "show");
        if (platformSupportsWindowActivation()) {
            QMetaObject::invokeMethod(rootObject, "raise");
            QMetaObject::invokeMethod(rootObject, "requestActivate");
        }
        if (forceRaise) {
            QTimer::singleShot(300, rootObject, [rootObject] {
                rootObject->setProperty("visible", true);
                QMetaObject::invokeMethod(rootObject, "show");
                if (platformSupportsWindowActivation()) {
                    QMetaObject::invokeMethod(rootObject, "raise");
                    QMetaObject::invokeMethod(rootObject, "requestActivate");
                }
            });
            QTimer::singleShot(1500, rootObject, [rootObject] {
                rootObject->setProperty("visible", true);
                QMetaObject::invokeMethod(rootObject, "show");
                if (platformSupportsWindowActivation()) {
                    QMetaObject::invokeMethod(rootObject, "raise");
                    QMetaObject::invokeMethod(rootObject, "requestActivate");
                }
            });
        }
        if (auto* window = qobject_cast<QQuickWindow*>(rootObject)) {
            rootWindow = window;
            platform.setMainWindow(rootWindow);
            rootWindow->setIcon(appIcon);
            activateWindowForUser(rootWindow);
            if (forceRaise) {
                QTimer::singleShot(300, rootWindow, [rootWindow] { activateWindowForUser(rootWindow); });
                QTimer::singleShot(900, rootWindow, [rootWindow] { activateWindowForUser(rootWindow); });
                QTimer::singleShot(1800, rootWindow, [rootWindow] { activateWindowForUser(rootWindow); });
            }
            if (arguments.contains(QStringLiteral("--open-about"))) {
                QTimer::singleShot(
                    250, rootObject, [rootObject] { QMetaObject::invokeMethod(rootObject, "openAboutSummary"); });
            }
            if (kNuHelpEnabled && arguments.contains(QStringLiteral("--open-help"))) {
                QTimer::singleShot(
                    250, rootObject, [rootObject] { QMetaObject::invokeMethod(rootObject, "openHelpManual"); });
            }
            if (kNuHelpEnabled && arguments.contains(QStringLiteral("--open-details"))) {
                QTimer::singleShot(
                    250, rootObject, [rootObject] { QMetaObject::invokeMethod(rootObject, "openDetailedAbout"); });
            }
            if (splash) {
                startup.step(QStringLiteral("Main window visible; closing startup window."));
                QTimer::singleShot(650, splash, &QSplashScreen::close);
                QTimer::singleShot(900, splash, &QObject::deleteLater);
            }
        }
        if (splash) {
            QTimer::singleShot(650, splash, &QSplashScreen::close);
            QTimer::singleShot(900, splash, &QObject::deleteLater);
        }
    }

    if (quickCloneNow) {
        QTimer::singleShot(2500, &service, [&service] { service.syncUsingQuickCloneNow(); });
    }

    if (!rootWindow) {
        for (QWindow* window : QGuiApplication::topLevelWindows()) {
            auto* quickWindow = qobject_cast<QQuickWindow*>(window);
            if (!quickWindow)
                continue;
            rootWindow = quickWindow;
            platform.setMainWindow(rootWindow);
            rootWindow->setIcon(appIcon);
            activateWindowForUser(rootWindow);
            if (splash) {
                QTimer::singleShot(650, splash, &QSplashScreen::close);
                QTimer::singleShot(900, splash, &QObject::deleteLater);
            }
            break;
        }
    }

    if (forceRaise) {
        QTimer::singleShot(1200, &app, [] { activateTopLevelWindowsForUser(); });
        QTimer::singleShot(2400, &app, [] { activateTopLevelWindowsForUser(); });
        QTimer::singleShot(4200, &app, [] { activateTopLevelWindowsForUser(); });
    }

    if (uiSelfTest) {
        if (splash) {
            splash->close();
            splash->deleteLater();
        }
        return runQtQuickUiSelfTest(app, rootObject, rootWindow, service);
    }

    if (grabIndex >= 0 && grabIndex + 1 < arguments.size()) {
        const QString outputPath = arguments.at(grabIndex + 1);
        int grabDelayMs = 1200;
        const int delayIndex = arguments.indexOf("--grab-delay-ms");
        if (delayIndex >= 0 && delayIndex + 1 < arguments.size()) {
            bool ok = false;
            const int parsed = arguments.at(delayIndex + 1).toInt(&ok);
            if (ok)
                grabDelayMs = qBound(250, parsed, 30000);
        }
        QTimer::singleShot(grabDelayMs, &app, [rootWindow, outputPath] {
            QQuickWindow* targetWindow = rootWindow;
            for (QWindow* window : QGuiApplication::topLevelWindows()) {
                auto* quickWindow = qobject_cast<QQuickWindow*>(window);
                if (quickWindow && quickWindow->isVisible() && quickWindow != rootWindow) {
                    targetWindow = quickWindow;
                }
            }
            if (targetWindow) {
                const QImage grab = targetWindow->grabWindow();
                const bool saved = !grab.isNull() && grab.save(outputPath) && QFileInfo(outputPath).size() > 0;
                QCoreApplication::exit(saved ? 0 : 3);
                return;
            }
            QCoreApplication::exit(3);
        });
    }

    return app.exec();
}
