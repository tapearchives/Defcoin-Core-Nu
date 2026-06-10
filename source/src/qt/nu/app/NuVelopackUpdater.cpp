#include "NuVelopackUpdater.h"

#include <QCoreApplication>
#include <QDir>
#include <QLibrary>
#include <QSysInfo>

#include <cstdint>

namespace {
constexpr qint8 kUpdateError = -1;
constexpr qint8 kUpdateAvailable = 0;
constexpr qint8 kNoUpdateAvailable = 1;
constexpr qint8 kRemoteIsEmpty = 2;

QStringList velopackRuntimeCandidates(const QString& app_dir)
{
    const QString resolved_app_dir = app_dir.isEmpty() ? QCoreApplication::applicationDirPath() : app_dir;
    QStringList candidates;
#if defined(Q_OS_MACOS)
    candidates << QDir(resolved_app_dir).filePath(QStringLiteral("../Frameworks/velopack_libc_osx.dylib"));
    candidates << QDir(resolved_app_dir).filePath(QStringLiteral("../Resources/nu/velopack_libc_osx.dylib"));
    candidates << QDir(resolved_app_dir).filePath(QStringLiteral("velopack_libc_osx.dylib"));
    candidates << QStringLiteral("velopack_libc_osx");
#elif defined(Q_OS_WIN)
    const QString arch = QSysInfo::currentCpuArchitecture().toLower();
    const QString dll = arch.contains(QStringLiteral("arm")) || arch.contains(QStringLiteral("aarch64")) ?
                            QStringLiteral("velopack_libc_win_arm64_msvc.dll") :
                            QStringLiteral("velopack_libc_win_x64_msvc.dll");
    candidates << QDir(resolved_app_dir).filePath(dll);
    candidates << dll;
#elif defined(Q_OS_LINUX)
    const QString arch = QSysInfo::currentCpuArchitecture().toLower();
    const QString so = arch.contains(QStringLiteral("arm")) || arch.contains(QStringLiteral("aarch64")) ?
                           QStringLiteral("velopack_libc_linux_arm64_gnu.so") :
                           QStringLiteral("velopack_libc_linux_x64_gnu.so");
    candidates << QDir(resolved_app_dir).filePath(so);
    candidates << so;
#endif
    candidates.removeDuplicates();
    return candidates;
}

template <typename Fn>
bool resolveSymbol(QLibrary& library, Fn& target, const char* name)
{
    target = reinterpret_cast<Fn>(library.resolve(name));
    return target != nullptr;
}

QString charPtrToQString(const char* value)
{
    return value ? QString::fromUtf8(value) : QString();
}
} // namespace

struct NuVelopackUpdater::Asset {
    char* PackageId;
    char* Version;
    char* Type;
    char* FileName;
    char* SHA1;
    char* SHA256;
    quint64 Size;
    char* NotesMarkdown;
    char* NotesHtml;
};

struct NuVelopackUpdater::UpdateInfo {
    Asset* TargetFullRelease;
    Asset* BaseRelease;
    Asset** DeltasToTarget;
    size_t DeltasToTargetCount;
    bool IsDowngrade;
};

struct NuVelopackUpdater::UpdateOptions {
    bool AllowVersionDowngrade;
    char* ExplicitChannel;
    qint32 MaximumDeltasBeforeFallback;
};

struct NuVelopackUpdater::LocatorConfig {
    char* RootAppDir;
    char* UpdateExePath;
    char* PackagesDir;
    char* ManifestPath;
    char* CurrentBinaryDir;
    bool IsPortable;
};

struct NuVelopackUpdater::Api {
    using new_update_manager_fn = bool (*)(const char*, UpdateOptions*, LocatorConfig*, void**);
    using get_current_version_fn = size_t (*)(void*, char*, size_t);
    using update_pending_restart_fn = bool (*)(void*, Asset**);
    using check_for_updates_fn = qint8 (*)(void*, UpdateInfo**);
    using download_updates_fn = bool (*)(void*, UpdateInfo*, void (*)(void*, size_t), void*);
    using wait_exit_then_apply_updates_fn = bool (*)(void*, Asset*, bool, bool, char**, size_t);
    using free_update_manager_fn = void (*)(void*);
    using free_update_info_fn = void (*)(UpdateInfo*);
    using free_asset_fn = void (*)(Asset*);
    using get_last_error_fn = size_t (*)(char*, size_t);
    using app_set_auto_apply_on_startup_fn = void (*)(bool);
    using app_run_fn = void (*)(void*);

    new_update_manager_fn newUpdateManager = nullptr;
    get_current_version_fn getCurrentVersion = nullptr;
    update_pending_restart_fn updatePendingRestart = nullptr;
    check_for_updates_fn checkForUpdates = nullptr;
    download_updates_fn downloadUpdates = nullptr;
    wait_exit_then_apply_updates_fn waitExitThenApplyUpdates = nullptr;
    free_update_manager_fn freeUpdateManager = nullptr;
    free_update_info_fn freeUpdateInfo = nullptr;
    free_asset_fn freeAsset = nullptr;
    get_last_error_fn getLastError = nullptr;
    app_set_auto_apply_on_startup_fn appSetAutoApplyOnStartup = nullptr;
    app_run_fn appRun = nullptr;
};

