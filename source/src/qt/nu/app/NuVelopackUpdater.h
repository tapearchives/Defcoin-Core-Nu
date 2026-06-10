#ifndef DEFCOIN_NU_VELOPACK_UPDATER_H
#define DEFCOIN_NU_VELOPACK_UPDATER_H

#include <QObject>
#include <QString>

#include <functional>
#include <memory>

class QLibrary;

struct NuVelopackUpdateDetails {
    QString version;
    QString packageName;
    QString notesMarkdown;
    quint64 size = 0;
    bool pendingRestart = false;
};

class NuVelopackUpdater final : public QObject
{
    Q_OBJECT

public:
    enum class CheckState {
        NotAvailable,
        NoUpdate,
        UpdateAvailable,
        Error,
    };

    explicit NuVelopackUpdater(QObject* parent = nullptr);
    ~NuVelopackUpdater() override;

    static void runStartupHook(const QString& app_dir);

    bool isRuntimeAvailable() const;
    bool isManagerAvailable() const;
    QString lastError() const;

    CheckState checkForUpdates(NuVelopackUpdateDetails& details);
    bool downloadPendingUpdate(const std::function<void(int)>& progress_callback);
    bool applyPendingUpdate(bool restart);

private:
    struct Asset;
    struct UpdateInfo;
    struct UpdateOptions;
    struct LocatorConfig;
    struct Api;

    bool loadRuntime(const QString& app_dir = QString());
    bool resolveApi();
    bool ensureManager();
    void clearPendingUpdate();
    QString runtimeError() const;
    QString targetVersion() const;
    QString targetPackageName() const;
    QString targetNotesMarkdown() const;
    quint64 targetSize() const;

    std::unique_ptr<QLibrary> m_library;
    std::unique_ptr<Api> m_api;
    void* m_manager = nullptr;
    UpdateInfo* m_update_info = nullptr;
    Asset* m_pending_restart_asset = nullptr;
    bool m_downloaded = false;
    QString m_last_error;
};

#endif // DEFCOIN_NU_VELOPACK_UPDATER_H
