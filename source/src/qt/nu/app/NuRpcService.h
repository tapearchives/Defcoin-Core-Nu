#ifndef DEFCOIN_NU_RPC_SERVICE_H
#define DEFCOIN_NU_RPC_SERVICE_H

#include <QByteArray>
#include <QDateTime>
#include <QElapsedTimer>
#include <QHash>
#include <QJsonArray>
#include <QJsonValue>
#include <QObject>
#include <QPair>
#include <QSet>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

#include <atomic>
#include <functional>
#include <memory>
#include <set>

class QNetworkAccessManager;
class QNetworkReply;
class QFile;
class QHostAddress;
class QJsonObject;
class QLockFile;
class QProcess;
class QTimer;
class QUdpSocket;
class NuVelopackUpdater;

class NuRpcService final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool rpcConnected READ rpcConnected NOTIFY stateChanged)
    Q_PROPERTY(QString connectionStatus READ connectionStatus NOTIFY stateChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY stateChanged)
    Q_PROPERTY(QString networkState READ networkState NOTIFY stateChanged)
    Q_PROPERTY(int peerCount READ peerCount NOTIFY stateChanged)
    Q_PROPERTY(int blockHeight READ blockHeight NOTIFY stateChanged)
    Q_PROPERTY(int headerHeight READ headerHeight NOTIFY stateChanged)
    Q_PROPERTY(bool syncing READ syncing NOTIFY stateChanged)
    Q_PROPERTY(QString syncState READ syncState NOTIFY stateChanged)
    Q_PROPERTY(QString syncDetail READ syncDetail NOTIFY stateChanged)
    Q_PROPERTY(QString syncEta READ syncEta NOTIFY stateChanged)
    Q_PROPERTY(int syncProgressPercent READ syncProgressPercent NOTIFY stateChanged)
    Q_PROPERTY(QString recentNetworkHashrate READ recentNetworkHashrate NOTIFY stateChanged)
    Q_PROPERTY(QString networkDifficulty READ networkDifficulty NOTIFY stateChanged)
    Q_PROPERTY(QString recentAverageBlockTime READ recentAverageBlockTime NOTIFY stateChanged)
    Q_PROPERTY(bool walletLocked READ walletLocked NOTIFY stateChanged)
    Q_PROPERTY(bool walletEncrypted READ walletEncrypted NOTIFY walletChanged)
    Q_PROPERTY(QString totalBalance READ totalBalance NOTIFY walletChanged)
    Q_PROPERTY(QString availableBalance READ availableBalance NOTIFY walletChanged)
    Q_PROPERTY(QString pendingBalance READ pendingBalance NOTIFY walletChanged)
    Q_PROPERTY(QString immatureBalance READ immatureBalance NOTIFY walletChanged)
    Q_PROPERTY(int walletTransactionCount READ walletTransactionCount NOTIFY walletChanged)
    Q_PROPERTY(QString receiveAddress READ receiveAddress NOTIFY walletChanged)
    Q_PROPERTY(QString receiveQrSource READ receiveQrSource NOTIFY walletChanged)
    Q_PROPERTY(QVariantList addressBook READ addressBook NOTIFY walletChanged)
    Q_PROPERTY(QVariantList receiveRequests READ receiveRequests NOTIFY walletChanged)
    Q_PROPERTY(QVariantList recentTransactions READ recentTransactions NOTIFY walletChanged)
    Q_PROPERTY(QStringList availableWallets READ availableWallets NOTIFY walletChanged)
    Q_PROPERTY(QStringList loadedWallets READ loadedWallets NOTIFY walletChanged)
    Q_PROPERTY(QString currentWalletName READ currentWalletName NOTIFY walletChanged)
    Q_PROPERTY(bool walletSelected READ walletSelected NOTIFY walletChanged)
    Q_PROPERTY(int walletAddressCount READ walletAddressCount NOTIFY walletChanged)
    Q_PROPERTY(int walletNonZeroAddressCount READ walletNonZeroAddressCount NOTIFY walletChanged)
    Q_PROPERTY(QVariantList walletFileStats READ walletFileStats NOTIFY walletChanged)
    Q_PROPERTY(QVariantList peers READ peers NOTIFY peersChanged)
    Q_PROPERTY(QVariantList peerRowsSimple READ peerRowsSimple NOTIFY peersChanged)
    Q_PROPERTY(QVariantList peerRowsDetailed READ peerRowsDetailed NOTIFY peersChanged)
    Q_PROPERTY(QVariantList bannedPeerRows READ bannedPeerRows NOTIFY peersChanged)
    Q_PROPERTY(QVariantList nodeMetrics READ nodeMetrics NOTIFY stateChanged)
    Q_PROPERTY(QVariantList trafficSamples READ trafficSamples NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficReceivedTotal READ trafficReceivedTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficSentTotal READ trafficSentTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficTcpReceivedTotal READ trafficTcpReceivedTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficTcpSentTotal READ trafficTcpSentTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficUdpReceivedTotal READ trafficUdpReceivedTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficUdpSentTotal READ trafficUdpSentTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficQuickCloneReceivedTotal READ trafficQuickCloneReceivedTotal NOTIFY trafficChanged)
    Q_PROPERTY(QString trafficQuickCloneSentTotal READ trafficQuickCloneSentTotal NOTIFY trafficChanged)
    Q_PROPERTY(QStringList logLines READ logLines NOTIFY logChanged)
    Q_PROPERTY(QVariantList logLineNumbers READ logLineNumbers NOTIFY logChanged)
    Q_PROPERTY(QString consoleOutput READ consoleOutput NOTIFY consoleChanged)
    Q_PROPERTY(QString paperWalletAddress READ paperWalletAddress NOTIFY walletChanged)
    Q_PROPERTY(QString paperWalletWif READ paperWalletWif NOTIFY walletChanged)
    Q_PROPERTY(QString paperWalletStatus READ paperWalletStatus NOTIFY walletChanged)
    Q_PROPERTY(bool paperWalletReady READ paperWalletReady NOTIFY walletChanged)
    Q_PROPERTY(bool feeEstimateAvailable READ feeEstimateAvailable NOTIFY feeEstimateChanged)
    Q_PROPERTY(QString feeEstimateStatus READ feeEstimateStatus NOTIFY feeEstimateChanged)
    Q_PROPERTY(bool psbtLoaded READ psbtLoaded NOTIFY psbtChanged)
    Q_PROPERTY(bool psbtFinalized READ psbtFinalized NOTIFY psbtChanged)
    Q_PROPERTY(QString currentPsbtSummary READ currentPsbtSummary NOTIFY psbtChanged)
    Q_PROPERTY(
        bool onlyDefcoinUserAgents READ onlyDefcoinUserAgents WRITE setOnlyDefcoinUserAgents NOTIFY settingsChanged)
    Q_PROPERTY(
        bool onlyDefcoinMagicBytes READ onlyDefcoinMagicBytes WRITE setOnlyDefcoinMagicBytes NOTIFY settingsChanged)
    Q_PROPERTY(bool switchToDefcoinOnlyMagicStartingJuly2026 READ switchToDefcoinOnlyMagicStartingJuly2026 WRITE
                   setSwitchToDefcoinOnlyMagicStartingJuly2026 NOTIFY settingsChanged)
    Q_PROPERTY(bool disallowLanNodeDiscovery READ disallowLanNodeDiscovery WRITE setDisallowLanNodeDiscovery NOTIFY
                   settingsChanged)
    Q_PROPERTY(bool lanNodeDiscoveryEnabled READ lanNodeDiscoveryEnabled WRITE setLanNodeDiscoveryEnabled NOTIFY
                   settingsChanged)
    Q_PROPERTY(bool lanFastSyncEnabled READ lanFastSyncEnabled WRITE setLanFastSyncEnabled NOTIFY settingsChanged)
    Q_PROPERTY(QString lanFastSyncStatus READ lanFastSyncStatus NOTIFY stateChanged)
    Q_PROPERTY(bool lanQuickCloneEnabled READ lanQuickCloneEnabled WRITE setLanQuickCloneEnabled NOTIFY settingsChanged)
    Q_PROPERTY(QString lanQuickCloneStatus READ lanQuickCloneStatus NOTIFY stateChanged)
    Q_PROPERTY(bool quickCloneAutoValidateAfter READ quickCloneAutoValidateAfter WRITE setQuickCloneAutoValidateAfter
                   NOTIFY settingsChanged)
    Q_PROPERTY(QString quickCloneValidationStatus READ quickCloneValidationStatus NOTIFY stateChanged)
    Q_PROPERTY(bool quickCloneValidationRunning READ quickCloneValidationRunning NOTIFY stateChanged)
    Q_PROPERTY(bool advancedToolsVisible READ advancedToolsVisible WRITE setAdvancedToolsVisible NOTIFY settingsChanged)
    Q_PROPERTY(
        bool upnpConnectionsEnabled READ upnpConnectionsEnabled WRITE setUpnpConnectionsEnabled NOTIFY settingsChanged)
    Q_PROPERTY(bool showLanNodeDiscoveryNotice READ showLanNodeDiscoveryNotice NOTIFY settingsChanged)
    Q_PROPERTY(bool automaticUpdateChecksEnabled READ automaticUpdateChecksEnabled WRITE setAutomaticUpdateChecksEnabled
                   NOTIFY settingsChanged)
    Q_PROPERTY(QString tableCopyDelimiterStyle READ tableCopyDelimiterStyle WRITE setTableCopyDelimiterStyle NOTIFY
                   settingsChanged)
    Q_PROPERTY(QString tableCopyCustomDelimiter READ tableCopyCustomDelimiter WRITE setTableCopyCustomDelimiter NOTIFY
                   settingsChanged)
    Q_PROPERTY(int logVerbosity READ logVerbosity WRITE setLogVerbosity NOTIFY settingsChanged)
    Q_PROPERTY(QString logSearchPattern READ logSearchPattern WRITE setLogSearchPattern NOTIFY settingsChanged)
    Q_PROPERTY(QString logLastSearchPattern READ logLastSearchPattern NOTIFY settingsChanged)
    Q_PROPERTY(QString logRemovePattern READ logRemovePattern WRITE setLogRemovePattern NOTIFY settingsChanged)
    Q_PROPERTY(
        bool backgroundCloseEnabled READ backgroundCloseEnabled WRITE setBackgroundCloseEnabled NOTIFY settingsChanged)
    Q_PROPERTY(QString updateStatus READ updateStatus NOTIFY updateStatusChanged)
    Q_PROPERTY(int updateDownloadProgress READ updateDownloadProgress NOTIFY updateStatusChanged)
    Q_PROPERTY(bool recoveryActive READ recoveryActive NOTIFY recoveryChanged)
    Q_PROPERTY(bool recoveryFinished READ recoveryFinished NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryStatus READ recoveryStatus NOTIFY recoveryChanged)
    Q_PROPERTY(int recoveryProgress READ recoveryProgress NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryFoundAmount READ recoveryFoundAmount NOTIFY recoveryChanged)
    Q_PROPERTY(int recoveryFoundAddressCount READ recoveryFoundAddressCount NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryRecentFoundAddress READ recoveryRecentFoundAddress NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryDetectedMethod READ recoveryDetectedMethod NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryCurrentMethod READ recoveryCurrentMethod NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryElapsed READ recoveryElapsed NOTIFY recoveryChanged)
    Q_PROPERTY(QString recoveryEta READ recoveryEta NOTIFY recoveryChanged)
    Q_PROPERTY(bool recoveryCancelable READ recoveryCancelable NOTIFY recoveryChanged)
    Q_PROPERTY(QStringList bip39EnglishWords READ bip39EnglishWords CONSTANT)
    Q_PROPERTY(QString minerExecutable READ minerExecutable NOTIFY minerChanged)
    Q_PROPERTY(QString minerPoolUrl READ minerPoolUrl NOTIFY minerChanged)
    Q_PROPERTY(QString minerPayoutAddress READ minerPayoutAddress NOTIFY minerChanged)
    Q_PROPERTY(QString minerPassword READ minerPassword NOTIFY minerChanged)
    Q_PROPERTY(int minerThreads READ minerThreads NOTIFY minerChanged)
    Q_PROPERTY(int minerNiceLevel READ minerNiceLevel NOTIFY minerChanged)
    Q_PROPERTY(QString minerStatus READ minerStatus NOTIFY minerChanged)
    Q_PROPERTY(QString minerLog READ minerLog NOTIFY minerChanged)
    Q_PROPERTY(bool minerRunning READ minerRunning NOTIFY minerChanged)
    Q_PROPERTY(QString miningStateText READ miningStateText NOTIFY minerChanged)
    Q_PROPERTY(QString miningMethodText READ miningMethodText NOTIFY minerChanged)
    Q_PROPERTY(QString minerHashrateText READ minerHashrateText NOTIFY minerChanged)
    Q_PROPERTY(int minerAcceptedShares READ minerAcceptedShares NOTIFY minerChanged)
    Q_PROPERTY(int minerRejectedShares READ minerRejectedShares NOTIFY minerChanged)
    Q_PROPERTY(QString minerSummaryText READ minerSummaryText NOTIFY minerChanged)
    Q_PROPERTY(bool maskBalances READ maskBalances WRITE setMaskBalances NOTIFY settingsChanged)
    Q_PROPERTY(bool thirdPartyTxUrlsEnabled READ thirdPartyTxUrlsEnabled WRITE setThirdPartyTxUrlsEnabled NOTIFY
                   settingsChanged)
    Q_PROPERTY(QString thirdPartyTxUrl READ thirdPartyTxUrl WRITE setThirdPartyTxUrl NOTIFY settingsChanged)
    Q_PROPERTY(QString explorerMode READ explorerMode NOTIFY settingsChanged)
    Q_PROPERTY(QString explorerDatabasePath READ explorerDatabasePath NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList explorerRecentLookups READ explorerRecentLookups NOTIFY explorerChanged)
    Q_PROPERTY(bool explorerIndexing READ explorerIndexing NOTIFY explorerChanged)
    Q_PROPERTY(QString explorerIndexStatus READ explorerIndexStatus NOTIFY explorerChanged)
    Q_PROPERTY(int explorerIndexHeight READ explorerIndexHeight NOTIFY explorerChanged)
    Q_PROPERTY(int explorerIndexTip READ explorerIndexTip NOTIFY explorerChanged)
    Q_PROPERTY(int explorerIndexedBlockCount READ explorerIndexedBlockCount NOTIFY explorerChanged)
    Q_PROPERTY(int explorerIndexedOutputCount READ explorerIndexedOutputCount NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList explorerRichList READ explorerRichList NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList explorerMovements READ explorerMovements NOTIFY explorerChanged)
    Q_PROPERTY(QVariantMap coindroidsSummary READ coindroidsSummary NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsWindowRows READ coindroidsWindowRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsEndpointRows READ coindroidsEndpointRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsWinnerRows READ coindroidsWinnerRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsPhaseRows READ coindroidsPhaseRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsPublishedRows READ coindroidsPublishedRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsVanityRows READ coindroidsVanityRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsOpReturnRows READ coindroidsOpReturnRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsBotRows READ coindroidsBotRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsPayoutRows READ coindroidsPayoutRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsAttackAddressRows READ coindroidsAttackAddressRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsQrSeedRows READ coindroidsQrSeedRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsSourceAmmoRows READ coindroidsSourceAmmoRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsOloRows READ coindroidsOloRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsGameAddressRows READ coindroidsGameAddressRows NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList coindroidsEvidenceRows READ coindroidsEvidenceRows NOTIFY explorerChanged)
    Q_PROPERTY(QString coindroidsStatus READ coindroidsStatus NOTIFY explorerChanged)
    Q_PROPERTY(bool coindroidsScanning READ coindroidsScanning NOTIFY explorerChanged)
    Q_PROPERTY(QVariantMap defcoinTimelineSummary READ defcoinTimelineSummary NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList defcoinTimelineRows READ defcoinTimelineRows NOTIFY explorerChanged)
    Q_PROPERTY(QString defcoinTimelineCriteria READ defcoinTimelineCriteria NOTIFY explorerChanged)
    Q_PROPERTY(QString defcoinTimelineStatus READ defcoinTimelineStatus NOTIFY explorerChanged)
    Q_PROPERTY(QVariantMap networkPulseSummary READ networkPulseSummary NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList networkPulseHistoryRows READ networkPulseHistoryRows NOTIFY explorerChanged)
    Q_PROPERTY(QString networkPulseStatus READ networkPulseStatus NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList explorerContactSets READ explorerContactSets NOTIFY explorerChanged)
    Q_PROPERTY(QString currentExplorerContactSetName READ currentExplorerContactSetName NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList explorerContacts READ explorerContacts NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList explorerContactRelationships READ explorerContactRelationships NOTIFY explorerChanged)
    Q_PROPERTY(QString explorerAnalyticsStatus READ explorerAnalyticsStatus NOTIFY explorerChanged)
    Q_PROPERTY(bool explorerTop100Scanning READ explorerTop100Scanning NOTIFY explorerChanged)
    Q_PROPERTY(bool explorerTop100FocusedIndexing READ explorerTop100FocusedIndexing WRITE
                   setExplorerTop100FocusedIndexing NOTIFY settingsChanged)
    Q_PROPERTY(QString explorerTop100Status READ explorerTop100Status NOTIFY explorerChanged)
    Q_PROPERTY(int explorerTop100ScanHeight READ explorerTop100ScanHeight NOTIFY explorerChanged)
    Q_PROPERTY(int explorerTop100ScanEndHeight READ explorerTop100ScanEndHeight NOTIFY explorerChanged)
    Q_PROPERTY(int explorerTop100TimelineStartHeight READ explorerTop100TimelineStartHeight NOTIFY explorerChanged)
    Q_PROPERTY(int explorerTop100TimelineEndHeight READ explorerTop100TimelineEndHeight NOTIFY explorerChanged)
    Q_PROPERTY(int explorerTop100TimelineEventCount READ explorerTop100TimelineEventCount NOTIFY explorerChanged)
    Q_PROPERTY(QVariantList forensicsIrregularMessages READ forensicsIrregularMessages NOTIFY forensicsChanged)
    Q_PROPERTY(bool forensicsScanning READ forensicsScanning NOTIFY forensicsChanged)
    Q_PROPERTY(QString forensicsScanStatus READ forensicsScanStatus NOTIFY forensicsChanged)
    Q_PROPERTY(QString forensicsScanSummary READ forensicsScanSummary NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsScanHeight READ forensicsScanHeight NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsScanTip READ forensicsScanTip NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsIrregularMessageCount READ forensicsIrregularMessageCount NOTIFY forensicsChanged)
    Q_PROPERTY(bool forensicsScanComplete READ forensicsScanComplete NOTIFY forensicsChanged)
    Q_PROPERTY(bool forensicsAcceptBip141AsRegular READ forensicsAcceptBip141AsRegular WRITE
                   setForensicsAcceptBip141AsRegular NOTIFY settingsChanged)
    Q_PROPERTY(bool forensicsMissingWitnessFound READ forensicsMissingWitnessFound NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsFirstMissingWitnessHeight READ forensicsFirstMissingWitnessHeight NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsMissingWitnessCount READ forensicsMissingWitnessCount NOTIFY forensicsChanged)
    Q_PROPERTY(bool forensicsWitnessRepairRunning READ forensicsWitnessRepairRunning NOTIFY forensicsChanged)
    Q_PROPERTY(
        bool forensicsWitnessInspectionAvailable READ forensicsWitnessInspectionAvailable NOTIFY forensicsChanged)
    Q_PROPERTY(QString forensicsWitnessRepairStatus READ forensicsWitnessRepairStatus NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsWitnessRepairStartHeight READ forensicsWitnessRepairStartHeight NOTIFY forensicsChanged)
    Q_PROPERTY(
        int forensicsWitnessRepairInspectedBlocks READ forensicsWitnessRepairInspectedBlocks NOTIFY forensicsChanged)
    Q_PROPERTY(int forensicsWitnessRepairFirstMissingHeight READ forensicsWitnessRepairFirstMissingHeight NOTIFY
                   forensicsChanged)

