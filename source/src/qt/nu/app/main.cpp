#include "NuRpcService.h"
#include "NuPlatformIntegration.h"
#include "NuVelopackUpdater.h"
#if defined(__APPLE__)
#include "MacHelp.h"
#endif

#include <QApplication>
#include <QColor>
#include <QFile>
#include <QFont>
#include <QHash>
#include <QIcon>
#include <QImage>
#include <QIODevice>
#include <QLinearGradient>
#include <QLockFile>
#include <QMessageBox>
#include <QPainter>
#include <QPixmap>
#include <QGuiApplication>
#include <QMetaObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml/qqml.h>
#include <QProcess>
#include <QQuickStyle>
#include <QDir>
#include <QDebug>
#include <QQuickWindow>
#include <QScreen>
#include <QSplashScreen>
#include <QStyleHints>
#include <QTimer>
#include <QUrl>
#include <QWidget>
#include <QWindow>

#include <memory>

#if defined(Q_OS_WIN)
#include <windows.h>
#endif

namespace {
constexpr bool kNuHelpEnabled = DEFCOIN_NU_HELP_ENABLED != 0;
#ifndef DEFCOIN_NU_EXPFOR_APP
#define DEFCOIN_NU_EXPFOR_APP 0
#endif
constexpr bool kExpForApp = DEFCOIN_NU_EXPFOR_APP != 0;

QString productName()
{
    return kExpForApp ? QStringLiteral("Defcoin Core ExpFor") : QStringLiteral("Defcoin Core Nu");
}

QString productExecutableName()
{
    return kExpForApp ? QStringLiteral("DefcoinCoreExpFor") : QStringLiteral("DefcoinCoreNu");
}

QString productBundleIdentifier()
{
    return kExpForApp ? QStringLiteral("org.defcoincore.DefcoinCoreExpFor") : QStringLiteral("org.defcoincore.DefcoinCoreNu");
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

    const QPixmap coinStack(resourceRoot + "/assets/brand/defcoin-nu-coin-stack-hires.png");
    const QRect logoCoinRect(112, 48, 216, 305);
    if (!coinStack.isNull()) {
        painter.setOpacity(0.96);
        painter.drawPixmap(logoCoinRect, coinStack);
        painter.setOpacity(1.0);
    }

    QFont brandFont(QStringLiteral("Avenir Next Condensed"));
    brandFont.setPixelSize(58);
    brandFont.setWeight(QFont::ExtraBold);
    brandFont.setLetterSpacing(QFont::AbsoluteSpacing, 1.15);
    painter.setFont(brandFont);
    painter.setPen(QColor("#f6f6f2"));

    const int wordX = logoCoinRect.right() + 30;
    const int wordY = logoCoinRect.top() + 78;
    const int wordW = panel.right() - wordX - 44;
    QFontMetrics brandMetrics(brandFont);
    painter.drawText(QRect(wordX, wordY, wordW, 66), Qt::AlignLeft | Qt::AlignVCenter, QStringLiteral("DEF"));
    painter.drawText(QRect(wordX + brandMetrics.horizontalAdvance(QStringLiteral("DEF")) + 2, wordY, wordW, 66), Qt::AlignLeft | Qt::AlignVCenter, QStringLiteral("COIN"));
    painter.drawText(QRect(wordX, wordY + 50, wordW, 66), Qt::AlignLeft | Qt::AlignVCenter, QStringLiteral("CORE NU"));
}

#if defined(Q_OS_WIN)
void holdTopmostBriefly(QWidget* context, HWND hwnd)
{
    if (!context || !hwnd) return;
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
    QTimer::singleShot(2200, context, [context] {
        HWND current_hwnd = reinterpret_cast<HWND>(context->winId());
        if (!current_hwnd) return;
        SetWindowPos(current_hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        BringWindowToTop(current_hwnd);
        SetForegroundWindow(current_hwnd);
    });
}

void holdTopmostBriefly(QWindow* context, HWND hwnd)
{
    if (!context || !hwnd) return;
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
    QTimer::singleShot(2200, context, [context] {
        HWND current_hwnd = reinterpret_cast<HWND>(context->winId());
        if (!current_hwnd) return;
        SetWindowPos(current_hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        BringWindowToTop(current_hwnd);
        SetForegroundWindow(current_hwnd);
        context->raise();
        context->requestActivate();
    });
}
#endif

void activateWindowForUser(QQuickWindow* window)
{
    if (!window) return;
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
    window->raise();
    window->requestActivate();
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
    for (QWindow* window : QGuiApplication::topLevelWindows()) {
        if (!window || !window->isVisible()) continue;
        if (auto* quickWindow = qobject_cast<QQuickWindow*>(window)) {
            activateWindowForUser(quickWindow);
            continue;
        }
        window->setVisibility(QWindow::Windowed);
        window->showNormal();
        window->raise();
        window->requestActivate();
    }
}

void activateSplashForUser(QSplashScreen* splash)
{
    if (!splash) return;
    splash->show();
    splash->raise();
    splash->activateWindow();
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

bool anotherGuiProcessIsRunning()
{
#if defined(Q_OS_UNIX)
    const qint64 current_pid = QCoreApplication::applicationPid();
    QProcess pgrep;
    pgrep.start(QStringLiteral("/usr/bin/pgrep"), {QStringLiteral("-x"), productExecutableName()});
    if (!pgrep.waitForFinished(1000)) {
        pgrep.kill();
        pgrep.waitForFinished(250);
        return false;
    }
    const QList<QByteArray> lines = pgrep.readAllStandardOutput().split('\n');
    for (const QByteArray& line : lines) {
        bool ok = false;
        const qint64 pid = QString::fromLocal8Bit(line).trimmed().toLongLong(&ok);
        if (ok && pid > 0 && pid != current_pid) return true;
    }
#if defined(Q_OS_MACOS)
    QProcess ps;
    ps.start(QStringLiteral("/bin/ps"), {QStringLiteral("-axo"), QStringLiteral("pid=,comm=")});
    if (!ps.waitForFinished(1000)) {
        ps.kill();
        ps.waitForFinished(250);
        return false;
    }
    const QList<QByteArray> ps_lines = ps.readAllStandardOutput().split('\n');
    for (const QByteArray& line : ps_lines) {
        const QString text = QString::fromLocal8Bit(line).trimmed();
        if (!text.contains(productExecutableName())) continue;
        const int space = text.indexOf(QLatin1Char(' '));
        bool ok = false;
        const qint64 pid = text.left(space > 0 ? space : text.size()).trimmed().toLongLong(&ok);
        if (ok && pid > 0 && pid != current_pid) return true;
    }
#endif
#endif
    return false;
}
}

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

    QQuickStyle::setStyle("Basic");

#ifdef Q_OS_MACOS
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString pluginDir = QDir(appDir).filePath("../PlugIns");
    if (QDir(pluginDir).exists()) QCoreApplication::setLibraryPaths({pluginDir});
    const QString resourceRoot = QDir(appDir).filePath("../Resources/nu");
    const QString deployedQmlRoot = QDir(appDir).filePath("../Resources/qml");
#else
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString pluginDir = QDir(appDir).filePath("plugins");
    if (QDir(pluginDir).exists()) QCoreApplication::setLibraryPaths({pluginDir});
    const QString resourceRoot = QDir(appDir).filePath("nu");
    const QString deployedQmlRoot = QDir(appDir).filePath("qml");
#endif
    const QStringList arguments = app.arguments();
    const bool buildSmokeTest = !qEnvironmentVariableIsEmpty("DEFCOIN_NU_SMOKE_TEST");
    const bool smokeTest = arguments.contains(QStringLiteral("--smoke-test")) ||
        buildSmokeTest;
    if (buildSmokeTest) {
        return 0;
    }
    const bool allowMultiple = arguments.contains(QStringLiteral("--allow-multiple"));

    std::unique_ptr<QLockFile> singleInstanceLock;
    if (!smokeTest && !allowMultiple) {
        const QString dataDir = nuDefaultDataDir();
        QDir().mkpath(dataDir);
        if (anotherGuiProcessIsRunning()) {
            QMessageBox::warning(nullptr,
                                 QStringLiteral("%1 is already open").arg(productName()),
                                 QStringLiteral("Another %1 window appears to be running. Close the other window before opening this build. This prevents two frontends from writing the same local cache or competing for actions.").arg(productName()));
            return 2;
        }
        singleInstanceLock = std::make_unique<QLockFile>(QDir(dataDir).filePath(kExpForApp ? QStringLiteral("defcoin-core-expfor-gui.lock") : QStringLiteral("defcoin-core-nu-gui.lock")));
        singleInstanceLock->setStaleLockTime(30000);
        if (!singleInstanceLock->tryLock(100)) {
            QMessageBox::warning(nullptr,
                                 QStringLiteral("%1 is already open").arg(productName()),
                                 QStringLiteral("Another %1 window is already using this data directory:\n\n%2\n\nClose the other window before opening this build.").arg(productName(), dataDir));
            return 2;
        }
    }

    bool velopackHookLaunch = !qEnvironmentVariableIsEmpty("VELOPACK_FIRSTRUN") ||
        !qEnvironmentVariableIsEmpty("VELOPACK_RESTART");
    for (const QString& argument : arguments) {
        if (argument.startsWith(QStringLiteral("--veloapp-"))) {
            velopackHookLaunch = true;
            break;
        }
    }
    if (!smokeTest && velopackHookLaunch) {
        NuVelopackUpdater::runStartupHook(appDir);
    }

    QIcon appIcon;
    appIcon.addFile(resourceRoot + "/assets/brand/defcoin-nu-icon-1024.png", QSize(256, 256));
    appIcon.addFile(resourceRoot + "/assets/brand/defcoin-nu-icon-1024.png", QSize(1024, 1024));
    appIcon.addFile(resourceRoot + "/assets/brand/DefcoinCoreNu.ico");
    QApplication::setWindowIcon(appIcon);

    const bool forceRaise = arguments.contains(QStringLiteral("--raise"));
    const int grabIndex = arguments.indexOf("--grab-screenshot");
    const QHash<QString, QString> buildInfo = readBuildInfoProperties(resourceRoot);
    const QString buildId = buildInfo.value(QStringLiteral("build_id"));
    const QString buildTimestamp = buildInfo.value(QStringLiteral("build_timestamp_utc"));
    const QString gitCommit = buildInfo.value(QStringLiteral("git_commit"));
    QSplashScreen* splash = nullptr;
    {
        QPixmap displaySplash(720, 405);
        displaySplash.fill(QColor("#05080a"));
        drawNuBrandSplash(displaySplash, resourceRoot);
        const QString splashText = QStringLiteral(
            "%1 v%2 • Core Memories • Backend: Litecoin Core v0.21.5.5 + Defcoin parameters\n"
            "© 2014-2026 Defcoin Core developers • © 2011-2026 Litecoin Core developers • © 2009-2026 Bitcoin Core developers")
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

        splash = new QSplashScreen(displaySplash);
        if (forceRaise) {
            splash->setWindowFlag(Qt::WindowStaysOnTopHint, true);
        }
        activateSplashForUser(splash);
        app.processEvents();
        if (forceRaise) {
            QTimer::singleShot(250, splash, [splash] { activateSplashForUser(splash); });
        }
    }

    NuRpcService service;
    NuPlatformIntegration platform;
    platform.setService(&service);
    platform.setTrayIcon(appIcon);
    qmlRegisterSingletonInstance("Defcoin.Nu", 1, 0, "NuService", &service);
    qmlRegisterSingletonInstance("Defcoin.Nu", 1, 0, "NuPlatform", &platform);

    bool duplicateGuiWarningShown = false;
    if (!smokeTest && !allowMultiple) {
        auto* duplicateGuiTimer = new QTimer(&app);
        duplicateGuiTimer->setInterval(10000);
        QObject::connect(duplicateGuiTimer, &QTimer::timeout, &app, [&duplicateGuiWarningShown] {
            if (duplicateGuiWarningShown || !anotherGuiProcessIsRunning()) return;
            duplicateGuiWarningShown = true;
            QMessageBox::warning(nullptr,
                                 QStringLiteral("Another %1 window is open").arg(productName()),
                                 QStringLiteral("Another %1 window is now running. Close one window before doing local cache or wallet work.").arg(productName()));
        });
        duplicateGuiTimer->start();
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("NuBuildVersion"), QStringLiteral(DEFCOIN_NU_VERSION));
    engine.rootContext()->setContextProperty(QStringLiteral("NuBuildId"), buildId);
    engine.rootContext()->setContextProperty(QStringLiteral("NuBuildTimestamp"), buildTimestamp);
    engine.rootContext()->setContextProperty(QStringLiteral("NuGitCommit"), gitCommit);
    engine.rootContext()->setContextProperty(QStringLiteral("NuHelpEnabled"), kNuHelpEnabled);
    if (QDir(deployedQmlRoot).exists()) engine.addImportPath(deployedQmlRoot);
    engine.addImportPath(resourceRoot + "/qml");
    engine.addImportPath(resourceRoot);

    const QUrl mainUrl = QUrl::fromLocalFile(resourceRoot + (kExpForApp ? QStringLiteral("/qml/ExpForMain.qml") : QStringLiteral("/qml/Main.qml")));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] {
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(mainUrl);

    if (smokeTest && grabIndex < 0) {
        if (splash) {
            splash->close();
            splash->deleteLater();
        }
        return engine.rootObjects().isEmpty() ? 1 : 0;
    }

    QQuickWindow* rootWindow = nullptr;
    if (!engine.rootObjects().isEmpty()) {
        QObject* rootObject = engine.rootObjects().constFirst();
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
            rootObject->setProperty("currentRoute", QStringLiteral("explorer"));
            QTimer::singleShot(450, &service, [&service, value = arguments.at(openAddressIndex + 1)] { service.openAddressInExplorer(value); });
        } else if (openTxIndex >= 0 && openTxIndex + 1 < arguments.size()) {
            rootObject->setProperty("currentRoute", QStringLiteral("explorer"));
            QTimer::singleShot(450, &service, [&service, value = arguments.at(openTxIndex + 1)] { service.openTransactionInExplorer(value); });
        } else if (openBlockIndex >= 0 && openBlockIndex + 1 < arguments.size()) {
            rootObject->setProperty("currentRoute", QStringLiteral("explorer"));
            QTimer::singleShot(450, &service, [&service, value = arguments.at(openBlockIndex + 1)] { service.openBlockInExplorer(value); });
        } else if (searchIndex >= 0 && searchIndex + 1 < arguments.size()) {
            rootObject->setProperty("currentRoute", QStringLiteral("explorer"));
            QTimer::singleShot(450, &service, [&service, value = arguments.at(searchIndex + 1)] { service.searchExplorer(value); });
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
        QMetaObject::invokeMethod(rootObject, "raise");
        QMetaObject::invokeMethod(rootObject, "requestActivate");
        if (forceRaise) {
            QTimer::singleShot(300, rootObject, [rootObject] {
                rootObject->setProperty("visible", true);
                QMetaObject::invokeMethod(rootObject, "show");
                QMetaObject::invokeMethod(rootObject, "raise");
                QMetaObject::invokeMethod(rootObject, "requestActivate");
            });
            QTimer::singleShot(1500, rootObject, [rootObject] {
                rootObject->setProperty("visible", true);
                QMetaObject::invokeMethod(rootObject, "show");
                QMetaObject::invokeMethod(rootObject, "raise");
                QMetaObject::invokeMethod(rootObject, "requestActivate");
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
                QTimer::singleShot(250, rootObject, [rootObject] {
                    QMetaObject::invokeMethod(rootObject, "openAboutSummary");
                });
            }
            if (kNuHelpEnabled && arguments.contains(QStringLiteral("--open-help"))) {
                QTimer::singleShot(250, rootObject, [rootObject] {
                    QMetaObject::invokeMethod(rootObject, "openHelpManual");
                });
            }
            if (kNuHelpEnabled && arguments.contains(QStringLiteral("--open-details"))) {
                QTimer::singleShot(250, rootObject, [rootObject] {
                    QMetaObject::invokeMethod(rootObject, "openDetailedAbout");
                });
            }
            if (splash) {
                QTimer::singleShot(650, splash, &QSplashScreen::close);
                QTimer::singleShot(900, splash, &QObject::deleteLater);
            }
        }
        if (splash) {
            QTimer::singleShot(650, splash, &QSplashScreen::close);
            QTimer::singleShot(900, splash, &QObject::deleteLater);
        }
    }

    if (!rootWindow) {
        for (QWindow* window : QGuiApplication::topLevelWindows()) {
            auto* quickWindow = qobject_cast<QQuickWindow*>(window);
            if (!quickWindow) continue;
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

    if (grabIndex >= 0 && grabIndex + 1 < arguments.size()) {
        const QString outputPath = arguments.at(grabIndex + 1);
        int grabDelayMs = 1200;
        const int delayIndex = arguments.indexOf("--grab-delay-ms");
        if (delayIndex >= 0 && delayIndex + 1 < arguments.size()) {
            bool ok = false;
            const int parsed = arguments.at(delayIndex + 1).toInt(&ok);
            if (ok) grabDelayMs = qBound(250, parsed, 30000);
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
                targetWindow->grabWindow().save(outputPath);
            }
            QCoreApplication::quit();
        });
    }

    return app.exec();
}
