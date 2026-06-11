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
    property var defaultHeaderSlotWidths: [108, 132, 132, 166, 186, 108, 430, 86, 250]
    property var learnedHeaderSlotWidths: NuService.tableColumnWidths("statusHeaderSlots", defaultHeaderSlotWidths)

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