public:
    explicit NuRpcService(QObject* parent = nullptr);
    ~NuRpcService() override;

    bool rpcConnected() const
    {
        return m_rpc_connected;
    }
    QString connectionStatus() const
    {
        return m_connection_status;
    }
    QString lastError() const
    {
        return m_last_error;
    }
    QString networkState() const
    {
        return m_network_state;
    }
    int peerCount() const
    {
        return m_peer_count;
    }
    int blockHeight() const
    {
        return m_block_height;
    }
    int headerHeight() const
    {
        return m_header_height;
    }
    bool syncing() const
    {
        return m_syncing;
    }
    QString syncState() const
    {
        return m_sync_state;
    }
    QString syncDetail() const
    {
        return m_sync_detail;
    }
    QString syncEta() const
    {
        return m_sync_eta;
    }
    int syncProgressPercent() const
    {
        return m_sync_progress_percent;
    }
    QString recentNetworkHashrate() const
    {
        return m_metric_network_hashrate;
    }
    QString networkDifficulty() const
    {
        return m_metric_difficulty;
    }
    QString recentAverageBlockTime() const
    {
        return m_metric_average_block_time;
    }
    bool walletLocked() const
    {
        return m_wallet_locked;
    }
    bool walletEncrypted() const
    {
        return m_wallet_encrypted;
    }
    QString totalBalance() const
    {
        return m_mask_balances ? QStringLiteral("******** DFC") : m_total_balance;
    }
    QString availableBalance() const
    {
        return m_mask_balances ? QStringLiteral("********") : m_available_balance;
    }
    QString pendingBalance() const
    {
        return m_mask_balances ? QStringLiteral("********") : m_pending_balance;
    }
    QString immatureBalance() const
    {
        return m_mask_balances ? QStringLiteral("********") : m_immature_balance;
    }
    int walletTransactionCount() const
    {
        return m_wallet_transaction_count;
    }
    QString receiveAddress() const
    {
        return m_receive_address;
    }
    QString receiveQrSource() const
    {
        return m_receive_qr_source;
    }
    QVariantList addressBook() const
    {
        return m_address_book;
    }
    QVariantList receiveRequests() const
    {
        return m_receive_requests;
    }
    QVariantList recentTransactions() const
    {
        return m_recent_transactions;
    }
    QStringList availableWallets() const
    {
        return m_available_wallets;
    }
    QStringList loadedWallets() const
    {
        return m_loaded_wallets;
    }
    QString currentWalletName() const
    {
        return m_wallet_name;
    }
    bool walletSelected() const
    {
        return m_wallet_selected;
    }
    int walletAddressCount() const
    {
        return m_wallet_address_count;
    }
    int walletNonZeroAddressCount() const
    {
        return m_wallet_nonzero_address_count;
    }
    QVariantList walletFileStats() const
    {
        return m_wallet_file_stats;
    }
    QVariantList peers() const
    {
        return m_peers;
    }
    QVariantList peerRowsSimple() const
    {
        return m_peer_rows_simple;
    }
    QVariantList peerRowsDetailed() const
    {
        return m_peer_rows_detailed;
    }
    QVariantList bannedPeerRows() const
    {
        return m_banned_peer_rows;
    }
    QVariantList nodeMetrics() const
    {
        return m_node_metrics;
    }
    QVariantList trafficSamples() const
    {
        return m_traffic_samples;
    }
    QString trafficReceivedTotal() const
    {
        return m_traffic_received_total;
    }
    QString trafficSentTotal() const
    {
        return m_traffic_sent_total;
    }
    QString trafficTcpReceivedTotal() const
    {
        return m_traffic_tcp_received_total;
    }
    QString trafficTcpSentTotal() const
    {
        return m_traffic_tcp_sent_total;
    }
    QString trafficUdpReceivedTotal() const
    {
        return m_traffic_udp_received_total;
    }
    QString trafficUdpSentTotal() const
    {
        return m_traffic_udp_sent_total;
    }
    QString trafficQuickCloneReceivedTotal() const
    {
        return m_traffic_quick_clone_received_total;
    }
    QString trafficQuickCloneSentTotal() const
    {
        return m_traffic_quick_clone_sent_total;
    }
    QStringList logLines() const
    {
        return m_log_lines;
    }
    QVariantList logLineNumbers() const
    {
        return m_log_line_numbers;
    }
    QString consoleOutput() const
    {
        return m_console_output;
    }
    QString paperWalletAddress() const
    {
        return m_paper_wallet_address;
    }
    QString paperWalletWif() const
    {
        return m_paper_wallet_wif;
    }
    QString paperWalletStatus() const
    {
        return m_paper_wallet_status;
    }
    bool paperWalletReady() const
    {
        return !m_paper_wallet_address.isEmpty() && !m_paper_wallet_wif.isEmpty();
    }
    bool feeEstimateAvailable() const
    {
        return m_fee_estimate_available;
    }
    QString feeEstimateStatus() const
    {
        return m_fee_estimate_status;
    }
    bool psbtLoaded() const
    {
        return !m_current_psbt.isEmpty();
    }
    bool psbtFinalized() const
    {
        return !m_current_psbt_final_hex.isEmpty();
    }
    QString currentPsbtSummary() const
    {
        return m_current_psbt_summary;
    }
    bool onlyDefcoinUserAgents() const
    {
        return m_only_defcoin_user_agents;
    }
    bool onlyDefcoinMagicBytes() const
    {
        return m_only_defcoin_magic_bytes;
    }
    bool switchToDefcoinOnlyMagicStartingJuly2026() const
    {
        return m_switch_to_defcoin_only_magic_starting_july_2026;
    }
    bool disallowLanNodeDiscovery() const
    {
        return !m_lan_node_discovery_enabled;
    }
    bool lanNodeDiscoveryEnabled() const
    {
        return m_lan_node_discovery_enabled;
    }
    bool lanFastSyncEnabled() const
    {
        return m_lan_fast_sync_enabled;
    }
    QString lanFastSyncStatus() const
    {
        return m_lan_fast_sync_status;
    }
    bool lanQuickCloneEnabled() const
    {
        return m_lan_quick_clone_enabled;
    }
    QString lanQuickCloneStatus() const
    {
        return m_lan_quick_clone_status;
    }
    bool quickCloneAutoValidateAfter() const
    {
        return m_quick_clone_auto_validate_after;
    }
    QString quickCloneValidationStatus() const
    {
        return m_quick_clone_validation_status;
    }
    bool quickCloneValidationRunning() const
    {
        return m_quick_clone_validation_running;
    }
    bool advancedToolsVisible() const
    {
        return m_advanced_tools_visible;
    }
    bool upnpConnectionsEnabled() const
    {
        return m_upnp_connections_enabled;
    }
    bool showLanNodeDiscoveryNotice() const
    {
        return !m_lan_node_discovery_notice_acknowledged && !m_lan_node_discovery_enabled;
    }
    bool automaticUpdateChecksEnabled() const
    {
        return m_automatic_update_checks_enabled;
    }
    QString tableCopyDelimiterStyle() const
    {
        return m_table_copy_delimiter_style;
    }
    QString tableCopyCustomDelimiter() const
    {
        return m_table_copy_custom_delimiter;
    }
    int logVerbosity() const
    {
        return m_log_verbosity;
    }
    QString logSearchPattern() const
    {
        return m_log_search_pattern;
    }
    QString logLastSearchPattern() const
    {
        return m_log_last_search_pattern;
    }
    QString logRemovePattern() const
    {
        return m_log_remove_pattern;
    }
    bool backgroundCloseEnabled() const
    {
        return m_background_close_enabled;
    }
    QString updateStatus() const
    {
        return m_update_status;
    }
    int updateDownloadProgress() const
    {
        return m_update_download_progress;
    }
    bool recoveryActive() const
    {
        return m_recovery_active;
    }
    bool recoveryFinished() const
    {
        return m_recovery_finished;
    }
    QString recoveryStatus() const
    {
        return m_recovery_status;
    }
    int recoveryProgress() const
    {
        return m_recovery_progress;
    }
    QString recoveryFoundAmount() const
    {
        return m_recovery_found_amount;
    }
    int recoveryFoundAddressCount() const
    {
        return m_recovery_found_address_count;
    }
    QString recoveryRecentFoundAddress() const
    {
        return m_recovery_recent_found_address;
    }
    QString recoveryDetectedMethod() const
    {
        return m_recovery_detected_method;
    }
    QString recoveryCurrentMethod() const
    {
        return m_recovery_current_method;
    }
    QString recoveryElapsed() const
    {
        return m_recovery_elapsed;
    }
    QString recoveryEta() const
    {
        return m_recovery_eta;
    }
    bool recoveryCancelable() const
    {
        return m_recovery_cancelable;
    }
    QStringList bip39EnglishWords() const;
    QString minerExecutable() const
    {
        return m_miner_executable;
    }
    QString minerPoolUrl() const
    {
        return m_miner_pool_url;
    }
    QString minerPayoutAddress() const
    {
        return m_miner_payout_address;
    }
    QString minerPassword() const
    {
        return m_miner_password;
    }
    int minerThreads() const
    {
        return m_miner_threads;
    }
    int minerNiceLevel() const
    {
        return m_miner_nice_level;
    }
    QString minerStatus() const
    {
        return m_miner_status;
    }
    QString minerLog() const
    {
        return m_miner_log;
    }
    bool minerRunning() const;
    QString miningStateText() const;
    QString miningMethodText() const;
    QString minerHashrateText() const
    {
        return m_miner_hashrate_text;
    }
    int minerAcceptedShares() const
    {
        return m_miner_accepted_shares;
    }
    int minerRejectedShares() const
    {
        return m_miner_rejected_shares;
    }
    QString minerSummaryText() const;
    QString walletMiningPayoutAddress() const;
    bool maskBalances() const
    {
        return m_mask_balances;
    }
    bool thirdPartyTxUrlsEnabled() const
    {
        return m_third_party_tx_urls_enabled;
    }
    QString thirdPartyTxUrl() const
    {
        return m_third_party_tx_url;
    }
    QString explorerMode() const
    {
        return m_explorer_mode;
    }
    QString explorerDatabasePath() const;
    QVariantList explorerRecentLookups() const
    {
        return m_explorer_recent_lookups;
    }
    bool explorerIndexing() const
    {
        return m_explorer_indexing;
    }
    QString explorerIndexStatus() const
    {
        return m_explorer_index_status;
    }
    int explorerIndexHeight() const
    {
        return m_explorer_index_height;
    }
    int explorerIndexTip() const
    {
        return m_explorer_index_tip;
    }
    int explorerIndexedBlockCount() const
    {
        return m_explorer_indexed_block_count;
    }
    int explorerIndexedOutputCount() const
    {
        return m_explorer_indexed_output_count;
    }
    QVariantList explorerRichList() const
    {
        return m_explorer_rich_list;
    }
    QVariantList explorerMovements() const
    {
        return m_explorer_movements;
    }
    QVariantMap coindroidsSummary() const
    {
        return m_coindroids_summary;
    }
    QVariantList coindroidsWindowRows() const
    {
        return m_coindroids_window_rows;
    }
    QVariantList coindroidsEndpointRows() const
    {
        return m_coindroids_endpoint_rows;
    }
    QVariantList coindroidsWinnerRows() const
    {
        return m_coindroids_winner_rows;
    }
    QVariantList coindroidsPhaseRows() const
    {
        return m_coindroids_phase_rows;
    }
    QVariantList coindroidsPublishedRows() const
    {
        return m_coindroids_published_rows;
    }
    QVariantList coindroidsVanityRows() const
    {
        return m_coindroids_vanity_rows;
    }
    QVariantList coindroidsOpReturnRows() const
    {
        return m_coindroids_op_return_rows;
    }
    QVariantList coindroidsBotRows() const
    {
        return m_coindroids_bot_rows;
    }
    QVariantList coindroidsPayoutRows() const
    {
        return m_coindroids_payout_rows;
    }
    QVariantList coindroidsAttackAddressRows() const
    {
        return m_coindroids_attack_address_rows;
    }
    QVariantList coindroidsQrSeedRows() const
    {
        return m_coindroids_qr_seed_rows;
    }
    QVariantList coindroidsSourceAmmoRows() const
    {
        return m_coindroids_source_ammo_rows;
    }
    QVariantList coindroidsOloRows() const
    {
        return m_coindroids_olo_rows;
    }
    QVariantList coindroidsGameAddressRows() const
    {
        return m_coindroids_game_address_rows;
    }
    QVariantList coindroidsEvidenceRows() const
    {
        return m_coindroids_evidence_rows;
    }
    QString coindroidsStatus() const
    {
        return m_coindroids_status;
    }
    bool coindroidsScanning() const
    {
        return m_coindroids_scanning;
    }
    QVariantMap defcoinTimelineSummary() const
    {
        return m_defcoin_timeline_summary;
    }
    QVariantList defcoinTimelineRows() const
    {
        return m_defcoin_timeline_rows;
    }
    QString defcoinTimelineCriteria() const
    {
        return m_defcoin_timeline_criteria;
    }
    QString defcoinTimelineStatus() const
    {
        return m_defcoin_timeline_status;
    }
    QVariantMap networkPulseSummary() const
    {
        return m_network_pulse_summary;
    }
    QVariantList networkPulseHistoryRows() const
    {
        return m_network_pulse_history_rows;
    }
    QString networkPulseStatus() const
    {
        return m_network_pulse_status;
    }
    QVariantList explorerContactSets() const
    {
        return m_explorer_contact_sets;
    }
    QString currentExplorerContactSetName() const
    {
        return m_current_explorer_contact_set_name;
    }
    QVariantList explorerContacts() const
    {
        return m_explorer_contacts;
    }
    QVariantList explorerContactRelationships() const
    {
        return m_explorer_contact_relationships;
    }
    QString explorerAnalyticsStatus() const
    {
        return m_explorer_analytics_status;
    }
    bool explorerTop100Scanning() const
    {
        return m_explorer_top100_scanning;
    }
    bool explorerTop100FocusedIndexing() const
    {
        return m_explorer_top100_focused_indexing;
    }
    QString explorerTop100Status() const
    {
        return m_explorer_top100_status;
    }
    int explorerTop100ScanHeight() const
    {
        return m_explorer_top100_scan_height;
    }
    int explorerTop100ScanEndHeight() const
    {
        return m_explorer_top100_scan_end_height;
    }
    int explorerTop100TimelineStartHeight() const
    {
        return m_explorer_top100_timeline_start_height;
    }
    int explorerTop100TimelineEndHeight() const
    {
        return m_explorer_top100_timeline_end_height;
    }
    int explorerTop100TimelineEventCount() const
    {
        return m_explorer_top100_timeline_event_count;
    }
    QVariantList forensicsIrregularMessages() const
    {
        return m_forensics_irregular_messages;
    }
    bool forensicsScanning() const
    {
        return m_forensics_scanning;
    }
    QString forensicsScanStatus() const
    {
        return m_forensics_scan_status;
    }
    QString forensicsScanSummary() const
    {
        return m_forensics_scan_summary;
    }
    int forensicsScanHeight() const
    {
        return m_forensics_scan_height;
    }
    int forensicsScanTip() const
    {
        return m_forensics_scan_tip;
    }
    int forensicsIrregularMessageCount() const
    {
        return m_forensics_irregular_messages.size();
    }
    bool forensicsScanComplete() const
    {
        return m_forensics_scan_complete;
    }
    bool forensicsAcceptBip141AsRegular() const
    {
        return m_forensics_accept_bip141_as_regular;
    }
    bool forensicsMissingWitnessFound() const
    {
        return m_forensics_missing_witness_found;
    }
    int forensicsFirstMissingWitnessHeight() const
    {
        return m_forensics_first_missing_witness_height;
    }
    int forensicsMissingWitnessCount() const
    {
        return m_forensics_missing_witness_count;
    }
    bool forensicsWitnessRepairRunning() const
    {
        return m_forensics_witness_repair_running;
    }
    bool forensicsWitnessInspectionAvailable() const
    {
        return m_forensics_witness_inspection_available;
    }
    QString forensicsWitnessRepairStatus() const
    {
        return m_forensics_witness_repair_status;
    }
    int forensicsWitnessRepairStartHeight() const
    {
        return m_forensics_witness_repair_start_height;
    }
    int forensicsWitnessRepairInspectedBlocks() const
    {
        return m_forensics_witness_repair_inspected_blocks;
    }
    int forensicsWitnessRepairFirstMissingHeight() const
    {
        return m_forensics_witness_repair_first_missing_height;
    }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void requestNewAddress(const QString& label = QString(),
                                       const QString& amount = QString(),
                                       const QString& message = QString());
    Q_INVOKABLE void deleteReceiveRequest(const QString& address);
    Q_INVOKABLE void deleteReceiveRequests(const QVariantList& addresses);
    Q_INVOKABLE void sendCoins(const QString& address,
                               const QString& amount,
                               const QString& fee_mode = QStringLiteral("recommended"),
                               const QString& fee_target = QStringLiteral("6"),
                               const QString& custom_fee_rate = QString(),
                               bool subtract_fee_from_amount = false,
                               const QString& label = QString(),
                               const QString& custom_change_address = QString());
    Q_INVOKABLE void createPsbt(const QString& address,
                                const QString& amount,
                                const QString& fee_mode = QStringLiteral("recommended"),
                                const QString& fee_target = QStringLiteral("6"),
                                const QString& custom_fee_rate = QString(),
                                bool subtract_fee_from_amount = false,
                                const QString& label = QString(),
                                const QString& custom_change_address = QString());
    Q_INVOKABLE void setAddressLabel(const QString& address, const QString& label);
    Q_INVOKABLE void setNetworkActive(bool active);
    Q_INVOKABLE void scheduleWitnessBlockRepair(int start_height);
    Q_INVOKABLE void repairWitnessBlockDataNow(int start_height, bool fix_missing_witness = true);
    Q_INVOKABLE void syncUsingQuickCloneNow();
    Q_INVOKABLE void acceptQuickClonePrompt();
    Q_INVOKABLE void declineQuickClonePrompt();
    Q_INVOKABLE void validateExistingBlockchain();
    Q_INVOKABLE void pingPeers();
    Q_INVOKABLE void refreshPeer(const QString& node_id);
    Q_INVOKABLE void banPeer(const QString& node_id);
    Q_INVOKABLE void unbanPeer(const QString& address);
    Q_INVOKABLE void refreshBannedPeers();
    Q_INVOKABLE void runRpcCommand(const QString& method, const QString& params_json, bool wallet_scoped);
    Q_INVOKABLE void runRpcConsoleCommand(const QString& command_text, const QString& wallet_name);
    Q_INVOKABLE void clearConsoleOutput();
    Q_INVOKABLE void generatePaperWallet(bool import_public_address = false, const QString& label = QString());
    Q_INVOKABLE void importWatchOnlyAddress(const QString& address,
                                            const QString& label,
                                            bool rescan = false,
                                            int start_height = -1);
    Q_INVOKABLE QString walletDisplayName(const QString& name) const;
    Q_INVOKABLE void copyText(const QString& text);
    Q_INVOKABLE void copySensitiveTextAfterWarning(const QString& text);
    Q_INVOKABLE void openExternalUrl(const QString& url);
    Q_INVOKABLE void backupWallet();
    Q_INVOKABLE void refreshWalletStats();
    Q_INVOKABLE void createWallet(const QString& name,
                                  bool encrypt = false,
                                  const QString& passphrase = QString(),
                                  bool disable_private_keys = false,
                                  bool blank = false,
                                  bool descriptor_sql = true);
    Q_INVOKABLE void setCurrentWallet(const QString& name);
    Q_INVOKABLE void loadWallet(const QString& name);
    Q_INVOKABLE void openWallets(const QVariantList& names);
    Q_INVOKABLE void closeWallet(const QString& name = QString());
    Q_INVOKABLE void closeAllWallets();
    Q_INVOKABLE void renameWallet(const QString& old_name, const QString& new_name);
    Q_INVOKABLE void deleteWallet(const QString& name);
    Q_INVOKABLE void encryptWallet(const QString& passphrase);
    Q_INVOKABLE void changeWalletPassphrase(const QString& old_passphrase, const QString& new_passphrase);
    Q_INVOKABLE void signMessage(const QString& address, const QString& message);
    Q_INVOKABLE void verifyMessage(const QString& address, const QString& signature, const QString& message);
    Q_INVOKABLE void openDebugLog();
    Q_INVOKABLE void saveLaunchLog(const QString& text);
    Q_INVOKABLE void openHelpManual(const QString& page = QString());
    Q_INVOKABLE QString helpManualHtml(const QString& page = QString()) const;
    Q_INVOKABLE void exportTransactionsCsv();
    Q_INVOKABLE void exportTrafficCsv();
    Q_INVOKABLE QVariantList tableColumnWidths(const QString& table_id, const QVariantList& default_widths) const;
    Q_INVOKABLE QVariantList suggestedTableColumnWidths(const QVariantList& columns,
                                                        const QVariantList& rows,
                                                        const QVariantList& column_types,
                                                        const QVariantList& column_weights,
                                                        const QVariantList& column_minimums,
                                                        const QVariantList& column_maximums,
                                                        int available_width,
                                                        int font_pixel_size,
                                                        bool compact) const;
    Q_INVOKABLE void saveTableColumnWidths(const QString& table_id, const QVariantList& widths);
    Q_INVOKABLE void resetTableColumnWidths(const QString& table_id = QString());
    Q_INVOKABLE void loadPsbtFromFile();
    Q_INVOKABLE void loadPsbtFromClipboard();
    Q_INVOKABLE void signCurrentPsbt();
    Q_INVOKABLE void finalizeCurrentPsbt();
    Q_INVOKABLE void broadcastFinalizedPsbt();
    Q_INVOKABLE void copyCurrentPsbt();
    Q_INVOKABLE void saveCurrentPsbt();
    Q_INVOKABLE void clearCurrentPsbt();
    Q_INVOKABLE void requestTransactionDetails(const QString& txid);
    Q_INVOKABLE void acknowledgeLanNodeDiscoveryNotice();
    Q_INVOKABLE QString receiveRequestQrSource(const QString& uri) const;
    Q_INVOKABLE QString explorerPresetUrl(int index) const;
    Q_INVOKABLE QString explorerUrlForTransaction(const QString& txid) const;
    Q_INVOKABLE QString explorerUrlForAddress(const QString& address) const;
    Q_INVOKABLE void openTransactionInExplorer(const QString& txid);
    Q_INVOKABLE void openAddressInExplorer(const QString& address);
    Q_INVOKABLE void openBlockInExplorer(const QString& block_id);
    Q_INVOKABLE void searchExplorer(const QString& query);
    Q_INVOKABLE void openExplorerLink(const QString& link);
    Q_INVOKABLE void refreshExplorerRecentLookups();
    Q_INVOKABLE void refreshExplorerAnalytics(int movement_threshold_coins = 5000,
                                              const QString& scope = QStringLiteral("all"));
    Q_INVOKABLE void refreshCoindroidsAnalytics();
    Q_INVOKABLE void refreshDefcoinTimeline();
    Q_INVOKABLE void refreshNetworkPulseHistory(int window_blocks = 120);
    Q_INVOKABLE void startExplorerIndexing();
    Q_INVOKABLE void stopExplorerIndexing();
    Q_INVOKABLE void resetExplorerIndex();
    Q_INVOKABLE void startExplorerTop100Timeline(int start_height, int end_height);
    Q_INVOKABLE void setExplorerTop100FocusedIndexing(bool enabled);
    Q_INVOKABLE void stopExplorerTop100Timeline();
    Q_INVOKABLE void resetExplorerTop100Timeline();
    Q_INVOKABLE void scanRemainingExplorerTop100Timeline();
    Q_INVOKABLE QVariantMap explorerTop100Snapshot(int height) const;
    Q_INVOKABLE void createExplorerContactSet(const QString& name);
    Q_INVOKABLE void saveExplorerContactSet(const QString& name);
    Q_INVOKABLE void loadExplorerContactSet(const QString& name);
    Q_INVOKABLE void renameExplorerContactSet(const QString& old_name, const QString& new_name);
    Q_INVOKABLE void deleteExplorerContactSet(const QString& name);
    Q_INVOKABLE void saveExplorerContact(const QString& username, const QString& addresses, int edit_index = -1);
    Q_INVOKABLE void deleteExplorerContact(int index);
    Q_INVOKABLE void refreshExplorerContactRelationships();
    Q_INVOKABLE void loadExplorerContactRows(const QString& name, const QVariantList& rows);
    Q_INVOKABLE void importCoindroidsGameContacts();
    Q_INVOKABLE void loadCoindroidsContactSet(const QString& key);
    Q_INVOKABLE void openCoindroidsReportPdf();
    Q_INVOKABLE void refreshForensicsIrregularMessages();
    Q_INVOKABLE void startForensicsIrregularMessages(int start_height);
    Q_INVOKABLE void stopForensicsScan();
    Q_INVOKABLE void resumeForensicsScan();
    Q_INVOKABLE void exportForensicsIrregularMessagesCsv();
    Q_INVOKABLE void checkForUpdates(bool manual);
    Q_INVOKABLE void downloadPendingUpdate();
    Q_INVOKABLE void installDownloadedUpdate();
    Q_INVOKABLE QString generateRecoveryPhrase();
    Q_INVOKABLE QVariantMap validateRecoveryPhrase(const QString& phrase) const;
    Q_INVOKABLE void previewRecoveryPhraseAddresses(const QString& phrase,
                                                    const QString& derivation_path,
                                                    const QString& wif_mode,
                                                    int count);
    Q_INVOKABLE void createWalletWithRecoveryPhrase(const QString& wallet_name,
                                                    const QString& phrase,
                                                    bool encrypt = false,
                                                    const QString& passphrase = QString());
    Q_INVOKABLE void restoreWalletFromRecoveryPhrase(const QString& wallet_name,
                                                     const QString& phrase,
                                                     const QString& mode,
                                                     const QString& derivation_path,
                                                     const QString& wif_mode,
                                                     int range,
                                                     bool encrypt = false,
                                                     const QString& passphrase = QString());
    Q_INVOKABLE void cancelRecovery();
    Q_INVOKABLE QVariantMap convertCompatibilityEncoding(const QString& text) const;
    Q_INVOKABLE void chooseMinerExecutable();
    Q_INVOKABLE void useWalletReceiveAddressForMining();
    Q_INVOKABLE void saveMinerConfiguration(
        const QString& pool_url, const QString& payout_address, const QString& password, int threads, int nice_level);
    Q_INVOKABLE void startConfiguredMiner();
    Q_INVOKABLE void stopMiner();
    Q_INVOKABLE void clearMinerLog();

