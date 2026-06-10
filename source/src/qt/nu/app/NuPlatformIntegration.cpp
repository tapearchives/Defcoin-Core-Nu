#include "NuPlatformIntegration.h"

#include "NuRpcService.h"

#include <QAction>
#include <QApplication>
#include <QIcon>
#include <QKeySequence>
#include <QMenu>
#include <QMenuBar>
#include <QMessageBox>
#include <QMetaObject>
#include <QWindow>

NuPlatformIntegration::NuPlatformIntegration(QObject* parent) : QObject(parent)
{
    connect(
        QCoreApplication::instance(), &QCoreApplication::aboutToQuit, this, &NuPlatformIntegration::shutdownTrayIcon);
}

NuPlatformIntegration::~NuPlatformIntegration()
{
    shutdownTrayIcon();
}

bool NuPlatformIntegration::trayAvailable() const
{
    return QSystemTrayIcon::isSystemTrayAvailable();
}

void NuPlatformIntegration::setRootObject(QObject* root_object)
{
    m_root_object = root_object;
}

void NuPlatformIntegration::setMainWindow(QWindow* window)
{
    m_main_window = window;
}

void NuPlatformIntegration::setService(NuRpcService* service)
{
    if (m_service == service)
        return;
    if (m_service) {
        disconnect(m_service, nullptr, this, nullptr);
    }
    m_service = service;
    if (m_service) {
        connect(m_service, &NuRpcService::stateChanged, this, &NuPlatformIntegration::refreshNodeStatus);
        connect(m_service, &NuRpcService::peersChanged, this, &NuPlatformIntegration::refreshNodeStatus);
        connect(m_service, &NuRpcService::settingsChanged, this, &NuPlatformIntegration::handleSettingsChanged);
    }
    refreshNodeStatus();
}

void NuPlatformIntegration::setTrayIcon(const QIcon& icon)
{
    m_tray_icon = icon;
    if (m_tray) {
        m_tray->setIcon(m_tray_icon);
    }
}

void NuPlatformIntegration::installMacApplicationMenu()
{
#if defined(Q_OS_MACOS)
    if (m_mac_menu_bar)
        return;

    m_mac_menu_bar = new QMenuBar(nullptr);
    m_mac_menu_bar->setNativeMenuBar(true);
    QMenu* app_menu = m_mac_menu_bar->addMenu(QApplication::applicationDisplayName());

    QAction* about_action = app_menu->addAction(QObject::tr("About %1").arg(QApplication::applicationDisplayName()));
    about_action->setMenuRole(QAction::AboutRole);
    connect(about_action, &QAction::triggered, this, [this] { invokeRootMethod("openAboutSummary"); });

    QAction* about_qt_action = app_menu->addAction(QObject::tr("About Qt"));
    about_qt_action->setMenuRole(QAction::AboutQtRole);
    connect(about_qt_action, &QAction::triggered, this, &NuPlatformIntegration::showAboutQt);

    QAction* update_action = app_menu->addAction(QObject::tr("Check for Updates..."));
    update_action->setMenuRole(QAction::ApplicationSpecificRole);
    connect(update_action, &QAction::triggered, this, [this] {
        if (m_service)
            m_service->checkForUpdates(true);
    });

    app_menu->addSeparator();

    QAction* prefs_action = app_menu->addAction(QObject::tr("Preferences..."));
    prefs_action->setShortcut(QKeySequence::Preferences);
    prefs_action->setMenuRole(QAction::PreferencesRole);
    connect(prefs_action, &QAction::triggered, this, [this] { invokeRootMethod("openPreferences"); });

    app_menu->addSeparator();

    QAction* quit_action = app_menu->addAction(QObject::tr("Quit %1").arg(QApplication::applicationDisplayName()));
    quit_action->setShortcut(QKeySequence::Quit);
    quit_action->setMenuRole(QAction::QuitRole);
    connect(quit_action, &QAction::triggered, this, &NuPlatformIntegration::quitApplication);
#else
    Q_UNUSED(this);
#endif
}

void NuPlatformIntegration::showAboutQt()
{
    QMessageBox::aboutQt(nullptr, QObject::tr("About Qt"));
}

void NuPlatformIntegration::showMainWindow()
{
    if (!m_main_window)
        return;
    m_main_window->showNormal();
    m_main_window->raise();
    m_main_window->requestActivate();
}

void NuPlatformIntegration::quitApplication()
{
    if (m_root_object) {
        m_root_object->setProperty("quitRequested", true);
    }
    shutdownTrayIcon();
    QCoreApplication::quit();
}

void NuPlatformIntegration::showBackgroundNotice()
{
    ensureTrayIcon();
    if (!m_tray || m_background_notice_shown)
        return;
    m_background_notice_shown = true;
    m_tray->showMessage(QApplication::applicationDisplayName(),
                        QObject::tr("%1 is running in the background.").arg(QApplication::applicationDisplayName()),
                        QSystemTrayIcon::Information,
                        7000);
}

void NuPlatformIntegration::hideTrayIcon()
{
    shutdownTrayIcon();
}

void NuPlatformIntegration::refreshNodeStatus()
{
    if (!m_status_action)
        return;
    m_status_action->setText(QObject::tr("Node Status: %1").arg(currentNodeStatusText()));
}

void NuPlatformIntegration::handleSettingsChanged()
{
    if (m_service && !m_service->backgroundCloseEnabled()) {
        shutdownTrayIcon();
    }
    refreshNodeStatus();
}

void NuPlatformIntegration::ensureTrayIcon()
{
    if (m_tray || !trayAvailable())
        return;

    m_tray_menu = new QMenu();
    QAction* show_action = m_tray_menu->addAction(QObject::tr("Show %1").arg(QApplication::applicationDisplayName()));
    connect(show_action, &QAction::triggered, this, &NuPlatformIntegration::showMainWindow);

    m_status_action = m_tray_menu->addAction(QObject::tr("Node Status: %1").arg(currentNodeStatusText()));
    m_status_action->setEnabled(false);
    m_tray_menu->addSeparator();

    QAction* quit_action = m_tray_menu->addAction(QObject::tr("Quit"));
    connect(quit_action, &QAction::triggered, this, &NuPlatformIntegration::quitApplication);

    m_tray = new QSystemTrayIcon(this);
    if (!m_tray_icon.isNull()) {
        m_tray->setIcon(m_tray_icon);
    } else {
        m_tray->setIcon(QApplication::windowIcon());
    }
    m_tray->setToolTip(QApplication::applicationDisplayName());
    m_tray->setContextMenu(m_tray_menu);
    connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
            showMainWindow();
        }
    });
    m_tray->show();
}

void NuPlatformIntegration::shutdownTrayIcon()
{
    m_status_action = nullptr;
    if (m_tray) {
        m_tray->hide();
        m_tray->setContextMenu(nullptr);
        m_tray->deleteLater();
        m_tray = nullptr;
    }
    if (m_tray_menu) {
        m_tray_menu->deleteLater();
        m_tray_menu = nullptr;
    }
    m_background_notice_shown = false;
}

void NuPlatformIntegration::invokeRootMethod(const char* method)
{
    if (!m_root_object)
        return;
    QMetaObject::invokeMethod(m_root_object, method, Qt::QueuedConnection);
}

QString NuPlatformIntegration::currentNodeStatusText() const
{
    if (!m_service)
        return QObject::tr("Starting");
    if (!m_service->rpcConnected())
        return QObject::tr("RPC not connected");
    return QObject::tr("%1, %2 peers").arg(m_service->networkState(), QString::number(m_service->peerCount()));
}
