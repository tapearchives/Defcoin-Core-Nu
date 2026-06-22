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

    property var defaultHeaderSlotWidths: [108, 132, 132, 166, 186, 108, 430, 86, 250]
    property var learnedHeaderSlotWidths: NuService.tableColumnWidths("statusHeaderSlots", defaultHeaderSlotWidths)

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
        if (!NuService.syncing) return "Ready"
        const tip = Number(NuService.headerHeight || 0)
        const mode = String(NuService.syncTransportMode || "Syncing")
        if (tip <= 0) return mode
        return mode + " | " + NuService.syncProgressPercent + "%, ETA " + NuService.syncEta
    }

    function blockMastValue() {
        const block = Number(NuService.blockHeight || 0)
        const tip = Number(NuService.headerHeight || 0)
        if (NuService.syncing && tip > 0)
            return block + " of " + tip
        if (block > 0)
            return block + ", Up to Date"
        return NuService.syncing ? "Syncing" : "Up to Date"
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

    function headerSlot(index, normalWidth, compactWidth) {
        if (root.width < 1050)
            return compactWidth
        const learned = Number(root.learnedHeaderSlotWidths[index] || normalWidth)
        return Math.max(normalWidth, learned)
    }

    function learnedSlotWidth(component, defaultWidth, maximumWidth) {
        if (!component)
            return defaultWidth
        return Math.max(defaultWidth, Math.min(maximumWidth, Math.ceil(component.implicitWidth + NuTokens.spaceMd)))
    }

    function currentHeaderSlotWidths() {
        return [
            root.learnedSlotWidth(networkSlot, 108, 150),
            root.learnedSlotWidth(txSlot, 132, 180),
            root.learnedSlotWidth(rxSlot, 132, 180),
            root.learnedSlotWidth(hashrateSlot, 166, 220),
            root.learnedSlotWidth(difficultySlot, 186, 240),
            root.learnedSlotWidth(walletSlot, 108, 150),
            root.learnedSlotWidth(syncSlot, 430, 720),
            root.learnedSlotWidth(peersSlot, 86, 120),
            root.learnedSlotWidth(blockSlot, 250, 320)
        ]
    }

    function refreshHeaderSlots() {
        root.learnedHeaderSlotWidths = NuService.tableColumnWidths("statusHeaderSlots", root.defaultHeaderSlotWidths)
    }

    function saveLearnedHeaderSlots() {
        if (root.width < 1050)
            return
        const widths = root.currentHeaderSlotWidths()
        NuService.saveTableColumnWidths("statusHeaderSlots", widths)
        root.learnedHeaderSlotWidths = widths
    }

    function scheduleHeaderSlotSave() {
        if (root.width >= 1050)
            headerSlotSaveTimer.restart()
    }

    Component.onCompleted: root.refreshHeaderSlots()
    Component.onDestruction: root.saveLearnedHeaderSlots()

    Connections {
        target: NuService
        function onTableSettingsChanged() { root.refreshHeaderSlots() }
    }

    Timer {
        id: headerSlotSaveTimer
        interval: 1600
        repeat: false
        onTriggered: root.saveLearnedHeaderSlots()
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.leftMargin: NuTokens.spaceLg
        anchors.rightMargin: NuTokens.spaceLg
        anchors.topMargin: NuTokens.spaceSm
        anchors.bottomMargin: NuTokens.spaceSm
        spacing: NuTokens.spaceSm

        ColumnLayout {
            id: statusBlock
            Layout.fillWidth: true
            Layout.preferredHeight: statusBlock.implicitHeight
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: root.width < 1050 ? NuTokens.spaceSm : NuTokens.spaceMd

                NuStatusDot {
                    id: networkSlot
                    Layout.preferredWidth: root.headerSlot(0, 108, 94)
                    label: root.networkStatusLabel()
                    stateColor: root.networkStatusColor()
                    helpText: root.networkStatusHelp()
                    labelMaximumWidth: root.headerSlot(0, 108, 94) - 26
                }

                NuMetricRow {
                    id: txSlot
                    Layout.preferredWidth: root.headerSlot(1, 132, 112)
                    label: "TX:"
                    value: NuService.trafficSentRate
                    labelMaximumWidth: 30
                    valueMaximumWidth: root.headerSlot(1, 132, 112) - 44
                    helpText: "Recent total network transmit rate, including Core TCP, Fast Sync UDP, and Quick Clone UDP traffic."
                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }

                NuMetricRow {
                    id: rxSlot
                    Layout.preferredWidth: root.headerSlot(2, 132, 112)
                    label: "RX:"
                    value: NuService.trafficReceivedRate
                    labelMaximumWidth: 30
                    valueMaximumWidth: root.headerSlot(2, 132, 112) - 44
                    helpText: "Recent total network receive rate, including Core TCP, Fast Sync UDP, and Quick Clone UDP traffic."
                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }

                NuMetricRow {
                    id: hashrateSlot
                    Layout.preferredWidth: root.headerSlot(3, 166, 140)
                    label: "Hashrate:"
                    value: NuService.recentNetworkHashrate
                    labelMaximumWidth: 74
                    valueMaximumWidth: root.headerSlot(3, 166, 140) - 88
                    helpText: "Estimated network hashrate from getnetworkhashps over the last 120 blocks. It is a recent estimate, not an exact live measurement."
                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }

                NuMetricRow {
                    id: difficultySlot
                    Layout.preferredWidth: root.headerSlot(4, 186, 158)
                    label: "Difficulty:"
                    value: NuService.networkDifficulty
                    labelMaximumWidth: 78
                    valueMaximumWidth: root.headerSlot(4, 186, 158) - 92
                    helpText: "Current proof-of-work difficulty from chain state. It can change at retarget boundaries and may lag until RPC refreshes."
                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.width < 1050 ? NuTokens.spaceSm : NuTokens.spaceMd

                NuStatusDot {
                    id: walletSlot
                    Layout.preferredWidth: root.headerSlot(5, 108, 94)
                    label: root.walletStatusLabel()
                    stateColor: root.walletStatusColor()
                    helpText: root.walletStatusHelp()
                    labelMaximumWidth: root.headerSlot(5, 108, 94) - 26
                }

                Rectangle {
                    id: syncSlot
                    Layout.preferredWidth: NuService.syncing ? root.headerSlot(6, 430, 260) : 180
                    implicitWidth: syncContent.implicitWidth + NuTokens.spaceSm * 2
                    implicitHeight: Math.max(26, syncContent.implicitHeight + NuTokens.spaceXs * 2)
                    radius: NuTokens.radiusSmall
                    color: syncHover.hovered ? Qt.rgba(0, 0, 0, 0.035) : "transparent"

                    readonly property string helpText: NuService.syncing
                                                       ? "Blockchain synchronization progress from Core's getblockchaininfo: verification progress, current block, known headers, and an ETA derived from recent progress."
                                                       : "The local chain is caught up to the best headers currently known by this node."

                    ToolTip.visible: syncHover.hovered
                    ToolTip.text: syncSlot.helpText
                    ToolTip.delay: NuTokens.tooltipDelay
                    ToolTip.timeout: NuTokens.tooltipTimeout

                    Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }

                    HoverHandler {
                        id: syncHover
                    }

                    RowLayout {
                        id: syncContent
                        anchors.fill: parent
                        anchors.leftMargin: NuTokens.spaceSm
                        anchors.rightMargin: NuTokens.spaceSm
                        spacing: NuTokens.spaceXs

                        Label {
                            text: "Sync:"
                            Layout.alignment: Qt.AlignVCenter
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Label {
                            text: root.syncMastValue()
                            Layout.alignment: Qt.AlignVCenter
                            Layout.maximumWidth: NuService.syncing ? root.headerSlot(6, 430, 260) - 60 : 112
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBody
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }

                Item { Layout.fillWidth: true }

                NuMetricRow {
                    id: peersSlot
                    Layout.preferredWidth: root.headerSlot(7, 86, 72)
                    label: "Peers"
                    value: NuService.peerCount
                    labelMaximumWidth: 44
                    valueMaximumWidth: 30
                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }

                NuMetricRow {
                    id: blockSlot
                    Layout.preferredWidth: root.headerSlot(8, 250, 188)
                    label: "Block"
                    value: root.blockMastValue()
                    labelMaximumWidth: 44
                    valueMaximumWidth: root.headerSlot(8, 250, 188) - 58
                    helpText: NuService.syncing && NuService.headerHeight > 0
                              ? "Current validated block height compared with the best header height currently known by this node."
                              : "Current validated active-chain block height. Up to Date means this node is caught up to its known headers."
                    onImplicitWidthChanged: root.scheduleHeaderSlotSave()
                }
            }
        }

        Rectangle {
            id: miningBubble
            visible: NuService.minerRunning
            Layout.fillWidth: true
            implicitHeight: visible ? Math.max(34, miningRow.implicitHeight + NuTokens.spaceXs * 2) : 0
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
                id: miningRow
                anchors.fill: parent
                anchors.leftMargin: NuTokens.spaceMd
                anchors.rightMargin: NuTokens.spaceMd
                anchors.topMargin: NuTokens.spaceXs
                anchors.bottomMargin: NuTokens.spaceXs
                spacing: NuTokens.spaceMd

                Rectangle {
                    implicitWidth: 14
                    implicitHeight: 14
                    radius: 7
                    color: Qt.rgba(NuTokens.accentSky.r, NuTokens.accentSky.g, NuTokens.accentSky.b, 0.16)
                    border.color: Qt.rgba(NuTokens.accentSky.r, NuTokens.accentSky.g, NuTokens.accentSky.b, 0.38)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.centerIn: parent
                        color: NuTokens.accentSky
                    }
                }

                NuMetricRow {
                    label: "Mining State:"
                    value: NuService.miningStateText
                    labelMaximumWidth: 92
                    valueMaximumWidth: root.width < 900 ? 180 : 280
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