public Q_SLOTS:
    void setOnlyDefcoinUserAgents(bool enabled);
    void setOnlyDefcoinMagicBytes(bool enabled);
    void setSwitchToDefcoinOnlyMagicStartingJuly2026(bool enabled);
    void setDisallowLanNodeDiscovery(bool enabled);
    void setLanNodeDiscoveryEnabled(bool enabled);
    void setLanFastSyncEnabled(bool enabled);
    void setLanQuickCloneEnabled(bool enabled);
    void setQuickCloneAutoValidateAfter(bool enabled);
    void setAdvancedToolsVisible(bool enabled);
    void setUpnpConnectionsEnabled(bool enabled);
    void setAutomaticUpdateChecksEnabled(bool enabled);
    void setTableCopyDelimiterStyle(const QString& style);
    void setTableCopyCustomDelimiter(const QString& delimiter);
    void setLogVerbosity(int verbosity);
    void setLogSearchPattern(const QString& pattern);
    void setLogRemovePattern(const QString& pattern);
    void setForensicsAcceptBip141AsRegular(bool enabled);
    void setBackgroundCloseEnabled(bool enabled);
    void setMaskBalances(bool enabled);
    void setThirdPartyTxUrlsEnabled(bool enabled);
    void setThirdPartyTxUrl(const QString& url);
    void setExplorerMode(const QString& mode);

