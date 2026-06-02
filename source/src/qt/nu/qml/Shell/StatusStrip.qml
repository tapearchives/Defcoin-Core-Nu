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
        if (NuService.explorerIndexTip <= 0) return "0.00%"
        const progress = Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
        return (progress * 100).toFixed(2) + "%"
    }

    function holderTimelineValue() {
        if (NuService.explorerTop100Scanning)
            return NuService.explorerTop100ScanHeight + " / " + NuService.explorerTop100ScanEndHeight
        return NuService.explorerTop100TimelineEventCount + " checkpoints"
    }

    function holderTimelineLabel() {
        if (NuService.explorerTop100Scanning) return "Holder timeline indexing"
        if (NuService.explorerTop100TimelineEventCount > 0) return "Holder timeline ready"
        return "Holder timeline idle"
    }

    function forensicsProgressValue() {
        if (NuService.forensicsScanning && NuService.forensicsScanTip > 0) {
            const progress = Math.max(0, Math.min(1, NuService.forensicsScanHeight / NuService.forensicsScanTip))
            return (progress * 100).toFixed(2) + "%"
        }
        return NuService.forensicsIrregularMessageCount + " rows"
    }

    function networkStatusLabel() {
        if (!NuService.rpcConnected)
            return NuService.connectionStatus === "Starting backend" ? "Starting backend..." : "Connecting to backend..."
        if (NuService.networkState === "connected" && NuService.peerCount <= 0)
            return "Peers connecting..."
        if (NuService.networkState === "connected")
            return "Network connected"
        return "Network isolated"
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
            spacing: NuTokens.spaceMd

            Item { Layout.fillWidth: true }

            NuTextField {
                id: mastSearchField
                Layout.preferredWidth: Math.min(640, Math.max(420, root.width * 0.52))
                Layout.maximumWidth: 720
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
                Layout.preferredWidth: 96
                Layout.preferredHeight: 42
                text: "Search"
                primary: true
                helpText: "Switch to Explorer and open the matching local lookup result."
                onClicked: root.runExplorerSearch()
            }

            Item { Layout.fillWidth: true }
        }

        Flow {
            id: indexFlow
            visible: root.showExplorerIndexTools
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? indexFlow.implicitHeight : 0
            spacing: NuTokens.spaceLg

            NuStatusDot {
                label: NuService.explorerIndexing ? "Explorer indexing" : "Explorer index idle"
                stateColor: NuService.explorerIndexing ? NuTokens.stateWarning : NuTokens.stateInactive
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
                stateColor: NuService.explorerTop100Scanning ? NuTokens.stateWarning : (NuService.explorerTop100TimelineEventCount > 0 ? NuTokens.stateConnected : NuTokens.stateInactive)
                helpText: NuService.explorerTop100Status
                labelMaximumWidth: root.width < 900 ? 200 : 260
            }

            NuMetricRow {
                label: "Holder Atlas"
                value: root.holderTimelineValue()
                valueMaximumWidth: root.width < 900 ? 120 : 180
                helpText: "Sparse over-time checkpoints for largest-holder analysis."
            }

            NuMetricRow {
                label: "Movements"
                value: NuService.explorerMovements.length + " rows"
                helpText: "Loaded large-movement rows from the local Explorer index."
            }

            NuMetricRow {
                label: "Forensics"
                value: root.forensicsProgressValue()
                helpText: NuService.forensicsScanStatus
            }
        }

        Flow {
            id: statusFlow
            Layout.fillWidth: true
            Layout.preferredHeight: statusFlow.implicitHeight
            spacing: NuTokens.spaceLg
            NuStatusDot {
                label: root.networkStatusLabel()
                stateColor: root.networkStatusColor()
                helpText: root.networkStatusHelp()
                labelMaximumWidth: root.width < 900 ? 170 : 230
            }

            NuMetricRow {
                label: "Recent hashrate:"
                value: NuService.recentNetworkHashrate
                helpText: "Estimated network hashrate from getnetworkhashps over the last 120 blocks. It is a recent estimate, not an exact live measurement."
            }

            NuMetricRow {
                label: "Difficulty:"
                value: NuService.networkDifficulty
                helpText: "Current proof-of-work difficulty from chain state. It can change at retarget boundaries and may lag until RPC refreshes."
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
                value: NuService.syncState
                valueMaximumWidth: NuService.syncing ? (root.width < 900 ? 220 : 300) : 120
                helpText: NuService.syncing
                          ? "Blockchain synchronization progress from Core's getblockchaininfo: verification progress, current block, known headers, and an ETA derived from recent progress."
                          : "The local chain is caught up to the best headers currently known by this node."
            }

            NuStatusDot {
                label: NuService.walletLocked ? "Wallet locked" : "Wallet unlocked"
                stateColor: NuService.walletLocked ? NuTokens.stateInactive : NuTokens.stateConnected
                helpText: NuService.walletLocked ? "The active wallet is encrypted and locked." : "The active wallet is unlocked or not encrypted."
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