NuVelopackUpdater::NuVelopackUpdater(QObject* parent) : QObject(parent)
{
    loadRuntime();
}

NuVelopackUpdater::~NuVelopackUpdater()
{
    clearPendingUpdate();
    if (m_manager && m_api && m_api->freeUpdateManager) {
        m_api->freeUpdateManager(m_manager);
    }
    m_manager = nullptr;
}

void NuVelopackUpdater::runStartupHook(const QString& app_dir)
{
    QLibrary library;
    for (const QString& candidate : velopackRuntimeCandidates(app_dir)) {
        library.setFileName(candidate);
        if (library.load())
            break;
    }
    if (!library.isLoaded())
        return;

    auto set_auto_apply =
        reinterpret_cast<Api::app_set_auto_apply_on_startup_fn>(library.resolve("vpkc_app_set_auto_apply_on_startup"));
    auto run = reinterpret_cast<Api::app_run_fn>(library.resolve("vpkc_app_run"));
    if (!run)
        return;
    if (set_auto_apply)
        set_auto_apply(true);
    run(nullptr);
}

bool NuVelopackUpdater::isRuntimeAvailable() const
{
    return m_library && m_library->isLoaded() && m_api != nullptr;
}

bool NuVelopackUpdater::isManagerAvailable() const
{
    return m_manager != nullptr;
}

QString NuVelopackUpdater::lastError() const
{
    return m_last_error;
}

bool NuVelopackUpdater::loadRuntime(const QString& app_dir)
{
    if (isRuntimeAvailable())
        return true;

    for (const QString& candidate : velopackRuntimeCandidates(app_dir)) {
        auto library = std::make_unique<QLibrary>(candidate);
        if (!library->load())
            continue;
        m_library = std::move(library);
        if (resolveApi())
            return true;
        m_library.reset();
        m_api.reset();
    }

    m_last_error = QStringLiteral("Velopack runtime library was not found in this app package.");
    return false;
}

bool NuVelopackUpdater::resolveApi()
{
    if (!m_library || !m_library->isLoaded())
        return false;
    auto api = std::make_unique<Api>();
    bool ok = true;
    ok = resolveSymbol(*m_library, api->newUpdateManager, "vpkc_new_update_manager") && ok;
    ok = resolveSymbol(*m_library, api->getCurrentVersion, "vpkc_get_current_version") && ok;
    ok = resolveSymbol(*m_library, api->updatePendingRestart, "vpkc_update_pending_restart") && ok;
    ok = resolveSymbol(*m_library, api->checkForUpdates, "vpkc_check_for_updates") && ok;
    ok = resolveSymbol(*m_library, api->downloadUpdates, "vpkc_download_updates") && ok;
    ok = resolveSymbol(*m_library, api->waitExitThenApplyUpdates, "vpkc_wait_exit_then_apply_updates") && ok;
    ok = resolveSymbol(*m_library, api->freeUpdateManager, "vpkc_free_update_manager") && ok;
    ok = resolveSymbol(*m_library, api->freeUpdateInfo, "vpkc_free_update_info") && ok;
    ok = resolveSymbol(*m_library, api->freeAsset, "vpkc_free_asset") && ok;
    ok = resolveSymbol(*m_library, api->getLastError, "vpkc_get_last_error") && ok;
    if (!ok) {
        m_last_error = QStringLiteral("Velopack runtime library is present but missing required updater symbols.");
        return false;
    }
    resolveSymbol(*m_library, api->appSetAutoApplyOnStartup, "vpkc_app_set_auto_apply_on_startup");
    resolveSymbol(*m_library, api->appRun, "vpkc_app_run");
    m_api = std::move(api);
    return true;
}

bool NuVelopackUpdater::ensureManager()
{
    if (m_manager)
        return true;
    if (!loadRuntime())
        return false;

    UpdateOptions options{};
    options.AllowVersionDowngrade = false;
    options.ExplicitChannel = nullptr;
    options.MaximumDeltasBeforeFallback = 10;

    void* manager = nullptr;
    if (!m_api->newUpdateManager(DEFCOIN_NU_VELOPACK_UPDATE_URL, &options, nullptr, &manager) || !manager) {
        m_last_error = runtimeError();
        if (m_last_error.isEmpty()) {
            m_last_error = QStringLiteral("This copy of Defcoin Core Nu was not installed by Velopack.");
        }
        return false;
    }

    m_manager = manager;
    return true;
}

void NuVelopackUpdater::clearPendingUpdate()
{
    if (m_update_info && m_api && m_api->freeUpdateInfo) {
        m_api->freeUpdateInfo(m_update_info);
    }
    if (m_pending_restart_asset && m_api && m_api->freeAsset) {
        m_api->freeAsset(m_pending_restart_asset);
    }
    m_update_info = nullptr;
    m_pending_restart_asset = nullptr;
    m_downloaded = false;
}

