#ifndef DEFCOIN_NU_PLATFORM_INTEGRATION_H
#define DEFCOIN_NU_PLATFORM_INTEGRATION_H

#include <QObject>
#include <QPointer>
#include <QSystemTrayIcon>

class QAction;
class QIcon;
class QMenu;
class QMenuBar;
class NuRpcService;
class QWindow;

class NuPlatformIntegration final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool trayAvailable READ trayAvailable CONSTANT)

public:
    explicit NuPlatformIntegration(QObject* parent = nullptr);
    ~NuPlatformIntegration() override;

    bool trayAvailable() const;

    void setRootObject(QObject* root_object);
    void setMainWindow(QWindow* window);
    void setService(NuRpcService* service);
    void setTrayIcon(const QIcon& icon);
    void installMacApplicationMenu();

    Q_INVOKABLE void showAboutQt();
    Q_INVOKABLE void showMainWindow();
    Q_INVOKABLE void quitApplication();
    Q_INVOKABLE void showBackgroundNotice();
    Q_INVOKABLE void hideTrayIcon();

public Q_SLOTS:
    void refreshNodeStatus();
    void handleSettingsChanged();

private:
    void ensureTrayIcon();
    void shutdownTrayIcon();
    void invokeRootMethod(const char* method);
    QString currentNodeStatusText() const;

    QPointer<QObject> m_root_object;
    QPointer<QWindow> m_main_window;
    QPointer<NuRpcService> m_service;
    QIcon m_tray_icon;
    QSystemTrayIcon* m_tray = nullptr;
    QMenu* m_tray_menu = nullptr;
    QAction* m_status_action = nullptr;
    QMenuBar* m_mac_menu_bar = nullptr;
    bool m_background_notice_shown = false;
};

#endif // DEFCOIN_NU_PLATFORM_INTEGRATION_H
