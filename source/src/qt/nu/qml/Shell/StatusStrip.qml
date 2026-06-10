import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

Rectangle {
    id: root
    radius: NuTokens.radiusMedium
    color: NuTokens.panelBase
    border.color: NuTokens.lineSubtle
    implicitHeight: contentColumn.implicitHeight + NuTokens.spaceSm * 2

    property bool showExplorerIndexTools: false

    signal explorerSearchRequested(string query)

    function runExplorerSearch() {
        const clean = String(mastSearchField.text || "").trim()
        if (clean.length === 0) return
        root.explorerSearchRequested(clean)
    }

    function explorerIndexPercentText() {
        if (NuService.explorerIndexTip <= 0)
            return NuService.explorerIndexedBlockCount > 0 ? "Cached" : "0%"
        const progress = Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
        return (progress * 100).toFixed(2) + "%"
    }

    function progressPercentFromText(text, fallback) {
        const match = String(text || "").match(/([0-9]+(?:\.[0-9]+)?)%/)
        return match ? (match[1] + "%") : fallback
    }

    function textHasProblem(text) {
        const lower = String(text || "").toLowerCase()
        return lower.indexOf("error") >= 0
            || lower.indexOf("failed") >= 0
            || lower.indexOf("failure") >= 0
            || lower.indexOf("cannot") >= 0
            || lower.indexOf("locked by another") >= 0
    }

    function textLooksBusy(text) {
        const lower = String(text || "").toLowerCase()
        return lower.indexOf("loading") >= 0
            || lower.indexOf("reading") >= 0
            || lower.indexOf("scanning") >= 0
            || lower.indexOf("refresh") >= 0
            || lower.indexOf("estimating") >= 0
            || lower.indexOf("starting") >= 0
            || lower.indexOf("indexing") >= 0
    }

    function textLooksReady(text) {
        const lower = String(text || "").toLowerCase()
        return lower.indexOf("ready") >= 0
            || lower.indexOf("loaded") >= 0
            || lower.indexOf("complete") >= 0
            || lower.indexOf("covers indexed blocks") >= 0
            || lower.indexOf("indexed through") >= 0
    }

    function explorerIndexReady() {
        if (NuService.explorerIndexedBlockCount > 0) return true
        return NuService.explorerIndexTip > 0 && NuService.explorerIndexHeight >= NuService.explorerIndexTip
    }

    function explorerIndexLabel() {
        if (NuService.explorerIndexing || root.textLooksBusy(NuService.explorerIndexStatus))
            return "Loading index " + root.explorerIndexPercentText()
        return "Explorer index"
    }

    function explorerIndexColor() {
        if (NuService.explorerIndexing)
            return root.textHasProblem(NuService.explorerIndexStatus) ? NuTokens.stateError : NuTokens.stateWarning
        if (root.explorerIndexReady()) return NuTokens.stateConnected
        if (root.textHasProblem(NuService.explorerIndexStatus)) return NuTokens.stateError
        return NuTokens.stateInactive
    }

    function holderTimelineValue() {
        if (NuService.explorerTop100Scanning)
            return NuService.explorerTop100ScanHeight + " / " + NuService.explorerTop100ScanEndHeight
        return NuService.explorerTop100TimelineEventCount + " checkpoints"
    }

    function holderTimelineLabel() {
        return "Holder timeline"
    }

    function holderTimelineColor() {
        if (root.textHasProblem(NuService.explorerTop100Status)) return NuTokens.stateError
        if (NuService.explorerTop100Scanning) return NuTokens.stateWarning
        if (NuService.explorerTop100TimelineEventCount > 0) return NuTokens.stateConnected
        return NuTokens.stateInactive
    }

    function movementStatusLabel() {
        if (root.textLooksBusy(NuService.explorerAnalyticsStatus))
            return "Loading analytics " + root.progressPercentFromText(NuService.explorerAnalyticsStatus, "0%")
        return "Movements"
    }

    function movementStatusColor() {
        if (root.textHasProblem(NuService.explorerAnalyticsStatus)) return NuTokens.stateError
        if (root.textLooksBusy(NuService.explorerAnalyticsStatus)) return NuTokens.stateWarning
        if (NuService.explorerMovements.length > 0 || root.textLooksReady(NuService.explorerAnalyticsStatus))
            return NuTokens.stateConnected
        return NuTokens.stateInactive
    }

    function coindroidsStatusLabel() {
        return "Droid Trails"
    }

    function coindroidsStatusColor() {
        if (root.textHasProblem(NuService.coindroidsStatus)) return NuTokens.stateError
        if (NuService.coindroidsScanning) return NuTokens.stateWarning
        if (NuService.coindroidsWindowRows.length > 0 || root.textLooksReady(NuService.coindroidsStatus))
            return NuTokens.stateConnected
        return NuTokens.stateInactive
    }

    function forensicsProgressValue() {
        if (NuService.forensicsScanning && NuService.forensicsScanTip > 0) {
            const progress = Math.max(0, Math.min(1, NuService.forensicsScanHeight / NuService.forensicsScanTip))
            return (progress * 100).toFixed(2) + "%"
        }
        return NuService.forensicsIrregularMessageCount + " rows"
    }

    function forensicsStatusLabel() {
        return "Forensics"
    }

    function forensicsStatusColor() {
        if (root.textHasProblem(NuService.forensicsScanStatus)) return NuTokens.stateError
        if (NuService.forensicsScanning) return NuTokens.stateWarning
        if (NuService.forensicsScanComplete || NuService.forensicsIrregularMessageCount > 0) return NuTokens.stateConnected
        return NuTokens.stateInactive
    }

    function networkStatusLabel() {
        return "Network"
    }

    function networkStatusColor() {
        if (!NuService.rpcConnected)
            return NuTokens.stateWarning
        if (NuService.networkState === "connected" && NuService.peerCount <= 0)
            return NuTokens.stateWarning
        if (NuService.networkState === "connected")
            return NuTokens.stateConnected
        return NuTokens.stateError
    }

    function networkStatusHelp() {
        if (!NuService.rpcConnected)
            return "Nu is starting or connecting to the local backend. Peer counts will appear after RPC is ready."
        if (NuService.networkState === "connected" && NuService.peerCount <= 0)
            return "P2P networking is enabled, but the node has not completed a peer connection yet. This is normal for the first few seconds after launch."
        if (NuService.networkState === "connected")
            return "The backend reports active P2P networking and at least one peer connection."
        return "Peer networking is disabled or no usable P2P state is available. Settings > Network can reconnect the node."
    }

    function walletStatusLabel() {
        return "Wallet"
    }

    function walletStatusColor() {
        if (!NuService.walletSelected) return NuTokens.stateInactive
        if (NuService.walletEncrypted && !NuService.walletLocked) return NuTokens.stateWarning
        return NuTokens.stateConnected
    }

    function walletStatusHelp() {
        if (!NuService.walletSelected) return "No active wallet is selected."
        if (NuService.walletEncrypted && NuService.walletLocked) return "The active wallet is encrypted and locked."
        if (NuService.walletEncrypted) return "The active wallet is encrypted but currently unlocked."
        return "The active wallet is loaded and not encrypted."
    }

    function syncMastValue() {
        if (!NuService.syncing) return NuService.syncState
        const tip = Number(NuService.headerHeight || 0)
        if (tip <= 0) return NuService.syncState
        return "Block " + NuService.blockHeight + " of " + tip
                + " (" + NuService.syncProgressPercent + "%, ETA " + NuService.syncEta + ")"
    }

    function currentWalletIndex() {
        if (!NuService.walletSelected)
            return -1
        for (var i = 0; i < NuService.availableWallets.length; ++i) {
            if (String(NuService.availableWallets[i]) === NuService.currentWalletName)
                return i
        }
        return -1
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.leftMargin: NuTokens.spaceLg
        anchors.rightMargin: NuTokens.spaceLg
        anchors.topMargin: NuTokens.spaceSm
        anchors.bottomMargin: NuTokens.spaceSm
        spacing: NuTokens.spaceSm

        RowLayout {
            id: searchRow
            visible: root.showExplorerIndexTools
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
            spacing: root.width < 900 ? NuTokens.spaceSm : NuTokens.spaceMd

            NuTextField {
                id: mastSearchField
                Layout.fillWidth: true
                Layout.minimumWidth: 260
                Layout.maximumWidth: 760
                Layout.preferredHeight: 42
                placeholderText: "Search wallet address, txid, block hash, or height..."
                helpText: "Search the local Defcoin explorer for a wallet address, transaction ID, block hash, or block height."
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.runExplorerSearch()
                        event.accepted = true
                    }
                }
            }

            NuActionButton {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 42
                text: "Search"
                primary: true
                helpText: "Switch to Explorer and open the matching local lookup result."
                onClicked: root.runExplorerSearch()
            }
        }

        Flow {
            id: indexFlow
            visible: root.showExplorerIndexTools
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? indexFlow.implicitHeight : 0
            spacing: root.width < 900 ? NuTokens.spaceMd : NuTokens.spaceLg

            NuStatusDot {
                label: root.explorerIndexLabel()
                stateColor: root.explorerIndexColor()
                helpText: NuService.explorerIndexStatus
                labelMaximumWidth: root.width < 900 ? 190 : 230
            }

            NuMetricRow {
                label: "Explorer"
                value: root.explorerIndexPercentText()
                helpText: "Progress of the local block, transaction, address, and output cache."
            }

            NuStatusDot {
                label: root.holderTimelineLabel()
                stateColor: root.holderTimelineColor()
                helpText: NuService.explorerTop100Status
                labelMaximumWidth: root.width < 900 ? 200 : 260
            }

            NuMetricRow {
                label: "Holder Atlas"
                value: root.holderTimelineValue()
                valueMaximumWidth: root.width < 900 ? 120 : 180
                helpText: "Sparse over-time checkpoints for largest-holder analysis."
            }

            NuStatusDot {
                label: root.movementStatusLabel()
                stateColor: root.movementStatusColor()
                helpText: NuService.explorerAnalyticsStatus
                labelMaximumWidth: root.width < 900 ? 180 : 230
            }

            NuMetricRow {
                label: "Movements"
                value: NuService.explorerMovements.length + " rows"
                helpText: "Loaded large-movement rows from the local Explorer index."
            }

            NuStatusDot {
                label: root.coindroidsStatusLabel()
                stateColor: root.coindroidsStatusColor()
                helpText: NuService.coindroidsStatus
                labelMaximumWidth: root.width < 900 ? 180 : 230
            }

            NuStatusDot {
                label: root.forensicsStatusLabel()
                stateColor: root.forensicsStatusColor()
                helpText: NuService.forensicsScanStatus
                labelMaximumWidth: root.width < 900 ? 170 : 220
            }

            NuMetricRow {
                label: "Forensics"
                value: root.forensicsProgressValue()
                helpText: NuService.forensicsScanSummary.length > 0 ? NuService.forensicsScanSummary : NuService.forensicsScanStatus
            }
        }

        Flow {
            id: statusFlow
            Layout.fillWidth: true
            Layout.preferredHeight: statusFlow.implicitHeight
            spacing: root.width < 900 ? NuTokens.spaceMd : NuTokens.spaceLg
            NuStatusDot {
                label: root.networkStatusLabel()
                stateColor: root.networkStatusColor()
                helpText: root.networkStatusHelp()
                labelMaximumWidth: root.width < 900 ? 170 : 230
            }

            NuMetricRow {
                label: "Hashrate:"
                value: NuService.recentNetworkHashrate
                helpText: "Estimated network hashrate from getnetworkhashps over the last 120 blocks. It is a recent estimate, not an exact live measurement."
            }

            NuMetricRow {
                label: "Difficulty:"
                value: NuService.networkDifficulty
                helpText: "Current proof-of-work difficulty from chain state. It can change at retarget boundaries and may lag until RPC refreshes."
            }

            NuMetricRow {
                label: "Avg block:"
                value: NuService.recentAverageBlockTime
                helpText: "Recent average block spacing over up to 120 active-chain blocks, sampled from RPC block headers with the local Explorer index used as fallback."
            }

            NuMetricRow {
                label: "Peers"
                value: NuService.peerCount
            }

            NuMetricRow {
                label: "Block"
                value: NuService.blockHeight
            }

            NuMetricRow {
                label: "Sync"
                value: root.syncMastValue()
                valueMaximumWidth: NuService.syncing ? (root.width < 900 ? 300 : 430) : 120
                helpText: NuService.syncing
                          ? "Blockchain synchronization progress from Core's getblockchaininfo: verification progress, current block, known headers, and an ETA derived from recent progress."
                          : "The local chain is caught up to the best headers currently known by this node."
            }

            NuStatusDot {
                label: root.walletStatusLabel()
                stateColor: root.walletStatusColor()
                helpText: root.walletStatusHelp()
                labelMaximumWidth: 170
            }
        }

        Rectangle {
            id: miningBubble
            visible: NuService.minerRunning
            Layout.fillWidth: true
            implicitHeight: visible ? Math.max(34, miningFlow.implicitHeight + NuTokens.spaceXs * 2) : 0
            radius: NuTokens.radiusSmall
            color: "#eef7ff"
            border.color: NuTokens.accentSky

            ToolTip.visible: miningBubbleHover.hovered
            ToolTip.text: "Local miner status parsed from cpuminer output. A is accepted shares and R is rejected shares. Counts reset when Nu starts the miner process."
            ToolTip.delay: NuTokens.tooltipDelay
            ToolTip.timeout: NuTokens.tooltipTimeout

            HoverHandler {
                id: miningBubbleHover
            }

            Flow {
                id: miningFlow
                anchors.fill: parent
                anchors.leftMargin: NuTokens.spaceMd
                anchors.rightMargin: NuTokens.spaceMd
                anchors.topMargin: NuTokens.spaceXs
                anchors.bottomMargin: NuTokens.spaceXs
                spacing: NuTokens.spaceLg

                NuStatusDot {
                    label: "Mining State: " + NuService.miningStateText
                    stateColor: NuTokens.accentSky
                    labelMaximumWidth: root.width < 900 ? 220 : 300
                }

                NuMetricRow {
                    label: "Hashrate:"
                    value: NuService.minerHashrateText
                }

                NuMetricRow {
                    label: "Accepted:"
                    value: String(NuService.minerAcceptedShares)
                }

                NuMetricRow {
                    label: "Rejected:"
                    value: String(NuService.minerRejectedShares)
                }

            }
        }
    }
}