Q_SIGNALS:
    void stateChanged();
    void walletChanged();
    void peersChanged();
    void trafficChanged();
    void settingsChanged();
    void logChanged();
    void consoleChanged();
    void feeEstimateChanged();
    void psbtChanged();
    void tableSettingsChanged();
    void updateStatusChanged();
    void userMessage(const QString& title, const QString& message);
    void quickClonePromptRequested(const QString& title, const QString& message);
    void transactionDetailsReady(const QString& title, const QString& html);
    void explorerWindowRequested(const QString& title, const QString& html);
    void explorerChanged();
    void forensicsChanged();
    void updateAvailable(const QString& version, const QString& message);
    void updateDownloaded(const QString& version, const QString& filePath, const QString& message);
    void recoveryPhrasePreviewReady(const QVariantMap& preview, const QString& message);
    void recoveryChanged();
    void minerChanged();

private:
    using RpcCallback = std::function<void(const QJsonValue&, const QString&)>;
    using RpcBatchCallback = std::function<void(const QVector<QJsonValue>&, const QStringList&, const QString&)>;

    struct PendingCall {
        QString method;
        RpcCallback callback;
    };

    struct PendingUpdate {
        QString version;
        QString tag;
        QString releaseUrl;
        QString assetName;
        QString assetUrl;
        QString checksumUrl;
        QString filePath;
        qint64 assetSize = 0;
        bool velopackManaged = false;
    };

    void loadLocalSettings();
    bool loadRpcSettings();
    QString defaultDataDir() const;
    void readDefcoinConf(const QString& conf_path);
    bool readCookie();
    QString backendBinaryPath() const;
    QString debugLogPath() const;
    bool ensureBackendStarted();
    void stopHelperProcesses();
    void stopOwnedBackend();
    void appendLaunchDiagnostic(const QString& message);
    int appendDebugLogLineFromNu(const QString& message);
    void beginBackendDebugLogSection(bool write_to_debug_log);
    void appendLogLine(const QString& line, int debug_log_line_number = 0);
    void trimLogLines();
    QStringList backendRuntimeDiagnostics(const QString& binary) const;
    bool walletAutoloadEntryExists(const QString& wallet_name) const;
    void pruneCoreWalletAutoloadSettings(const QStringList& force_remove = {});
    bool shouldAutostartAfterTransportError(QNetworkReply* reply) const;
    void rpcCall(const QString& method, const QJsonArray& params, bool wallet_scoped, RpcCallback callback);
    void rpcCallForWallet(const QString& method,
                          const QJsonArray& params,
                          const QString& wallet_name,
                          RpcCallback callback);
    void rpcBatchCall(const QVector<QPair<QString, QJsonArray>>& calls, bool wallet_scoped, RpcBatchCallback callback);
    void rpcBatchCallAsSingles(const QVector<QPair<QString, QJsonArray>>& calls,
                               bool wallet_scoped,
                               RpcBatchCallback callback);
    void handleReply(QNetworkReply* reply);
    QUrl rpcUrl(bool wallet_scoped) const;
    QUrl rpcUrlForWallet(const QString& wallet_name) const;
    QString walletRpcNameFor(const QString& wallet_name) const;
    QString walletLoadNameFor(const QString& wallet_name) const;
    void setError(const QString& message);
    void clearError();
    bool setCurrentWalletInternal(const QString& name, bool selected = true);
    void clearWalletScopedState();
    bool ensureCurrentWalletSelected(const QString& title);

    void refreshNode();
    void refreshBannedPeerRows();
    void refreshWallet();
    void refreshAddressBook();
    void refreshWalletList();
    void updateWalletStatsEntry(const QString& wallet_name, const QVariantMap& updates);
    void refreshFeeEstimate();
    void schedulePeerNameLookups(const QString& host);
    void scheduleLanPeerNameLookups(const QString& host);
    void scheduleConfiguredSeedAliasLookups();
    void sampleTraffic();
    void ensureLanFastSyncSocket();
    void stopLanFastSyncSocket();
    void handleLanFastSyncDatagrams();
    void sendLanDiscoveryAnnouncement();
    void handleLanDiscoveryAnnouncement(const QJsonObject& message, const QHostAddress& sender, quint16 sender_port);
    void queueLanDiscoveryAddNode(const QString& host, quint16 p2p_port);
    void processQueuedLanDiscoveryAddNodes();
    bool isLocalInterfaceAddress(const QHostAddress& address) const;
    void lanFastSyncTick();
    void requestLanFastSyncBlock();
    QString selectUdpFastSyncTargetHost(int* node_id) const;
    bool isPrivateLocalOrProvenUdpFastSyncTarget(const QString& host) const;
    bool isUdpFastSyncProbeAllowed(const QString& host, qint64 now) const;
    bool isUdpFastSyncHostVerified(const QString& host) const;
    void setUdpFastSyncPeerTransportVerified(const QString& host, bool verified);
    void clearUdpFastSyncTransportVerification(const QString& host);
    void recordUdpFastSyncPeerReply(const QString& host);
    void recordUdpFastSyncPeerMiss(const QString& host, const QString& reason = QString());
    void acknowledgeLanQuickCloneSourceOffline(const QString& host, int height, const QString& reason);
    bool sendUdpFastSyncProbe(const QString& host, int node_id);
    void lanQuickCloneTick();
    void evaluateQuickClonePrompt();
    bool quickCloneMissingChainThresholdReached() const;
    bool hasQuickCloneLanCandidate() const;
    QString quickClonePromptText() const;
    QString selectLanQuickCloneTargetHost(int* node_id, int* peer_tip) const;
    QString selectLanQuickCloneProbeHost(int* node_id) const;
    void sendLanFastSyncBlockRequest(int height, const QString& host, int node_id, const QString& expected_hash);
    void releaseLanFastSyncReservation();
    void releaseLanFastSyncReservationFor(int node_id, const QString& hash);
    void releaseAllLanFastSyncReservations();
    void expireLanFastSyncTransfers(qint64 now);
    void submitNextLanFastSyncReadyBlock();
    void refreshLanFastSyncCurrentTargetHosts();
    void updateLanFastSyncRequestState();
    bool canStartMoreLanFastSyncTransfers() const;
    bool hasLanFastSyncPendingHeight(int height) const;
    int nextLanFastSyncWantedHeight() const;
    qint64 lanFastSyncBufferedBytes() const;
    int lanFastSyncLocalInflightCount(const QString& host) const;
    void handleLanFastSyncProbe(const QJsonObject& header, const QHostAddress& sender, quint16 sender_port);
    void handleLanFastSyncProbeAck(const QJsonObject& header, const QHostAddress& sender, quint16 sender_port);
    void handleLanFastSyncRequest(const QJsonObject& header, const QHostAddress& sender, quint16 sender_port);
    void handleLanFastSyncChunk(const QJsonObject& header, const QByteArray& payload, const QHostAddress& sender);
    void resetLanFastSyncTransfer(const QString& status);
    bool isUdpFastSyncAllowedPeer(const QHostAddress& address) const;
    bool isLanQuickCloneAllowedPeer(const QHostAddress& address) const;
    bool hasPrivateUdpFastSyncTarget() const;
    int currentFastSyncDatagramSize() const;
    int currentFastSyncChunkSize() const;
    void tuneFastSyncDatagramAfterSuccess();
    void tuneFastSyncDatagramAfterFailure();
    QString lanFastSyncMethodSummary() const;
    QString lanFastSyncRateSummary() const;
    QString syncTransportSpeedSummary() const;
    QString coreSyncPathSummary() const;
    QString fastSyncUdpSummary() const;
    QString fastSyncUdpDetailSummary() const;
    QString quickCloneTrafficSummary() const;
    QString syncTransportDecisionSummary() const;
    QString syncTransportProbeSummary() const;
    QString syncBenchmarkSummary() const;
    void updateSyncBenchmarkState(bool syncing, int headers, int blocks_behind, double progress);
    QString coreSchedulingWaitStatus(const QString& feature, const QString& reason) const;
    void recordLanFastSyncUdpTraffic(qint64 sent_bytes, qint64 received_bytes, bool quick_clone = false);
    QString udpFastSyncEndpointText(const QHostAddress& address, quint16 port = 0) const;
    void recordFastSyncUdpDiagnostic(const QString& reason, const QString& detail = QString());
    enum class FastSyncTransport { TcpCore, UdpFastSync };
    enum class FastSyncUdpFailureKind { ProbeSend, RequestSend, RequestTimeout, Checksum, Buffer, Submit };
    void recordFastSyncTransportSuccess(FastSyncTransport transport, int blocks, int height, double seconds);
    void recordFastSyncTransportFailure(FastSyncTransport transport);
    void recordFastSyncUdpSuccess(int height, qint64 latency_ms);
    void recordFastSyncUdpFailure(FastSyncUdpFailureKind kind);
    void recordCoreSyncPathProgress(int blocks, double seconds);
    bool shouldAttemptUdpFastSync();
    void resetFastSyncProtocolWindow();
    void probeBackendCapabilities();
    void refreshDebugLog();
    void updateReceiveQr();
    QString receiveRequestSettingsKey() const;
    QVariantMap receiveRequestMeta(const QString& address,
                                   const QString& label,
                                   const QString& amount,
                                   const QString& message,
                                   const QString& uri,
                                   const QString& date,
                                   qint64 created_ms) const;
    QVariantMap receiveRequestRow(const QVariantMap& meta) const;
    void loadReceiveRequests();
    void saveReceiveRequests() const;
    QString defcoinUri(const QString& address,
                       const QString& amount,
                       const QString& label,
                       const QString& message) const;
    QString qrSourceForUri(const QString& uri) const;
    QString normalizedExplorerUrl(const QString& url) const;
    QString explorerAddressUrlTemplate(const QString& url) const;
    bool usingInternalExplorer() const;
    bool ensureExplorerDatabase(QString* error = nullptr) const;
    bool ensureExplorerBalanceDeltas(QString* error = nullptr);
    bool acquireExplorerWriterLock(QString* error = nullptr);
    void releaseExplorerWriterLock();
    void cacheExplorerLookup(const QString& type,
                             const QString& id,
                             const QString& title,
                             const QString& summary,
                             const QJsonValue& raw_json);
    void loadExplorerRecentLookups();
    int explorerHighestIndexedBlock() const;
    qint64 explorerMetaInteger(const QString& key, qint64 fallback = -1) const;
    int explorerIndexedBlockCountFromDb() const;
    int explorerIndexedOutputCountFromDb() const;
    QVariantList explorerRichListFromDb(QString* error = nullptr) const;
    QVariantList explorerMovementsFromDb(qint64 threshold_sats, QString* error = nullptr) const;
    QString droidTrailsDatabasePath() const;
    bool ensureDroidTrailsDatabase(QString* error = nullptr) const;
    QVariantMap coindroidsAnalyticsFromCache(QString* error = nullptr) const;
    void saveCoindroidsAnalyticsCache(const QVariantMap& analysis, QString* error = nullptr) const;
    QVariantMap coindroidsAnalyticsFromDb(QString* error = nullptr) const;
    void loadDefcoinTimeline();
    QVariantMap networkPulseHistoryFromDb(int window_blocks, QString* error = nullptr) const;
    void refreshRecentAverageBlockTimeFromRpc(int tip_height);
    void refreshRecentAverageBlockTimeFromIndex();
    void loadExplorerContacts();
    void persistExplorerContacts();
    void persistExplorerContactSets();
    QString coindroidsContactSetName(const QString& key) const;
    QVariantList coindroidsContactsForSetKey(const QString& key) const;
    void ensureCoindroidsPrebuiltContactSets(bool emit_signal);
    QVariantList explorerContactsFromJsonArray(const QJsonArray& raw_contacts) const;
    QJsonArray explorerContactsToJsonArray(const QVariantList& contacts) const;
    QVariantMap explorerContactSetRow(const QString& name, const QVariantList& contacts, qint64 updated_at) const;
    int explorerContactSetIndex(const QString& name) const;
    void upsertExplorerContactSet(const QString& name, const QVariantList& contacts, qint64 updated_at);
    void refreshExplorerTop100TimelineStats();
    QString explorerBlockHashAtHeight(int height) const;
    QString explorerBlockHashForTransaction(const QString& txid) const;
    QString explorerCachedBlockHtml(const QString& block_id,
                                    QJsonObject* raw_json = nullptr,
                                    bool* found = nullptr) const;
    QString explorerIndexedTransactionHtml(const QString& txid,
                                           QJsonObject* raw_json = nullptr,
                                           bool* found = nullptr) const;
    QString explorerIndexedAddressHtml(const QString& address, bool* found = nullptr) const;
    bool explorerPruneFromHeight(int height, QString* error = nullptr);
    bool storeExplorerBlock(const QJsonObject& block, QString* error = nullptr);
    bool storeExplorerBlocks(const QVector<QJsonObject>& blocks,
                             int* output_rows_written = nullptr,
                             QString* error = nullptr);
    void emitExplorerChangedThrottled(bool force = false);
    void scheduleExplorerIndexStep(int delay_ms = 0);
    void explorerIndexStep();
    void scheduleExplorerTop100Step(int delay_ms = 0);
    void explorerTop100Step();
    bool initializeExplorerTop100Scan(int start_height, int end_height, QString* error = nullptr);
    struct ExplorerTop100EventRow {
        int rank = 0;
        QString address;
        int percent = 0;
        int color_index = 0;
    };
    struct ExplorerTop100EventWrite {
        int height = 0;
        qint64 time = 0;
        bool is_anchor = false;
        QVector<ExplorerTop100EventRow> rows;
    };
    bool prepareExplorerTop100EventWrite(
        int height, qint64 block_time, bool force_anchor, ExplorerTop100EventWrite* event, QString* error = nullptr);
    bool writeExplorerTop100EventBatch(const QVector<ExplorerTop100EventWrite>& events, QString* error = nullptr);
    bool writeExplorerTop100Events(int height, qint64 block_time, bool force_anchor, QString* error = nullptr);
    bool finishExplorerTop100Scan(bool completed, QString* error = nullptr);
    void scheduleForensicsScanStep(int delay_ms = 0);
    void forensicsScanStep();
    void rebuildForensicsScanSummary();
    void resetForensicsPrefixCompression();
    void finalizeForensicsPrefixCompression(QVariantList& rows);
    bool appendForensicsDisplayRow(QVariantList& rows, const QVariantMap& display_row);
    QString explorerLookupHtml(const QString& title, const QString& summary_html, const QJsonValue& raw_json) const;
    void emitExplorerError(const QString& title, const QString& detail);
    void rebuildNodeMetrics();
    QString helpManualPath(const QString& page) const;
    void loadPsbtPayload(const QByteArray& payload, const QString& source);
    void analyzeCurrentPsbt(const QString& source);
    void handleUpdateReleaseReply(QNetworkReply* reply);
    void handleUpdateAssetReply(QNetworkReply* reply);
    void handleUpdateChecksumReply(QNetworkReply* reply);
    void setUpdateStatus(const QString& status, int progress = -1);
    void clearPendingUpdateDownload();
    bool verifyDownloadedUpdate(const QByteArray& checksum_file, QString& error);
    void continueWalletOpenQueue();
    void appendMinerLog(const QString& line);
    void parseMinerLogChunk(const QString& text);
    void resetMinerRuntimeStats();
    void setRecoveryState(bool active, const QString& status, int progress = -1);
    void setRecoveryCurrentMethod(const QString& method);
    void updateRecoveryTiming(int completed_work = -1, int estimated_total_work = -1);
    void scheduleRecoveryScanPoll();
    void importRecoveryDescriptorsWithRescan(const QVector<QPair<QString, QString>>& descriptors, int range);
    void importRecoveryDescriptorsUntilEmpty(const QVector<QPair<QString, QString>>& descriptors, int empty_gap);
    void summarizeCompletedRecoveryImport(int import_range, const QStringList& tried_methods = {});
    void lockRecoveryWalletIfNeeded();
    QString currentNuVersion() const;
    QString selectedUpdateAssetNeedle() const;
    QString updateDownloadDirectory() const;
    QString nuResourceRoot() const;
    QStringList loadBip39Words() const;
    bool validateMnemonic(const QString& phrase, QString* normalized = nullptr, QString* error = nullptr) const;
    bool looksLikeRecoveryPhraseText(const QString& text) const;
    bool requireLocalRecoveryRpc(const QString& operation);
    bool mnemonicMaterial(
        const QString& phrase, const QString& wif_mode, QString* wif, QString* xprv, QString* error) const;
    QString descriptorForRecoveryPath(const QString& xprv, const QString& derivation_path, QString* error) const;
    static QString normalizedVersionString(QString version);
    static bool isVersionNewer(const QString& candidate, const QString& current);

    static QString formatAmount(const QJsonValue& value);
    static QString formatBytes(qint64 bytes);
    static QString formatPing(const QJsonValue& seconds);
    static QString formatServices(const QString& services_hex);
    static QString formatServiceDetails(const QString& services_hex);
    static QString trimUserAgent(QString subver);
    static bool isDefcoinUserAgent(QString subver);
    static bool isDefcoinCoreNuUserAgent(QString subver);

    QNetworkAccessManager* m_network = nullptr;
    QNetworkAccessManager* m_update_network = nullptr;
    QTimer* m_refresh_timer = nullptr;
    QTimer* m_traffic_timer = nullptr;
    QElapsedTimer m_uptime;
    QDateTime m_app_launch_utc;
    QHash<int, PendingCall> m_pending;
    int m_next_id = 1;

    QString m_data_dir;
    QString m_rpc_host = QStringLiteral("127.0.0.1");
    int m_rpc_port = 9332;
    QString m_rpc_user;
    QString m_rpc_password;
    QString m_wallet_name;
    bool m_wallet_selected = false;
    int m_wallet_refresh_generation = 0;
    QStringList m_available_wallets;
    QStringList m_loaded_wallets;
    QHash<QString, QString> m_wallet_rpc_name_by_canonical;
    QStringList m_wallet_open_queue;
    bool m_wallet_open_queue_active = false;
    QString m_wallet_open_queue_final_wallet;
    int m_wallet_address_count = 0;
    int m_wallet_nonzero_address_count = 0;
    QVariantList m_wallet_file_stats;
    bool m_backend_start_attempted = false;
    bool m_backend_started_by_nu = false;
    qint64 m_backend_pid = 0;
    QProcess* m_backend_process = nullptr;
    QProcess* m_miner_process = nullptr;
    QString m_miner_executable;
    QString m_miner_pool_url = QStringLiteral("stratum+tcp://defcoin.dc903.org:13372");
    QString m_miner_payout_address;
    QString m_miner_password = QStringLiteral("x");
    int m_miner_threads = 4;
    int m_miner_nice_level = 20;
    QString m_miner_status = QStringLiteral("Miner not configured.");
    QString m_miner_log;
    QString m_miner_parse_buffer;
    QString m_miner_hashrate_text = QStringLiteral("-");
    int m_miner_accepted_shares = 0;
    int m_miner_rejected_shares = 0;
    bool m_have_pending_network_active = false;
    bool m_pending_network_active = true;
    bool m_applying_pending_network_active = false;
    bool m_only_defcoin_magic_bytes = false;
    bool m_switch_to_defcoin_only_magic_starting_july_2026 = true;
    bool m_lan_node_discovery_enabled = false;
    bool m_upnp_connections_enabled = false;
    bool m_lan_node_discovery_notice_acknowledged = false;
    bool m_automatic_update_checks_enabled = true;
    QString m_table_copy_delimiter_style = QStringLiteral("tsv");
    QString m_table_copy_custom_delimiter = QStringLiteral("|");
    int m_log_verbosity = 0;
    QString m_log_search_pattern;
    QString m_log_last_search_pattern;
    QString m_log_remove_pattern;
    bool m_background_close_enabled = false;
    bool m_update_check_in_progress = false;
    bool m_update_download_in_progress = false;
    bool m_rpc_ready_logged = false;
    int m_update_download_progress = 0;
    QString m_update_status;
    bool m_recovery_active = false;
    bool m_recovery_finished = false;
    bool m_recovery_cancel_requested = false;
    bool m_recovery_cancelable = false;
    bool m_recovery_poll_scheduled = false;
    QString m_recovery_status;
    int m_recovery_progress = 0;
    QString m_recovery_found_amount;
    int m_recovery_found_address_count = 0;
    QString m_recovery_recent_found_address;
    QString m_recovery_detected_method;
    QString m_recovery_current_method;
    QString m_recovery_elapsed = QStringLiteral("Not running");
    QString m_recovery_eta = QStringLiteral("Unknown");
    bool m_recovery_lock_after_restore = false;
    QElapsedTimer m_recovery_timer;
    PendingUpdate m_pending_update;
    QFile* m_update_download_file = nullptr;
    NuVelopackUpdater* m_velopack_updater = nullptr;

    bool m_rpc_connected = false;
    QString m_connection_status = QStringLiteral("RPC not connected");
    QString m_last_error;
    QString m_network_state = QStringLiteral("isolated");
    int m_peer_count = 0;
    int m_block_height = 0;
    int m_header_height = 0;
    bool m_syncing = false;
    QString m_sync_state = QStringLiteral("Unknown");
    QString m_sync_detail = QStringLiteral("Waiting for backend status.");
    QString m_sync_eta = QStringLiteral("Unknown");
    int m_sync_progress_percent = 0;
    double m_sync_last_progress = -1.0;
    double m_sync_average_blocks_per_second = 0.0;
    int m_sync_last_block_height = -1;
    qint64 m_sync_last_sample_ms = 0;
    bool m_sync_benchmark_active = false;
    qint64 m_sync_benchmark_started_ms = 0;
    qint64 m_sync_benchmark_completed_elapsed_ms = 0;
    int m_sync_benchmark_start_block = -1;
    int m_sync_benchmark_start_headers = -1;
    int m_sync_benchmark_final_block = -1;
    int m_sync_benchmark_final_headers = -1;
    bool m_wallet_locked = true;
    bool m_wallet_encrypted = false;
    QString m_metric_network_active = QStringLiteral("Hydrating");
    QString m_metric_connections = QStringLiteral("0");
    QString m_metric_inbound = QStringLiteral("0");
    QString m_metric_outbound = QStringLiteral("0");
    QString m_metric_version = QStringLiteral("Unknown");
    QString m_metric_blocks = QStringLiteral("Unknown");
    QString m_metric_headers = QStringLiteral("Unknown");
    QString m_metric_verification = QStringLiteral("Unknown");
    QString m_metric_difficulty = QStringLiteral("Unknown");
    QString m_metric_network_hashrate = QStringLiteral("Unknown");
    QString m_metric_average_block_time = QStringLiteral("Unknown");
    QString m_metric_chain_tips = QStringLiteral("Unknown");
    QString m_metric_peer_messages_sent = QStringLiteral("Unknown");
    QString m_metric_peer_messages_received = QStringLiteral("Unknown");
    QString m_metric_traffic = QStringLiteral("0 B received / 0 B sent");
    QString m_total_balance = QStringLiteral("0.00000000 DFC");
    QString m_available_balance = QStringLiteral("0.00000000");
    QString m_pending_balance = QStringLiteral("0.00000000");
    QString m_immature_balance = QStringLiteral("0.00000000");
    int m_wallet_transaction_count = 0;
    QString m_receive_address;
    QString m_receive_qr_source;
    QString m_receive_label;
    QString m_receive_amount;
    QString m_receive_message;
    QString m_loaded_receive_request_settings_key;
    bool m_seed_alias_lookups_started = false;
    QHash<QString, QString> m_peer_dns_name_by_host;
    QHash<QString, QString> m_peer_domain_alias_by_host;
    QHash<QString, int> m_peer_domain_alias_priority_by_host;
    QHash<QString, QString> m_peer_lan_name_by_host;
    QHash<QString, QString> m_peer_lan_info_by_host;
    QSet<QProcess*> m_helper_processes;
    bool m_stopping_helper_processes = false;
    QSet<int> m_host_lookup_ids;
    QSet<QString> m_peer_reverse_lookup_pending;
    QSet<QString> m_peer_reverse_lookup_attempted;
    QSet<QString> m_peer_lan_lookup_pending;
    QSet<QString> m_peer_lan_lookup_attempted;
    QHash<QString, qint64> m_peer_lan_lookup_last_attempt_ms;
    QString m_lan_discovery_node_id;
    qint64 m_lan_discovery_last_announce_ms = 0;
    qint64 m_lan_discovery_last_addnode_attempt_ms = 0;
    QSet<QString> m_lan_discovery_added_endpoints;
    QSet<QString> m_lan_discovery_addnode_pending;
    QSet<QString> m_lan_discovery_addnode_inflight;
    struct LanFastSyncTransfer {
        QString request_id;
        QString host;
        QString expected_hash;
        QString block_hash;
        QString block_checksum;
        QHash<int, QByteArray> chunks;
        int node_id = -1;
        int height = -1;
        int expected_chunks = 0;
        int expected_size = 0;
        int assembled_bytes = 0;
        qint64 request_ms = 0;
        bool clone_mode = false;
    };
    struct LanFastSyncReadyBlock {
        QByteArray block;
        QString host;
        QString hash;
        int node_id = -1;
        int height = -1;
        qint64 request_ms = 0;
    };
    QSet<QString> m_lan_quick_clone_candidate_hosts;
    QSet<QString> m_quick_clone_snapshot_candidate_hosts;
    QSet<QString> m_udp_fast_sync_peer_hosts;
    QSet<QString> m_udp_fast_sync_attempted_peer_hosts;
    QSet<QString> m_udp_fast_sync_available_peer_hosts;
    QSet<QString> m_udp_fast_sync_failed_peer_hosts;
    QSet<QString> m_udp_fast_sync_used_peer_hosts;
    QSet<QString> m_udp_fast_sync_block_attempted_peer_hosts;
    QSet<QString> m_udp_fast_sync_block_success_peer_hosts;
    QSet<QString> m_udp_fast_sync_block_failed_peer_hosts;
    QSet<QString> m_udp_fast_sync_block_served_peer_hosts;
    QSet<QString> m_udp_fast_sync_current_target_hosts;
    QHash<QString, qint64> m_udp_fast_sync_last_request_ms_by_host;
    QHash<QString, qint64> m_udp_fast_sync_last_probe_ms_by_host;
    QHash<QString, QString> m_udp_fast_sync_probe_ids_by_host;
    QHash<QString, QString> m_udp_fast_sync_probe_hosts_by_id;
    QHash<QString, int> m_udp_fast_sync_probe_failures_by_host;
    QHash<QString, int> m_udp_fast_sync_failure_reason_counts;
    QHash<QString, qint64> m_udp_fast_sync_last_diagnostic_ms_by_reason;
    QHash<QString, int> m_udp_fast_sync_suppressed_diagnostic_count_by_reason;
    QHash<QString, int> m_udp_fast_sync_peer_node_ids_by_host;
    QHash<QString, int> m_udp_fast_sync_peer_tips_by_host;
    QHash<QString, int> m_udp_fast_sync_peer_inflight_counts_by_host;
    QSet<int> m_udp_fast_sync_core_verified_node_ids;
    int m_address_book_refresh_generation = 0;
    QVariantList m_address_book;
    QVariantList m_receive_requests;
    QVariantList m_recent_transactions;
    QVariantList m_peers;
    QVariantList m_peer_rows_simple;
    QVariantList m_peer_rows_detailed;
    QVariantList m_banned_peer_rows;
    QHash<int, QString> m_peer_host_by_node_id;
    QHash<int, QString> m_peer_addr_by_node_id;
    QHash<int, bool> m_peer_inbound_by_node_id;
    QVariantList m_node_metrics;
    QVariantList m_traffic_samples;
    qint64 m_last_traffic_ms = 0;
    qint64 m_last_bytes_recv = -1;
    qint64 m_last_bytes_sent = -1;
    qint64 m_last_udp_bytes_recv = -1;
    qint64 m_last_udp_bytes_sent = -1;
    qint64 m_last_quick_clone_bytes_recv = -1;
    qint64 m_last_quick_clone_bytes_sent = -1;
    QString m_traffic_received_total = QStringLiteral("0 B");
    QString m_traffic_sent_total = QStringLiteral("0 B");
    QString m_traffic_tcp_received_total = QStringLiteral("0 B");
    QString m_traffic_tcp_sent_total = QStringLiteral("0 B");
    QString m_traffic_udp_received_total = QStringLiteral("0 B");
    QString m_traffic_udp_sent_total = QStringLiteral("0 B");
    QString m_traffic_quick_clone_received_total = QStringLiteral("0 B");
    QString m_traffic_quick_clone_sent_total = QStringLiteral("0 B");
    double m_quick_clone_received_rate_bytes_per_second = 0.0;
    double m_quick_clone_sent_rate_bytes_per_second = 0.0;
    qint64 m_sync_tcp_bytes_received = 0;
    qint64 m_sync_tcp_bytes_sent = 0;
    double m_sync_tcp_active_seconds = 0.0;
    qint64 m_last_core_header_message_bytes = -1;
    qint64 m_last_core_block_message_bytes = -1;
    qint64 m_last_core_block_received_message_bytes = -1;
    qint64 m_last_core_message_sample_ms = 0;
    qint64 m_sync_core_header_bytes = 0;
    qint64 m_sync_core_block_bytes = 0;
    qint64 m_sync_core_block_bytes_received = 0;
    double m_sync_core_header_active_seconds = 0.0;
    double m_sync_core_block_active_seconds = 0.0;
    QStringList m_log_lines;
    QVariantList m_log_line_numbers;
    QString m_last_logged_error_message;
    QString m_debug_log_path;
    qint64 m_debug_log_offset = -1;
    int m_debug_log_next_line_number = 1;
    QString m_debug_log_append_path;
    qint64 m_debug_log_append_size_hint = -1;
    int m_debug_log_append_line_hint = 0;
    bool m_debug_log_collecting_continuation = false;
    bool m_launch_diagnostics_section_started = false;
    bool m_backend_log_section_started = false;
    qint64 m_chain_progress_last_diagnostic_ms = 0;
    int m_chain_progress_last_diagnostic_headers = -1;
    int m_chain_progress_last_diagnostic_blocks = -1;
    QString m_console_output = QStringLiteral(
        "Welcome to the Defcoin Core Nu RPC console.\nUse the command line below for standard Core commands, for "
        "example getblockchaininfo or listtransactions \"*\" 5.\nJSON parameter arrays are still accepted after the "
        "method name when needed.\n\nWARNING: Do not paste commands from strangers into this console.");
    QString m_paper_wallet_address;
    QString m_paper_wallet_wif;
    QString m_paper_wallet_status = QStringLiteral("No paper wallet generated in this session.");
    bool m_fee_estimate_available = false;
    QString m_fee_estimate_status = QStringLiteral("Fee estimate hydrates after RPC connects.");
    QString m_current_psbt;
    QString m_current_psbt_summary = QStringLiteral("No PSBT loaded.");
    QString m_current_psbt_final_hex;
    bool m_only_defcoin_user_agents = true;
    bool m_advanced_tools_visible = false;
    bool m_lan_fast_sync_enabled = true;
    bool m_lan_quick_clone_enabled = false;
    bool m_debug_disable_core_tcp_sync = false;
    bool m_debug_disable_core_sync = false;
    bool m_debug_disable_fast_sync = false;
    bool m_debug_disable_quick_clone = false;
    bool m_debug_fast_sync_lan_only = false;
    bool m_quick_clone_auto_validate_after = false;
    bool m_quick_clone_validation_running = false;
    bool m_quick_clone_missing_cycle_active = false;
    bool m_quick_clone_prompt_declined_for_cycle = false;
    bool m_quick_clone_prompt_shown_for_cycle = false;
    bool m_quick_clone_auto_validate_ran_this_session = false;
    QString m_quick_clone_validation_status = QStringLiteral("Blockchain validation idle.");
    bool m_lan_quick_clone_paused_network = false;
    QUdpSocket* m_lan_fast_sync_socket = nullptr;
    QTimer* m_lan_fast_sync_timer = nullptr;
    QString m_lan_fast_sync_status = QStringLiteral("UDP fast sync idle.");
    QString m_lan_quick_clone_status = QStringLiteral("Quick Clone off.");
    QString m_lan_fast_sync_request_id;
    QString m_lan_fast_sync_current_host;
    QString m_lan_fast_sync_block_hash;
    QString m_lan_fast_sync_block_checksum;
    QHash<int, QByteArray> m_lan_fast_sync_chunks;
    int m_lan_fast_sync_assembled_bytes = 0;
    int m_lan_fast_sync_current_height = -1;
    int m_lan_fast_sync_expected_chunks = 0;
    int m_lan_fast_sync_expected_size = 0;
    int m_lan_fast_sync_retransmit_errors = 0;
    int m_lan_fast_sync_blocks_received = 0;
    qint64 m_lan_fast_sync_bytes_received = 0;
    qint64 m_lan_fast_sync_udp_bytes_received = 0;
    qint64 m_lan_fast_sync_udp_bytes_sent = 0;
    qint64 m_lan_fast_sync_udp_packets_received = 0;
    qint64 m_lan_fast_sync_udp_packets_sent = 0;
    qint64 m_lan_fast_sync_udp_first_activity_ms = 0;
    qint64 m_lan_fast_sync_udp_last_activity_ms = 0;
    qint64 m_lan_quick_clone_udp_bytes_received = 0;
    qint64 m_lan_quick_clone_udp_bytes_sent = 0;
    qint64 m_lan_quick_clone_udp_packets_received = 0;
    qint64 m_lan_quick_clone_udp_packets_sent = 0;
    qint64 m_lan_quick_clone_udp_first_activity_ms = 0;
    qint64 m_lan_quick_clone_udp_last_activity_ms = 0;
    qint64 m_lan_fast_sync_started_ms = 0;
    qint64 m_lan_fast_sync_request_ms = 0;
    qint64 m_lan_fast_sync_last_progress_ms = 0;
    QString m_lan_fast_sync_last_failure_detail;
    int m_lan_fast_sync_reserved_node_id = -1;
    QString m_lan_fast_sync_reserved_hash;
    bool m_lan_fast_sync_request_in_flight = false;
    bool m_lan_fast_sync_reserve_in_flight = false;
    bool m_lan_fast_sync_submit_in_flight = false;
    int m_lan_fast_sync_submitting_height = -1;
    QSet<int> m_lan_fast_sync_counted_heights;
    QHash<QString, LanFastSyncTransfer> m_lan_fast_sync_transfers_by_id;
    QHash<int, LanFastSyncReadyBlock> m_lan_fast_sync_ready_blocks_by_height;
    qint64 m_lan_quick_clone_reservation_backoff_until_ms = 0;
    qint64 m_lan_quick_clone_last_reservation_status_ms = 0;
    QString m_lan_quick_clone_last_reservation_reason;
    int m_fast_sync_tcp_successes = 0;
    int m_fast_sync_udp_successes = 0;
    int m_fast_sync_tcp_failures = 0;
    int m_fast_sync_udp_failures = 0;
    int m_fast_sync_udp_probe_send_failures = 0;
    int m_fast_sync_udp_request_send_failures = 0;
    int m_fast_sync_udp_request_timeouts = 0;
    int m_fast_sync_udp_checksum_failures = 0;
    int m_fast_sync_udp_buffer_failures = 0;
    int m_fast_sync_udp_submit_failures = 0;
    double m_fast_sync_tcp_ewma_blocks_per_second = 0.0;
    double m_fast_sync_udp_ewma_blocks_per_second = 0.0;
    int m_fast_sync_tcp_quota_remaining = 1;
    int m_fast_sync_udp_quota_remaining = 1;
    int m_fast_sync_window_size = 2;
    qint64 m_fast_sync_udp_cooldown_until_ms = 0;
    qint64 m_fast_sync_last_probe_ms = 0;
    qint64 m_fast_sync_last_udp_attempt_ms = 0;
    QString m_fast_sync_decision_summary = QStringLiteral(
        "Fast sync selector waiting for peer samples; normal TCP sync and UDP will be sampled when available.");
    int m_fast_sync_last_udp_accepted_height = -1;
    int m_fast_sync_udp_datagram_index = 0;
    int m_fast_sync_current_datagram_bytes = 1232;
    int m_fast_sync_current_chunk_bytes = 768;
    bool m_mask_balances = false;
    bool m_third_party_tx_urls_enabled = false;
    QString m_third_party_tx_url;
    QString m_explorer_mode = QStringLiteral("internal");
    QVariantList m_explorer_recent_lookups;
    QVariantList m_explorer_rich_list;
    QVariantList m_explorer_movements;
    QVariantMap m_coindroids_summary;
    QVariantList m_coindroids_window_rows;
    QVariantList m_coindroids_endpoint_rows;
    QVariantList m_coindroids_winner_rows;
    QVariantList m_coindroids_phase_rows;
    QVariantList m_coindroids_published_rows;
    QVariantList m_coindroids_vanity_rows;
    QVariantList m_coindroids_op_return_rows;
    QVariantList m_coindroids_bot_rows;
    QVariantList m_coindroids_payout_rows;
    QVariantList m_coindroids_attack_address_rows;
    QVariantList m_coindroids_qr_seed_rows;
    QVariantList m_coindroids_source_ammo_rows;
    QVariantList m_coindroids_olo_rows;
    QVariantList m_coindroids_game_address_rows;
    QVariantList m_coindroids_evidence_rows;
    QString m_coindroids_status = QStringLiteral("Coindroids analysis not loaded yet.");
    int m_coindroids_generation = 0;
    bool m_coindroids_scanning = false;
    qint64 m_coindroids_last_refresh_ms = 0;
    QVariantMap m_defcoin_timeline_summary;
    QVariantList m_defcoin_timeline_rows;
    QString m_defcoin_timeline_criteria = QStringLiteral("Timeline not loaded yet.");
    QString m_defcoin_timeline_status = QStringLiteral("/r/Defcoin timeline not loaded yet.");
    bool m_defcoin_timeline_loaded = false;
    QVariantMap m_network_pulse_summary;
    QVariantList m_network_pulse_history_rows;
    QString m_network_pulse_status =
        QStringLiteral("Network Pulse waits for the Explorer index to cache block timestamps.");
    QVariantList m_explorer_contacts;
    QVariantList m_explorer_contact_relationships;
    QVariantList m_explorer_contact_sets;
    QString m_current_explorer_contact_set_name = QStringLiteral("Default");
    QString m_explorer_analytics_status = QStringLiteral("Explorer analytics not loaded yet.");
    int m_explorer_analytics_generation = 0;
    bool m_explorer_analytics_refreshing = false;
    int m_explorer_analytics_last_threshold_coins = -1;
    QString m_explorer_analytics_last_scope;
    qint64 m_explorer_analytics_last_refresh_ms = 0;
    bool m_explorer_indexing = false;
    bool m_explorer_index_request_in_flight = false;
    bool m_explorer_auto_index_requested = false;
    bool m_explorer_index_paused_by_user = false;
    QString m_explorer_index_status = QStringLiteral("Index not running.");
    int m_explorer_index_height = 0;
    int m_explorer_index_tip = 0;
    int m_explorer_indexed_block_count = 0;
    int m_explorer_indexed_output_count = 0;
    qint64 m_explorer_index_started_ms = 0;
    int m_explorer_index_started_block_count = 0;
    qint64 m_explorer_index_last_ui_update_ms = 0;
    std::unique_ptr<QLockFile> m_explorer_writer_lock;
    struct ExplorerTop100Entry {
        qint64 balance = 0;
        QString address;
    };
    struct ExplorerTop100EntryLess {
        bool operator()(const ExplorerTop100Entry& a, const ExplorerTop100Entry& b) const
        {
            if (a.balance != b.balance)
                return a.balance < b.balance;
            return a.address > b.address;
        }
    };
    bool m_explorer_top100_scanning = false;
    bool m_explorer_top100_paused_by_user = false;
    bool m_explorer_top100_focused_indexing = false;
    QString m_explorer_top100_status = QStringLiteral("Holder timeline not built yet.");
    int m_explorer_top100_scan_start_height = 0;
    int m_explorer_top100_scan_height = 0;
    int m_explorer_top100_scan_end_height = 0;
    int m_explorer_top100_timeline_start_height = -1;
    int m_explorer_top100_timeline_end_height = -1;
    int m_explorer_top100_timeline_event_count = 0;
    int m_explorer_top100_events_written = 0;
    int m_explorer_top100_checkpoint_interval_blocks = 10000;
    int m_explorer_top100_next_checkpoint_height = 0;
    int m_explorer_top100_last_rank_count = 0;
    qint64 m_explorer_top100_last_ui_update_ms = 0;
    qint64 m_explorer_top100_started_ms = 0;
    qint64 m_explorer_top100_total_sats = 0;
    QHash<QString, qint64> m_explorer_top100_balances;
    std::set<ExplorerTop100Entry, ExplorerTop100EntryLess> m_explorer_top100_order;
    QVector<QPair<QString, int>> m_explorer_top100_previous_rows;
    QVariantList m_forensics_irregular_messages;
    bool m_forensics_scanning = false;
    bool m_forensics_request_in_flight = false;
    bool m_forensics_scan_complete = false;
    bool m_forensics_accept_bip141_as_regular = true;
    bool m_forensics_missing_witness_found = false;
    int m_forensics_first_missing_witness_height = -1;
    int m_forensics_missing_witness_count = 0;
    QString m_forensics_scan_status = QStringLiteral("Irregular message scan not started.");
    QString m_forensics_scan_summary;
    bool m_forensics_witness_repair_running = false;
    bool m_forensics_witness_inspection_available = false;
    bool m_forensics_witness_capability_known = false;
    bool m_forensics_witness_capability_probe_in_flight = false;
    QString m_forensics_witness_repair_status = QStringLiteral("Witness data inspection not started.");
    int m_forensics_witness_repair_start_height = 903168;
    int m_forensics_witness_repair_inspected_blocks = 0;
    int m_forensics_witness_repair_first_missing_height = -1;
    int m_forensics_scan_start_height = 0;
    int m_forensics_scan_height = 0;
    int m_forensics_scan_tip = 0;
    QString m_forensics_compress_prefix;
    int m_forensics_compress_start_height = -1;
    int m_forensics_compress_last_height = -1;
    QVariantMap m_forensics_compress_start_row;
    QVariantMap m_forensics_compress_summary_row;
    QVariantMap m_forensics_compress_end_row;
    int m_forensics_compress_start_index = -1;
    int m_forensics_compress_summary_index = -1;
    int m_forensics_compress_end_index = -1;
    int m_forensics_compress_count = 0;
    mutable QStringList m_bip39_words;
    mutable QHash<QString, int> m_bip39_word_index;
};

#endif // DEFCOIN_NU_RPC_SERVICE_H
