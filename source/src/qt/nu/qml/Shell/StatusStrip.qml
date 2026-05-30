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
