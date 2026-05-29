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
    implicitHeight: NuService.minerRunning ? 106 : 62

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
        anchors.fill: parent
        anchors.leftMargin: NuTokens.spaceLg
        anchors.rightMargin: NuTokens.spaceLg
        anchors.topMargin: NuTokens.spaceSm
        anchors.bottomMargin: NuTokens.spaceSm
        spacing: NuTokens.spaceSm

        RowLayout {
            id: statusRow
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: NuTokens.spaceLg
            NuStatusDot {
                label: NuService.networkState === "connected" ? "Network connected" : "Network isolated"
                stateColor: NuService.networkState === "connected" ? NuTokens.stateConnected : NuTokens.stateError
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
                valueMaximumWidth: NuService.syncing ? 360 : 120
                helpText: NuService.syncing
                          ? "Blockchain synchronization progress from Core's getblockchaininfo: verification progress, current block, known headers, and an ETA derived from recent progress."
                          : "The local chain is caught up to the best headers currently known by this node."
            }

            Item { Layout.fillWidth: true }

            NuStatusDot {
                label: NuService.walletLocked ? "Wallet locked" : "Wallet unlocked"
                stateColor: NuService.walletLocked ? NuTokens.stateInactive : NuTokens.stateConnected
            }
        }

        Rectangle {
            id: miningBubble
            visible: NuService.minerRunning
            Layout.fillWidth: true
            implicitHeight: visible ? 34 : 0
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

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: NuTokens.spaceMd
                anchors.rightMargin: NuTokens.spaceMd
                spacing: NuTokens.spaceLg

                NuStatusDot {
                    label: "Mining State: " + NuService.miningStateText
                    stateColor: NuTokens.accentSky
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

                Item { Layout.fillWidth: true }
            }
        }
    }
}
