import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg

    property int movementPage: 0
    property int selectedRichRank: -1
    property int hoveredRichRank: -1
    property var timelineSnapshot: ({ rows: [], height: -1, status: "No Top 100 timeline snapshot loaded." })
    property bool timelinePlaying: false
    property bool top100EndInitialized: false
    property bool top100EndEdited: false
    readonly property real indexProgress: NuService.explorerIndexTip > 0
                                          ? Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
                                          : 0

    Connections {
        target: NuService
        function onExplorerChanged() {
            if (!top100EndField || root.top100EndEdited || NuService.explorerIndexTip <= 0) return
            if (top100EndField.text.length === 0 || top100EndField.text === "0")
                root.initializeTop100EndField(true)
        }
    }

    function indexPercentText() {
        if (NuService.explorerIndexTip <= 0) return "0.00%"
        return (root.indexProgress * 100).toFixed(2) + "%"
    }

    function movementThresholdCoins() {
        const value = parseInt(movementThreshold.text)
        return isNaN(value) ? 5000 : Math.max(0, Math.min(1000000000, value))
    }

    function movementPageCount(rowsPerPage) {
        const perPage = Math.max(1, rowsPerPage)
        return Math.max(1, Math.ceil(NuService.explorerMovements.length / perPage))
    }

    function initializeTop100EndField(force) {
        if (!top100EndField || (root.top100EndInitialized && root.top100EndEdited && !force)) return
        const tip = Math.max(0, NuService.explorerIndexTip)
        top100EndField.text = String(tip)
        root.top100EndInitialized = true
        root.top100EndEdited = false
    }

    function timelineSnapshotTimeText() {
        const seconds = Number(root.timelineSnapshot.time || 0)
        if (!seconds || seconds <= 0) return "date and time unavailable"
        return Qt.formatDateTime(new Date(seconds * 1000), "yyyy-MM-dd hh:mm:ss t")
    }

    function timelineSnapshotHeaderText() {
        const height = Number(root.timelineSnapshot.height)
        if (isNaN(height) || height < 0) return "No snapshot"
        return "Block " + height + " on date and time " + root.timelineSnapshotTimeText()
    }

    function movementPageRows(rowsPerPage) {
        const perPage = Math.max(1, rowsPerPage)
        const pageCount = movementPageCount(perPage)
        const page = Math.max(0, Math.min(root.movementPage, pageCount - 1))
        const start = page * perPage
        return NuService.explorerMovements.slice(start, start + perPage)
    }

    function movementShowingText(rowsPerPage) {
        const total = NuService.explorerMovements.length
        if (total === 0) return "No movement rows loaded."
        const perPage = Math.max(1, rowsPerPage)
        const page = Math.max(0, Math.min(root.movementPage, movementPageCount(perPage) - 1))
        const first = page * perPage + 1
        const last = Math.min(total, first + perPage - 1)
        return "Showing " + first + " to " + last + " of " + total + " movements. Rows per page: " + perPage + "."
    }

    function setMovementPageFromField(rowsPerPage) {
        const requested = parseInt(movementPageField.text)
        if (isNaN(requested)) {
            movementPageField.text = String(root.movementPage + 1)
            return
        }
        root.movementPage = Math.max(0, Math.min(movementPageCount(rowsPerPage) - 1, requested - 1))
        movementPageField.text = String(root.movementPage + 1)
    }

    function refreshAnalytics() {
        root.movementPage = 0
        NuService.refreshExplorerAnalytics(root.movementThresholdCoins())
    }

    function openRow(row) {
        const meta = row && row.meta ? row.meta : {}
        const type = String(meta.type || "")
        const id = String(meta.id || "")
        if (type === "transaction") NuService.openTransactionInExplorer(id)
        else if (type === "address") NuService.openAddressInExplorer(id)
        else if (type === "block") NuService.openBlockInExplorer(id)
    }

    function richRowsForPie() {
        return NuService.explorerRichList.slice(0, 10)
    }

    function richTotalSats() {
        let total = 0
        for (let i = 0; i < NuService.explorerRichList.length; ++i)
            total += Number((NuService.explorerRichList[i].meta || {}).balanceSats || 0)
        return total
    }

    function colorForRichRow(row, fallbackIndex) {
        const meta = row && row.meta ? row.meta : {}
        const cells = row && row.cells ? row.cells : []
        const fromRow = meta.color || (cells.length > 0 ? cells[0] : "")
        return String(fromRow || ["#48b7ff", "#f3d447", "#46d39a", "#f05d4f", "#b779ff", "#ff9f43", "#5fe1e8", "#f78fb3", "#9bc53d", "#c8d6e5", "#7f8fa6"][fallbackIndex % 11])
    }

    function richSliceAt(x, y) {
        const rows = richRowsForPie()
        const total = richTotalSats()
        if (rows.length === 0 || total <= 0) return -1
        const cx = richPie.width / 2
        const cy = richPie.height / 2
        const dx = x - cx
        const dy = y - cy
        const distance = Math.sqrt(dx * dx + dy * dy)
        const radius = Math.min(richPie.width, richPie.height) * 0.42
        if (distance < radius * 0.52 || distance > radius * 1.16) return -1
        let angle = Math.atan2(dy, dx)
        if (angle < -Math.PI / 2) angle += Math.PI * 2
        let start = -Math.PI / 2
        for (let i = 0; i < rows.length; ++i) {
            const sats = Number((rows[i].meta || {}).balanceSats || 0)
            const end = start + (Math.PI * 2 * sats / total)
            if (angle >= start && angle <= end) return Number((rows[i].meta || {}).rank || (i + 1))
            start = end
        }
        return 0
    }

    function richHoverText(rank) {
        if (rank < 0) return ""
        if (rank === 0) return "Other indexed addresses outside the first ten visible pie slices."
        for (let i = 0; i < NuService.explorerRichList.length; ++i) {
            const row = NuService.explorerRichList[i]
            const meta = row.meta || {}
            if (Number(meta.rank || 0) === rank) {
                return "Rank " + rank + "\n" + String(meta.address || "") + "\nBalance: " + String(row.cells[3] || "") + "\nShare: " + String(row.cells[4] || "")
            }
        }
        return ""
    }

    function timelineHeightForPosition(position) {
        const start = Math.max(0, NuService.explorerTop100TimelineStartHeight)
        const end = Math.max(start, NuService.explorerTop100TimelineEndHeight)
        return Math.round(start + Math.max(0, Math.min(1, position)) * Math.max(1, end - start))
    }

    function loadTimelineSnapshotAtPosition(position) {
        root.timelineSnapshot = NuService.explorerTop100Snapshot(root.timelineHeightForPosition(position))
        if (timelinePie) timelinePie.requestPaint()
    }

    Component.onCompleted: NuService.refreshExplorerAnalytics(root.movementThresholdCoins())

    onMovementPageChanged: {
        if (movementPageField)
            movementPageField.text = String(root.movementPage + 1)
    }

    Connections {
        target: NuService
        function onExplorerChanged() {
            if (movementTableHost && root.movementPage >= root.movementPageCount(movementTableHost.rowsPerPage))
                root.movementPage = Math.max(0, root.movementPageCount(movementTableHost.rowsPerPage) - 1)
            if (richPie)
                richPie.requestPaint()
            if (timelinePie)
                timelinePie.requestPaint()
        }
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Explorer"
        detail: "Local block, transaction, address, Top 100, and movement lookups backed by a SQLite WAL cache."
    }

    NuPanel {
        id: explorerStatusPanel
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(158, explorerStatusContent.implicitHeight + padding * 2)
        Layout.minimumHeight: Math.max(158, explorerStatusContent.implicitHeight + padding * 2)
        ColumnLayout {
            id: explorerStatusContent
            anchors.fill: parent
            spacing: NuTokens.spaceMd

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceLg

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceXs
                    Label {
                        Layout.fillWidth: true
                        text: "Explorer index status"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    Basic.TextArea {
                        Layout.fillWidth: true
                        text: NuService.explorerIndexStatus
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        background: Item {}
                        padding: 0
                    }
                    Basic.TextArea {
                        Layout.fillWidth: true
                        text: NuService.explorerAnalyticsStatus
                        color: NuTokens.textMuted
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        background: Item {}
                        padding: 0
                    }
                }

                NuActionButton {
                    Layout.preferredWidth: 148
                    Layout.alignment: Qt.AlignTop
                    text: "Refresh stats"
                    helpText: "Reload Top 100 and movement summaries from the local SQLite explorer index."
                    onClicked: root.refreshAnalytics()
                }
            }

            Basic.ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                from: 0
                to: 1
                value: root.indexProgress
                indeterminate: NuService.explorerIndexing && NuService.explorerIndexTip <= 0
            }

            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                spacing: NuTokens.spaceLg
                NuMetricRow { label: "Index"; value: root.indexPercentText() }
                NuMetricRow { label: "Next block"; value: String(NuService.explorerIndexHeight) }
                NuMetricRow { label: "Tip"; value: String(NuService.explorerIndexTip) }
                NuMetricRow { label: "Blocks"; value: String(NuService.explorerIndexedBlockCount) }
                NuMetricRow { label: "Outputs"; value: String(NuService.explorerIndexedOutputCount) }
                NuMetricRow { label: "Top 100"; value: String(NuService.explorerRichList.length) }
                NuMetricRow { label: "Top 100 events"; value: String(NuService.explorerTop100TimelineEventCount) }
                NuMetricRow { label: "Movements"; value: String(NuService.explorerMovements.length) }
            }
        }
    }

    NuTabBar {
        id: explorerTabs
        Layout.fillWidth: true
        NuTabButton { text: "Search" }
        NuTabButton { text: "Index" }
        NuTabButton { text: "Top 100" }
        NuTabButton { text: "Movements" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        currentIndex: explorerTabs.currentIndex

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Search blockchain"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "Open block heights, block hashes, transaction IDs, or Defcoin wallet addresses. Nu checks the local SQLite explorer cache first, then asks the connected backend when needed."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    NuTextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        font.pixelSize: NuTokens.fontBodyLarge
                        topPadding: NuTokens.spaceMd
                        bottomPadding: NuTokens.spaceMd
                        placeholderText: "Block height, block hash, transaction ID, or address"
                        helpText: "Search block heights, 64-character block or transaction hashes, and supported Defcoin Base58 address forms."
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                NuService.searchExplorer(searchField.text)
                                event.accepted = true
                            }
                        }
                    }

                    NuActionButton {
                        text: "Search"
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 56
                        primary: true
                        helpText: "Open the matching item in an independent internal explorer window."
                        onClicked: NuService.searchExplorer(searchField.text)
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "internalExplorerRecent"
                    columns: ["Type", "Identifier", "Title", "Cached"]
                    columnTypes: ["text", "hash", "text", "date"]
                    columnWeights: [0.7, 2.7, 1.1, 1.2]
                    rows: NuService.explorerRecentLookups
                    emptyText: "No internal explorer lookups cached yet. Search above or open an explorer link from Wallet, Transactions, or Addresses."
                    defaultSortColumn: 3
                    defaultSortAscending: false
                    onRowActivated: (row) => root.openRow(row)
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Background index"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "The indexer is throttled and resumable. It stores public block summaries, transaction IDs, and standard address outputs in the local SQLite WAL explorer cache so internal lookups can work without exposing wallet-private data."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    NuActionButton {
                        text: NuService.explorerIndexing ? "Indexing" : "Start / Resume"
                        width: 150
                        enabled: !NuService.explorerIndexing
                        primary: !NuService.explorerIndexing
                        helpText: "Build or resume the local block, transaction-ID, and standard address-output index from the connected backend."
                        onClicked: NuService.startExplorerIndexing()
                    }

                    NuActionButton {
                        text: "Pause"
                        width: 110
                        enabled: NuService.explorerIndexing
                        helpText: "Pause indexing after the current RPC request completes. Progress is kept in SQLite."
                        onClicked: NuService.stopExplorerIndexing()
                    }

                    NuActionButton {
                        text: "Reset index"
                        width: 130
                        enabled: !NuService.explorerIndexing
                        danger: true
                        helpText: "Clear only the block, transaction, Top 100, and movement index. Recent manual lookups are kept."
                        onClicked: NuService.resetExplorerIndex()
                    }

                    NuActionButton {
                        text: "Reload recent"
                        width: 150
                        helpText: "Refresh the list of recent explorer lookups cached in SQLite."
                        onClicked: NuService.refreshExplorerRecentLookups()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: NuTokens.lineSubtle
                }

                Label {
                    Layout.fillWidth: true
                    text: "Top 100 timeline index"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Basic.TextArea {
                    Layout.fillWidth: true
                    text: NuService.explorerTop100Status
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    background: Item {}
                    padding: 0
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    Label {
                        text: "Start"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    NuTextField {
                        id: top100StartField
                        width: 110
                        text: "0"
                        validator: IntValidator { bottom: 0; top: 99999999 }
                        helpText: "First block height to include when rebuilding the sparse Top 100 over-time index."
                    }
                    Label {
                        text: "Stop"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    NuTextField {
                        id: top100EndField
                        width: 120
                        text: ""
                        validator: IntValidator { bottom: 0; top: 99999999 }
                        helpText: "Last block height to include. Leave this at the indexed tip for a full current timeline."
                        onTextEdited: root.top100EndEdited = true
                        Component.onCompleted: root.initializeTop100EndField(false)
                    }
                    NuActionButton {
                        width: 132
                        text: NuService.explorerTop100Scanning ? "Scanning" : "Start scan"
                        enabled: !NuService.explorerTop100Scanning && !NuService.explorerIndexing
                        primary: enabled
                        helpText: "Build the exact sparse Top 100 timeline from local balance deltas."
                        onClicked: NuService.startExplorerTop100Timeline(parseInt(top100StartField.text) || 0,
                                                                          top100EndField.text.length > 0 ? parseInt(top100EndField.text) : NuService.explorerIndexTip)
                    }
                    NuActionButton {
                        width: 112
                        text: "Pause scan"
                        enabled: NuService.explorerTop100Scanning
                        helpText: "Pause the Top 100 timeline scan after the current chunk."
                        onClicked: NuService.stopExplorerTop100Timeline()
                    }
                    NuActionButton {
                        width: 152
                        text: "Scan remaining"
                        enabled: !NuService.explorerTop100Scanning && !NuService.explorerIndexing
                        helpText: "Scan the next missing Top 100 timeline range between block 0 and the indexed tip."
                        onClicked: NuService.scanRemainingExplorerTop100Timeline()
                    }
                    NuActionButton {
                        width: 138
                        text: "Clear timeline"
                        enabled: !NuService.explorerTop100Scanning && !NuService.explorerIndexing
                        danger: true
                        helpText: "Delete only the sparse Top 100 over-time events and ranges."
                        onClicked: NuService.resetExplorerTop100Timeline()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Index database: " + NuService.explorerDatabasePath
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    elide: Text.ElideMiddle
                }

                Item { Layout.fillHeight: true }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg

                    Canvas {
                        id: richPie
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 220
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const rows = root.richRowsForPie()
                            const total = root.richTotalSats()
                            const cx = width / 2
                            const cy = height / 2
                            const radius = Math.min(width, height) * 0.42
                            if (rows.length === 0 || total <= 0) {
                                ctx.strokeStyle = NuTokens.lineSubtle
                                ctx.lineWidth = 2
                                ctx.beginPath()
                                ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                                ctx.stroke()
                                ctx.fillStyle = NuTokens.textSecondary
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.font = "12px " + NuTokens.bodyFont
                                ctx.fillText("Build index", cx, cy)
                                return
                            }
                            let used = 0
                            let start = -Math.PI / 2
                            for (let s = 0; s < rows.length; ++s) {
                                const sats = Number((rows[s].meta || {}).balanceSats || 0)
                                const rank = Number((rows[s].meta || {}).rank || (s + 1))
                                used += sats
                                const end = start + (Math.PI * 2 * sats / total)
                                const selected = root.selectedRichRank === rank
                                const mid = (start + end) / 2
                                const offset = selected ? 10 : 0
                                const sx = cx + Math.cos(mid) * offset
                                const sy = cy + Math.sin(mid) * offset
                                ctx.beginPath()
                                ctx.moveTo(sx, sy)
                                ctx.arc(sx, sy, radius, start, end)
                                ctx.closePath()
                                ctx.fillStyle = root.colorForRichRow(rows[s], s)
                                ctx.fill()
                                start = end
                            }
                            if (used < total) {
                                ctx.beginPath()
                                ctx.moveTo(cx, cy)
                                ctx.arc(cx, cy, radius, start, Math.PI * 1.5)
                                ctx.closePath()
                                ctx.fillStyle = "#7f8fa6"
                                ctx.fill()
                            }
                            ctx.beginPath()
                            ctx.arc(cx, cy, radius * 0.52, 0, Math.PI * 2)
                            ctx.fillStyle = NuTokens.panelBase
                            ctx.fill()
                            ctx.fillStyle = NuTokens.textPrimary
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.font = "700 14px " + NuTokens.bodyFont
                            ctx.fillText("Top 100", cx, cy - 8)
                            ctx.font = "11px " + NuTokens.bodyFont
                            ctx.fillStyle = NuTokens.textSecondary
                            ctx.fillText("indexed balances", cx, cy + 10)
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            ToolTip.visible: containsMouse && root.richHoverText(root.hoveredRichRank).length > 0
                            ToolTip.text: root.richHoverText(root.hoveredRichRank)
                            ToolTip.delay: NuTokens.tooltipDelay
                            ToolTip.timeout: NuTokens.tooltipTimeout
                            onPositionChanged: (mouse) => {
                                root.hoveredRichRank = root.richSliceAt(mouse.x, mouse.y)
                            }
                            onExited: root.hoveredRichRank = -1
                            onClicked: (mouse) => {
                                const rank = root.richSliceAt(mouse.x, mouse.y)
                                root.selectedRichRank = root.selectedRichRank === rank ? -1 : rank
                                richPie.requestPaint()
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm
                        Label {
                            Layout.fillWidth: true
                            text: "Top 100 Address Balance Holders"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Ranked by unspent balance in the local explorer index. This view is complete only through the indexed block height shown above."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceMd
                            NuActionButton {
                                width: 150
                                text: "Refresh Top 100"
                                helpText: "Recalculate Top 100 and movement summaries from the local SQLite explorer index."
                                onClicked: root.refreshAnalytics()
                            }
                            NuActionButton {
                                width: 118
                                text: "Timeline"
                                enabled: NuService.explorerTop100TimelineEventCount > 0
                                helpText: "Open the sparse Top 100 over-time animation window."
                                onClicked: {
                                    root.loadTimelineSnapshotAtPosition(1)
                                    top100TimelineWindow.showFullScreen()
                                    top100TimelineWindow.raise()
                                    top100TimelineWindow.requestActivate()
                                }
                            }
                            NuMetricRow { label: "Rows"; value: String(NuService.explorerRichList.length) }
                            NuMetricRow { label: "Coverage"; value: NuService.explorerIndexedBlockCount + " blocks" }
                            NuMetricRow { label: "Timeline"; value: NuService.explorerTop100TimelineEventCount + " events" }
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "internalExplorerRichList"
                    columns: ["", "Rank", "Address", "Balance", "Share", "Received", "Txs", "UTXOs"]
                    columnTypes: ["swatch", "number", "address", "amount", "number", "amount", "number", "number"]
                    columnWeights: [0.25, 0.45, 3.1, 1.1, 0.75, 1.1, 0.55, 0.55]
                    rows: NuService.explorerRichList
                    emptyText: "Top 100 appears after the Explorer index contains spendable outputs."
                    defaultSortColumn: 1
                    rowSelectionEnabled: true
                    plainClickSelectsRows: true
                    rowKeyMetaField: "rank"
                    onRowSelectionChanged: (keys) => {
                        root.selectedRichRank = keys.length > 0 ? Number(keys[0]) : -1
                        richPie.requestPaint()
                    }
                    onRowActivated: (row) => root.openRow(row)
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceXs
                        Label {
                            Layout.fillWidth: true
                            text: "Movements"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Large non-coinbase transactions grouped by indexed transaction outputs. Adjust the DFC threshold, then refresh."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    Label { text: "Min DFC"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: movementThreshold
                        Layout.preferredWidth: 130
                        text: "5000"
                        placeholderText: "5000"
                        validator: IntValidator { bottom: 0; top: 1000000000 }
                        helpText: "Minimum transaction output total to include in movement rows."
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.refreshAnalytics()
                                event.accepted = true
                            }
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: "Refresh"
                        primary: true
                        helpText: "Reload movement rows using the selected DFC threshold."
                        onClicked: root.refreshAnalytics()
                    }
                }

                Item {
                    id: movementTableHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property int rowsPerPage: Math.max(5, Math.floor((height - 84) / 36))

                    NuDataTable {
                        anchors.fill: parent
                        tableId: "internalExplorerMovements"
                        columns: ["Tx Hash", "Amount", "Timestamp", "Height", "Outputs", "Addresses"]
                        columnTypes: ["hash", "amount", "date", "number", "number", "number"]
                        columnWeights: [3.6, 1.1, 1.4, 0.75, 0.65, 0.75]
                        rows: root.movementPageRows(movementTableHost.rowsPerPage)
                        emptyText: "Large movements appear after the Explorer index contains non-coinbase transactions above the selected threshold."
                        defaultSortColumn: 2
                        defaultSortAscending: false
                        onRowActivated: (row) => root.openRow(row)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm
                    Label {
                        Layout.fillWidth: true
                        text: root.movementShowingText(movementTableHost.rowsPerPage)
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        elide: Text.ElideRight
                    }
                    NuActionButton {
                        Layout.preferredWidth: 52
                        text: "<"
                        enabled: root.movementPage > 0
                        helpText: "Previous movement page."
                        onClicked: root.movementPage = Math.max(0, root.movementPage - 1)
                    }
                    Label { text: "Page"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: movementPageField
                        Layout.preferredWidth: 64
                        text: "1"
                        validator: IntValidator { bottom: 1; top: 999999 }
                        helpText: "Enter a movement page number."
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.setMovementPageFromField(movementTableHost.rowsPerPage)
                                event.accepted = true
                            }
                        }
                        onEditingFinished: root.setMovementPageFromField(movementTableHost.rowsPerPage)
                    }
                    Label {
                        text: "of " + root.movementPageCount(movementTableHost.rowsPerPage)
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    NuActionButton {
                        Layout.preferredWidth: 52
                        text: ">"
                        enabled: root.movementPage < root.movementPageCount(movementTableHost.rowsPerPage) - 1
                        helpText: "Next movement page."
                        onClicked: root.movementPage = Math.min(root.movementPageCount(movementTableHost.rowsPerPage) - 1, root.movementPage + 1)
                    }
                }
            }
        }
    }

    Timer {
        id: timelinePlayTimer
        interval: 350
        repeat: true
        running: root.timelinePlaying && top100TimelineWindow.visible
        onTriggered: {
            const next = Math.min(1, timelineRange.start + 0.01)
            timelineRange.start = next
            timelineRange.end = Math.min(1, Math.max(next + timelineRange.minSpan, timelineRange.end + 0.01))
            root.loadTimelineSnapshotAtPosition(timelineRange.start)
            if (next >= 1) root.timelinePlaying = false
        }
    }

    Item {
        Layout.preferredWidth: 0
        Layout.preferredHeight: 0
        visible: false

        Window {
            id: top100TimelineWindow
            width: 1040
            height: 760
            minimumWidth: 760
            minimumHeight: 560
            visible: false
            title: "Top 100 Timeline"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceSm

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceSm
                Label {
                    Layout.fillWidth: true
                    text: "Top 100 Timeline"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.maximumWidth: Math.max(240, top100TimelineWindow.width * 0.46)
                    text: root.timelineSnapshotHeaderText()
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }
                NuActionButton {
                    Layout.preferredWidth: 94
                    text: root.timelinePlaying ? "Pause" : "Play"
                    helpText: "Animate the pie chart forward through sparse Top 100 timeline events."
                    onClicked: root.timelinePlaying = !root.timelinePlaying
                }
            }

            Canvas {
                id: timelinePie
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(340, top100TimelineWindow.width - 80)
                Layout.preferredHeight: Layout.preferredWidth
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const rows = root.timelineSnapshot.rows || []
                    const cx = width / 2
                    const cy = height / 2
                    const radius = Math.min(width, height) * 0.43
                    let totalPct = 0
                    for (let i = 0; i < rows.length; ++i)
                        totalPct += Math.max(0, parseInt(String(rows[i].cells[3]).replace("%", "")) || 0)
                    if (rows.length === 0 || totalPct <= 0) {
                        ctx.strokeStyle = NuTokens.lineSubtle
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                        ctx.stroke()
                        ctx.fillStyle = NuTokens.textSecondary
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.font = "13px " + NuTokens.bodyFont
                        ctx.fillText("Build Top 100 timeline", cx, cy)
                        return
                    }
                    let start = -Math.PI / 2
                    for (let r = 0; r < rows.length; ++r) {
                        const pct = Math.max(0, parseInt(String(rows[r].cells[3]).replace("%", "")) || 0)
                        if (pct <= 0) continue
                        const rank = Number(rows[r].cells[1] || (r + 1))
                        const selected = root.selectedRichRank === rank
                        const end = start + Math.PI * 2 * pct / Math.max(100, totalPct)
                        const mid = (start + end) / 2
                        const offset = selected ? 12 : 0
                        const sx = cx + Math.cos(mid) * offset
                        const sy = cy + Math.sin(mid) * offset
                        ctx.beginPath()
                        ctx.moveTo(sx, sy)
                        ctx.arc(sx, sy, radius, start, end)
                        ctx.closePath()
                        ctx.fillStyle = String(rows[r].cells[0] || "#7f8fa6")
                        ctx.fill()
                        start = end
                    }
                    if (start < Math.PI * 1.5) {
                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.arc(cx, cy, radius, start, Math.PI * 1.5)
                        ctx.closePath()
                        ctx.fillStyle = "#2f3640"
                        ctx.fill()
                    }
                    ctx.beginPath()
                    ctx.arc(cx, cy, radius * 0.52, 0, Math.PI * 2)
                    ctx.fillStyle = NuTokens.panelBase
                    ctx.fill()
                    ctx.fillStyle = NuTokens.textPrimary
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.font = "700 15px " + NuTokens.bodyFont
                    ctx.fillText("Top 100", cx, cy - 8)
                    ctx.font = "12px " + NuTokens.bodyFont
                    ctx.fillStyle = NuTokens.textSecondary
                    ctx.fillText("whole-percent history", cx, cy + 12)
                }
            }

            NuTimelineWindow {
                id: timelineRange
                Layout.fillWidth: true
                label: "Block range"
                start: 0
                end: 1
                minSpan: 0.01
                onViewportChanged: (s, e) => root.loadTimelineSnapshotAtPosition(s)
            }

            Label {
                Layout.fillWidth: true
                text: root.timelineSnapshot.status || ""
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            NuDataTable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                tableId: "internalExplorerTop100Timeline"
                columns: ["", "Rank", "Address", "Share"]
                columnTypes: ["swatch", "number", "address", "number"]
                columnWeights: [0.25, 0.4, 3.2, 0.65]
                rows: root.timelineSnapshot.rows || []
                emptyText: "No Top 100 timeline snapshot loaded."
                defaultSortColumn: 1
                rowSelectionEnabled: true
                plainClickSelectsRows: true
                rowKeyMetaField: "rank"
                onRowSelectionChanged: (keys) => {
                    root.selectedRichRank = keys.length > 0 ? Number(keys[0]) : -1
                    timelinePie.requestPaint()
                }
                onRowActivated: (row) => root.openRow(row)
            }
        }

            onVisibleChanged: {
                if (!visible) root.timelinePlaying = false
            }
        }
    }
}