QString NuVelopackUpdater::runtimeError() const
{
    if (!m_api || !m_api->getLastError)
        return QString();
    QByteArray buffer(2048, Qt::Uninitialized);
    const size_t needed = m_api->getLastError(buffer.data(), size_t(buffer.size()));
    if (needed == 0)
        return QString();
    if (needed > size_t(buffer.size())) {
        buffer.resize(int(needed + 1));
        m_api->getLastError(buffer.data(), size_t(buffer.size()));
    }
    return QString::fromUtf8(buffer.constData()).trimmed();
}

QString NuVelopackUpdater::targetVersion() const
{
    if (m_pending_restart_asset)
        return charPtrToQString(m_pending_restart_asset->Version);
    if (m_update_info && m_update_info->TargetFullRelease)
        return charPtrToQString(m_update_info->TargetFullRelease->Version);
    return QString();
}

QString NuVelopackUpdater::targetPackageName() const
{
    if (m_pending_restart_asset)
        return charPtrToQString(m_pending_restart_asset->FileName);
    if (m_update_info && m_update_info->TargetFullRelease)
        return charPtrToQString(m_update_info->TargetFullRelease->FileName);
    return QStringLiteral("Velopack package");
}

QString NuVelopackUpdater::targetNotesMarkdown() const
{
    if (m_pending_restart_asset)
        return charPtrToQString(m_pending_restart_asset->NotesMarkdown);
    if (m_update_info && m_update_info->TargetFullRelease)
        return charPtrToQString(m_update_info->TargetFullRelease->NotesMarkdown);
    return QString();
}

quint64 NuVelopackUpdater::targetSize() const
{
    if (m_pending_restart_asset)
        return m_pending_restart_asset->Size;
    if (m_update_info && m_update_info->TargetFullRelease)
        return m_update_info->TargetFullRelease->Size;
    return 0;
}

NuVelopackUpdater::CheckState NuVelopackUpdater::checkForUpdates(NuVelopackUpdateDetails& details)
{
    clearPendingUpdate();
    if (!ensureManager())
        return CheckState::NotAvailable;

    Asset* pending_restart_asset = nullptr;
    if (m_api->updatePendingRestart(m_manager, &pending_restart_asset) && pending_restart_asset) {
        m_pending_restart_asset = pending_restart_asset;
        details.version = targetVersion();
        details.packageName = targetPackageName();
        details.notesMarkdown = targetNotesMarkdown();
        details.size = targetSize();
        details.pendingRestart = true;
        m_downloaded = true;
        return CheckState::UpdateAvailable;
    }

    UpdateInfo* update_info = nullptr;
    const qint8 state = m_api->checkForUpdates(m_manager, &update_info);
    if (state == kUpdateAvailable && update_info && update_info->TargetFullRelease) {
        m_update_info = update_info;
        details.version = targetVersion();
        details.packageName = targetPackageName();
        details.notesMarkdown = targetNotesMarkdown();
        details.size = targetSize();
        details.pendingRestart = false;
        return CheckState::UpdateAvailable;
    }
    if (update_info) {
        m_api->freeUpdateInfo(update_info);
    }

    if (state == kNoUpdateAvailable || state == kRemoteIsEmpty) {
        return CheckState::NoUpdate;
    }

    Q_UNUSED(kUpdateError);
    m_last_error = runtimeError();
    if (m_last_error.isEmpty())
        m_last_error = QStringLiteral("Velopack could not check for updates.");
    return CheckState::Error;
}

bool NuVelopackUpdater::downloadPendingUpdate(const std::function<void(int)>& progress_callback)
{
    if (!m_update_info) {
        if (m_pending_restart_asset) {
            m_downloaded = true;
            return true;
        }
        m_last_error = QStringLiteral("No Velopack update is selected.");
        return false;
    }

    auto callback = [](void* user_data, size_t progress) {
        const auto* cb = static_cast<const std::function<void(int)>*>(user_data);
        if (cb && *cb)
            (*cb)(qBound(0, int(progress), 100));
    };

    if (!m_api->downloadUpdates(
            m_manager, m_update_info, callback, const_cast<std::function<void(int)>*>(&progress_callback))) {
        m_last_error = runtimeError();
        if (m_last_error.isEmpty())
            m_last_error = QStringLiteral("Velopack could not download the update.");
        return false;
    }

    m_downloaded = true;
    return true;
}

bool NuVelopackUpdater::applyPendingUpdate(bool restart)
{
    if (!m_downloaded) {
        m_last_error = QStringLiteral("Download the Velopack update before installing it.");
        return false;
    }

    Asset* asset = m_pending_restart_asset;
    if (!asset && m_update_info)
        asset = m_update_info->TargetFullRelease;
    if (!asset) {
        m_last_error = QStringLiteral("Velopack update metadata is no longer available.");
        return false;
    }

    if (!m_api->waitExitThenApplyUpdates(m_manager, asset, false, restart, nullptr, 0)) {
        m_last_error = runtimeError();
        if (m_last_error.isEmpty())
            m_last_error = QStringLiteral("Velopack could not launch the updater.");
        return false;
    }
    return true;
}
