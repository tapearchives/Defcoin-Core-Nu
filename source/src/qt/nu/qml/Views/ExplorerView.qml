import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg

    property int movementPage: 0
    readonly property real indexProgress: NuService.explorerIndexTip > 0
                                          ? Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
                                          : 0

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
                    Label {
                        Layout.fillWidth: true
                        text: NuService.explorerIndexStatus + " " + NuService.explorerAnalyticsStatus
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
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
                            const colors = ["#48b7ff", "#f3d447", "#46d39a", "#f05d4f", "#b779ff", "#ff9f43", "#5fe1e8", "#f78fb3", "#9bc53d", "#c8d6e5", "#6c7a89"]
                            const rows = NuService.explorerRichList.slice(0, 10)
                            let total = 0
                            for (let i = 0; i < NuService.explorerRichList.length; ++i)
                                total += Number((NuService.explorerRichList[i].meta || {}).balanceSats || 0)
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
                                used += sats
                                const end = start + (Math.PI * 2 * sats / total)
                                ctx.beginPath()
                                ctx.moveTo(cx, cy)
                                ctx.arc(cx, cy, radius, start, end)
                                ctx.closePath()
                                ctx.fillStyle = colors[s % colors.length]
                                ctx.fill()
                                start = end
                            }
                            if (used < total) {
                                ctx.beginPath()
                                ctx.moveTo(cx, cy)
                                ctx.arc(cx, cy, radius, start, Math.PI * 1.5)
                                ctx.closePath()
                                ctx.fillStyle = colors[10]
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
                            NuMetricRow { label: "Rows"; value: String(NuService.explorerRichList.length) }
                            NuMetricRow { label: "Coverage"; value: NuService.explorerIndexedBlockCount + " blocks" }
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "internalExplorerRichList"
                    columns: ["Rank", "Address", "Balance", "Share", "Received", "Txs", "UTXOs"]
                    columnTypes: ["number", "address", "amount", "number", "amount", "number", "number"]
                    columnWeights: [0.45, 3.1, 1.1, 0.75, 1.1, 0.55, 0.55]
                    rows: NuService.explorerRichList
                    emptyText: "Top 100 appears after the Explorer index contains spendable outputs."
                    defaultSortColumn: 0
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
}
