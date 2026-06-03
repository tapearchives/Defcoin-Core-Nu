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
    property string selectedWealthGroup: ""
    property string selectedWhaleGroup: ""
    property bool active: false
    property int preferredTab: 0
    property string sectionTitle: "Explorer"
    property string sectionDetail: "Local block, transaction, address, Holder Atlas, and movement lookups backed by a SQLite WAL cache."
    property string mastSearchText: ""
    property int mastSearchNonce: 0
    property string explorerResultTitle: ""
    property string explorerResultHtml: ""
    property int explorerResultNonce: 0
    property bool analyticsRequested: false
    property bool summaryRequested: false
    property bool coindroidsRequested: false
    property int hoveredCoindroidsWindowIndex: -1
    property int hoveredCoindroidsAttackIndex: -1
    property int selectedCoindroidsWindowIndex: -1
    property bool coindroidsWindowZoomed: false
    property int coindroidsDetailTab: 0
    property bool defcoinTimelineRequested: false
    property bool networkPulseRequested: false
    property string networkPulseMetric: "Hashrate"
    property int networkPulseWindowBlocks: 120
    property int hoveredNetworkPulseIndex: -1
    property var timelineSnapshot: ({ rows: [], height: -1, status: "No holder timeline snapshot loaded." })
    property bool timelinePlaying: false
    property bool top100EndInitialized: false
    property bool top100EndEdited: false
    property bool top100UpdatingEndField: false
    property string selectedContactSetName: ""
    property int selectedContactIndex: -1
    property string selectedContactName: ""
    property var contactGraphPositions: ({})
    property string contactGraphSignature: ""
    property string hoveredContactName: ""
    property string draggingContactName: ""
    property real contactDragLastX: 0
    property real contactDragLastY: 0
    property bool contactDragMoved: false
    property int movementGraphLimit: 15
    property string movementGraphSortMode: "Largest"
    property real movementNodeScale: 0.95
    property var movementNodePositions: ({})
    property var movementNodeVelocities: ({})
    property string movementGraphSignature: ""
    property var movementGraphStates: ({})
    property string hoveredMovementAddress: ""
    property string draggingMovementAddress: ""
    property real movementDragLastX: 0
    property real movementDragLastY: 0
    property bool movementDragMoved: false
    readonly property real indexProgress: NuService.explorerIndexTip > 0
                                          ? Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
                                          : (NuService.explorerIndexedBlockCount > 0 ? 1 : 0)

    Connections {
        target: NuService
        function onExplorerChanged() {
            if (!top100EndField || root.top100EndEdited || NuService.explorerIndexTip <= 0) return
            if (!root.top100EndInitialized || top100EndField.text.length === 0)
                root.initializeTop100EndField(true)
        }
    }

    function applyPreferredTab() {
        if (explorerTabs)
            explorerTabs.currentIndex = Math.max(0, Math.min(6, root.preferredTab))
    }

    function applyMastSearchText() {
        if (!searchField || root.mastSearchText.length === 0) return
        explorerTabs.currentIndex = 0
        searchField.text = root.mastSearchText
    }

    function applyExplorerResult() {
        if (!explorerTabs || root.explorerResultHtml.length === 0) return
        explorerTabs.currentIndex = 0
    }

    function contentIndexForTab(tabIndex) {
        if (tabIndex === 1) return 3
        if (tabIndex === 2) return 4
        if (tabIndex === 3) return 1
        if (tabIndex === 4) return 2
        if (tabIndex === 5) return 6
        if (tabIndex === 6) return 7
        return 0
    }

    Component.onCompleted: Qt.callLater(function() {
        root.applyPreferredTab()
        root.applyMastSearchText()
        root.applyExplorerResult()
        root.maybeRefreshAnalyticsForTab()
    })

    onPreferredTabChanged: if (root.active) root.applyPreferredTab()
    onMastSearchNonceChanged: Qt.callLater(root.applyMastSearchText)
    onExplorerResultNonceChanged: Qt.callLater(root.applyExplorerResult)

    function indexPercentText() {
        if (NuService.explorerIndexTip <= 0)
            return NuService.explorerIndexedBlockCount > 0 ? "Cached" : "Not built"
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
        if (tip <= 0 && !force) return
        root.top100UpdatingEndField = true
        top100EndField.text = String(tip)
        root.top100UpdatingEndField = false
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
        if (total === 0) return "No movement outputs loaded."
        const perPage = Math.max(1, rowsPerPage)
        const page = Math.max(0, Math.min(root.movementPage, movementPageCount(perPage) - 1))
        const first = page * perPage + 1
        const last = Math.min(total, first + perPage - 1)
        return "Showing " + first + " to " + last + " of " + total + " movement outputs. Rows per page: " + perPage + "."
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

    function refreshAnalytics(scope) {
        root.movementPage = 0
        root.analyticsRequested = true
        NuService.refreshExplorerAnalytics(root.movementThresholdCoins(), scope || "all")
    }

    function refreshCoindroids() {
        root.coindroidsRequested = true
        NuService.refreshCoindroidsAnalytics()
    }

    function refreshDefcoinTimeline() {
        root.defcoinTimelineRequested = true
        NuService.refreshDefcoinTimeline()
    }

    function refreshNetworkPulse() {
        root.networkPulseRequested = true
        NuService.refreshNetworkPulseHistory(root.networkPulseWindowBlocks)
    }

    function maybeRefreshAnalyticsForTab() {
        if (!root.active || !explorerTabs) return
        if (explorerTabs.currentIndex === 1 && !root.analyticsRequested)
            root.refreshAnalytics("rich")
        else if (explorerTabs.currentIndex === 2 && !root.analyticsRequested)
            root.refreshAnalytics("movements")
        else if (explorerTabs.currentIndex === 3 && !root.coindroidsRequested)
            root.refreshCoindroids()
        else if (explorerTabs.currentIndex === 5 && !root.defcoinTimelineRequested)
            root.refreshDefcoinTimeline()
        else if (explorerTabs.currentIndex === 6 && !root.networkPulseRequested)
            root.refreshNetworkPulse()
    }

    function openRow(row) {
        const meta = row && row.meta ? row.meta : {}
        const type = String(meta.type || "")
        const id = String(meta.id || "")
        if (type === "transaction") NuService.openTransactionInExplorer(id)
        else if (type === "address") NuService.openAddressInExplorer(id)
        else if (type === "block") NuService.openBlockInExplorer(id)
    }

    function openTimelineRow(row) {
        const meta = row && row.meta ? row.meta : {}
        const url = String(meta.url || "")
        if (url.length > 0)
            NuService.openExplorerLink(url)
    }

    function networkPulseRows() {
        return NuService.networkPulseHistoryRows || []
    }

    function networkPulseSummaryValue(key, fallbackValue) {
        const value = (NuService.networkPulseSummary || {})[key]
        if (value === undefined || value === null || String(value).length === 0)
            return fallbackValue === undefined ? "-" : fallbackValue
        return value
    }

    function networkPulseText(key, fallbackText) {
        return String(root.networkPulseSummaryValue(key, fallbackText || "-"))
    }

    function networkPulseNumber(key) {
        return Number(root.networkPulseSummaryValue(key, 0)).toLocaleString(Qt.locale(), "f", 0)
    }

    function networkPulseMetricValue(row) {
        const meta = row && row.meta ? row.meta : {}
        if (root.networkPulseMetric === "Difficulty")
            return Number(meta.difficulty || 0)
        if (root.networkPulseMetric === "Block time")
            return Number(meta.avgSpacingSeconds || 0)
        return Number(meta.hashrate || 0)
    }

    function networkPulseMetricColor() {
        if (root.networkPulseMetric === "Difficulty") return "#f3d447"
        if (root.networkPulseMetric === "Block time") return "#46d39a"
        return "#48b7ff"
    }

    function networkPulseHashrateText(value) {
        const units = ["H/s", "KH/s", "MH/s", "GH/s", "TH/s", "PH/s"]
        let amount = Number(value || 0)
        if (!isFinite(amount) || amount <= 0) return "-"
        let unit = 0
        while (amount >= 1000 && unit + 1 < units.length) {
            amount /= 1000
            unit += 1
        }
        return amount.toLocaleString(Qt.locale(), "f", amount >= 100 ? 0 : 2) + " " + units[unit]
    }

    function networkPulseDurationText(seconds) {
        const value = Number(seconds || 0)
        if (!isFinite(value) || value <= 0) return "-"
        if (value < 90) return value.toLocaleString(Qt.locale(), "f", value < 10 ? 1 : 0) + "s"
        const minutes = value / 60.0
        if (minutes < 120) return minutes.toLocaleString(Qt.locale(), "f", minutes < 10 ? 1 : 0) + "m"
        const hours = minutes / 60.0
        return hours.toLocaleString(Qt.locale(), "f", hours < 10 ? 1 : 0) + "h"
    }

    function networkPulseDifficultyText(value) {
        const amount = Number(value || 0)
        if (!isFinite(amount) || amount <= 0) return "-"
        return amount.toLocaleString(Qt.locale(), "f", amount >= 100 ? 2 : 8).replace(/0+$/, "").replace(/\.$/, "")
    }

    function networkPulseValueText(value) {
        if (root.networkPulseMetric === "Hashrate")
            return root.networkPulseHashrateText(value)
        if (root.networkPulseMetric === "Block time")
            return root.networkPulseDurationText(value)
        return root.networkPulseDifficultyText(value)
    }

    function networkPulsePlot(canvasWidth, canvasHeight) {
        const left = canvasWidth < 760 ? 66 : 82
        const right = 24
        const top = 22
        const bottom = 46
        return {
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            width: Math.max(1, canvasWidth - left - right),
            height: Math.max(1, canvasHeight - top - bottom)
        }
    }

    function networkPulseIndexAt(mouseX, mouseY, canvasWidth, canvasHeight) {
        const rows = root.networkPulseRows()
        if (rows.length === 0) return -1
        const plot = root.networkPulsePlot(canvasWidth, canvasHeight)
        if (mouseX < plot.left || mouseX > plot.left + plot.width || mouseY < plot.top || mouseY > plot.top + plot.height)
            return -1
        const ratio = Math.max(0, Math.min(1, (mouseX - plot.left) / plot.width))
        return Math.max(0, Math.min(rows.length - 1, Math.round(ratio * (rows.length - 1))))
    }

    function networkPulseHoverText(index) {
        const rows = root.networkPulseRows()
        if (index < 0 || index >= rows.length) return ""
        const row = rows[index]
        const meta = row.meta || {}
        const cells = row.cells || []
        return "Block " + String(meta.height || cells[0] || "")
            + "\nDate: " + String(cells[1] || "")
            + "\n" + root.networkPulseMetric + ": " + root.networkPulseValueText(root.networkPulseMetricValue(row))
            + "\nAvg block: " + root.networkPulseDurationText(meta.avgSpacingSeconds)
            + "\nDifficulty: " + root.networkPulseDifficultyText(meta.difficulty)
            + "\nHashrate: " + root.networkPulseHashrateText(meta.hashrate)
            + "\nSpan: " + String(cells[5] || "") + "; click table rows to open blocks."
    }

    function drawNetworkPulseChart(ctx, canvasWidth, canvasHeight) {
        ctx.reset()
        ctx.clearRect(0, 0, canvasWidth, canvasHeight)
        const rows = root.networkPulseRows()
        ctx.fillStyle = NuTokens.panelBase
        ctx.fillRect(0, 0, canvasWidth, canvasHeight)
        const plot = root.networkPulsePlot(canvasWidth, canvasHeight)
        ctx.strokeStyle = NuTokens.lineSubtle
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.rect(plot.left, plot.top, plot.width, plot.height)
        ctx.stroke()
        if (rows.length < 2) {
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "600 15px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText("Index more blocks or press Refresh to load Network Pulse history.", canvasWidth / 2, canvasHeight / 2)
            return
        }
        let minValue = Number.POSITIVE_INFINITY
        let maxValue = 0
        let values = []
        for (let i = 0; i < rows.length; ++i) {
            const value = root.networkPulseMetricValue(rows[i])
            values.push(value)
            if (value > 0) {
                minValue = Math.min(minValue, value)
                maxValue = Math.max(maxValue, value)
            }
        }
        if (!isFinite(minValue) || minValue === Number.POSITIVE_INFINITY) minValue = 0
        if (!isFinite(maxValue) || maxValue <= minValue) maxValue = minValue + 1
        const padding = (maxValue - minValue) * 0.08
        minValue = Math.max(0, minValue - padding)
        maxValue += padding
        ctx.font = "11px " + NuTokens.bodyFont
        ctx.textAlign = "right"
        ctx.textBaseline = "middle"
        for (let g = 0; g <= 4; ++g) {
            const y = plot.top + plot.height * g / 4
            const value = maxValue - (maxValue - minValue) * g / 4
            ctx.strokeStyle = g === 4 ? NuTokens.lineSubtle : "#e8edf5"
            ctx.beginPath()
            ctx.moveTo(plot.left, y)
            ctx.lineTo(plot.left + plot.width, y)
            ctx.stroke()
            ctx.fillStyle = NuTokens.textMuted
            ctx.fillText(root.networkPulseValueText(value), plot.left - 8, y)
        }
        const color = root.networkPulseMetricColor()
        ctx.beginPath()
        for (let p = 0; p < values.length; ++p) {
            const x = plot.left + plot.width * p / Math.max(1, values.length - 1)
            const y = plot.top + plot.height - ((values[p] - minValue) / Math.max(1e-9, maxValue - minValue)) * plot.height
            if (p === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
        }
        ctx.strokeStyle = color
        ctx.lineWidth = 3
        ctx.stroke()
        ctx.lineTo(plot.left + plot.width, plot.top + plot.height)
        ctx.lineTo(plot.left, plot.top + plot.height)
        ctx.closePath()
        const fill = ctx.createLinearGradient(0, plot.top, 0, plot.top + plot.height)
        fill.addColorStop(0, color + "55")
        fill.addColorStop(1, color + "08")
        ctx.fillStyle = fill
        ctx.fill()
        ctx.fillStyle = NuTokens.textSecondary
        ctx.textAlign = "left"
        ctx.textBaseline = "top"
        ctx.font = "700 12px " + NuTokens.bodyFont
        ctx.fillText(root.networkPulseMetric + " history", plot.left, 4)
        const first = rows[0].meta || {}
        const last = rows[rows.length - 1].meta || {}
        ctx.textBaseline = "alphabetic"
        ctx.font = "11px " + NuTokens.bodyFont
        ctx.fillStyle = NuTokens.textMuted
        ctx.textAlign = "left"
        ctx.fillText("Block " + String(first.height || ""), plot.left, canvasHeight - 10)
        ctx.textAlign = "right"
        ctx.fillText("Block " + String(last.height || ""), plot.left + plot.width, canvasHeight - 10)
        if (root.hoveredNetworkPulseIndex >= 0 && root.hoveredNetworkPulseIndex < rows.length) {
            const hi = root.hoveredNetworkPulseIndex
            const xh = plot.left + plot.width * hi / Math.max(1, rows.length - 1)
            const yh = plot.top + plot.height - ((values[hi] - minValue) / Math.max(1e-9, maxValue - minValue)) * plot.height
            ctx.strokeStyle = "#111827"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(xh, plot.top)
            ctx.lineTo(xh, plot.top + plot.height)
            ctx.stroke()
            ctx.fillStyle = color
            ctx.beginPath()
            ctx.arc(xh, yh, 5, 0, Math.PI * 2)
            ctx.fill()
            ctx.strokeStyle = "#ffffff"
            ctx.lineWidth = 2
            ctx.stroke()
        }
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

    function richSliceAt(x, y, canvasWidth, canvasHeight) {
        const rows = richRowsForPie()
        const total = root.explorerSupplySats()
        if (rows.length === 0 || total <= 0) return -1
        const w = canvasWidth || richPie.width
        const h = canvasHeight || richPie.height
        const cx = w / 2
        const cy = h / 2
        const dx = x - cx
        const dy = y - cy
        const distance = Math.sqrt(dx * dx + dy * dy)
        const radius = Math.min(w, h) * 0.42
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

    function showChartWindow(win) {
        if (!win) return
        win.showMaximized()
        win.raise()
        win.requestActivate()
        if (networkPulsePopoutCanvas)
            networkPulsePopoutCanvas.requestPaint()
    }

    function showRelationshipWindow() {
        NuService.refreshExplorerContactRelationships()
        if (contactGraphCanvas)
            contactGraphCanvas.requestPaint()
        root.showChartWindow(contactGraphWindow)
    }

    function popOutCoindroidsTab() {
        if (root.coindroidsDetailTab === 2)
            root.showChartWindow(coindroidsAttackWindow)
        else if (root.coindroidsDetailTab === 1)
            root.showChartWindow(coindroidsPayoutWindow)
        else
            root.showChartWindow(coindroidsChartWindow)
    }

    function drawRichPie(ctx, canvasWidth, canvasHeight) {
        ctx.reset()
        const rows = root.richRowsForPie()
        const total = root.explorerSupplySats()
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        const radius = Math.min(canvasWidth, canvasHeight) * 0.42
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
            if (selected) {
                const share = total > 0 ? (100 * sats / total) : 0
                ctx.fillStyle = NuTokens.textPrimary
                ctx.font = "700 12px " + NuTokens.bodyFont
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(share.toFixed(2) + "%", sx + Math.cos(mid) * radius * 0.70, sy + Math.sin(mid) * radius * 0.70)
            }
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
        ctx.fillText("Largest", cx, cy - 8)
        ctx.font = "11px " + NuTokens.bodyFont
        ctx.fillStyle = NuTokens.textSecondary
        ctx.fillText("holders", cx, cy + 10)
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

    function formatDfcFromSats(sats) {
        const value = Number(sats || 0) / 100000000.0
        return value.toLocaleString(Qt.locale(), "f", 8) + " DFC"
    }

    function coindroidsNumber(key) {
        return Number((NuService.coindroidsSummary || {})[key] || 0).toLocaleString(Qt.locale(), "f", 0)
    }

    function coindroidsText(key, fallbackText) {
        const value = (NuService.coindroidsSummary || {})[key]
        if (value === undefined || value === null || String(value).length === 0)
            return fallbackText || "Not loaded"
        return String(value)
    }

    function coindroidsWindowRows() {
        return NuService.coindroidsWindowRows || []
    }

    function coindroidsWindowRow(index) {
        const rows = root.coindroidsWindowRows()
        return index >= 0 && index < rows.length ? rows[index] : null
    }

    function coindroidsWindowMeta(index) {
        const row = root.coindroidsWindowRow(index)
        return row && row.meta ? row.meta : ({})
    }

    function coindroidsWindowLabel(index) {
        const meta = root.coindroidsWindowMeta(index)
        return String(meta.label || meta.shortLabel || "Droid Trails window")
    }

    function coindroidsMetricNumber(value) {
        return Number(value || 0).toLocaleString(Qt.locale(), "f", 0)
    }

    function coindroidsDfcFromSats(sats, decimals) {
        const amount = Number(sats || 0) / 100000000.0
        return amount.toLocaleString(Qt.locale(), "f", decimals === undefined ? 2 : decimals) + " DFC"
    }

    function coindroidsDfcSummary(key, decimals) {
        const amount = Number((NuService.coindroidsSummary || {})[key] || 0)
        return amount.toLocaleString(Qt.locale(), "f", decimals === undefined ? 2 : decimals) + " DFC"
    }

    function coindroidsWindowTotal(metaKey) {
        const rows = root.coindroidsWindowRows()
        let total = 0
        for (let i = 0; i < rows.length; ++i) {
            const meta = rows[i].meta || {}
            total += Number(meta[metaKey] || 0)
        }
        return total
    }

    function coindroidsChartEntries() {
        const rows = root.coindroidsWindowRows()
        if (root.coindroidsWindowZoomed
                && root.selectedCoindroidsWindowIndex >= 0
                && root.selectedCoindroidsWindowIndex < rows.length) {
            return [{ row: rows[root.selectedCoindroidsWindowIndex], sourceIndex: root.selectedCoindroidsWindowIndex }]
        }
        let entries = []
        for (let i = 0; i < rows.length; ++i)
            entries.push({ row: rows[i], sourceIndex: i })
        return entries
    }

    function coindroidsChartPlot(canvasWidth, canvasHeight) {
        const top = canvasHeight < 380 ? 82 : 98
        const bottom = canvasHeight < 380 ? 42 : 54
        const left = 62
        const right = 22
        return {
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            width: Math.max(1, canvasWidth - left - right),
            height: Math.max(1, canvasHeight - top - bottom)
        }
    }

    function coindroidsWindowIndexAt(mouseX, mouseY, canvasWidth, canvasHeight) {
        const entries = root.coindroidsChartEntries()
        if (entries.length === 0) return -1
        const plot = root.coindroidsChartPlot(canvasWidth, canvasHeight)
        if (mouseX < plot.left || mouseX > plot.left + plot.width || mouseY < plot.top || mouseY > plot.top + plot.height)
            return -1
        if (root.coindroidsWindowZoomed)
            return root.selectedCoindroidsWindowIndex
        const gap = Math.max(10, Math.min(28, plot.width / Math.max(18, entries.length * 5)))
        const barWidth = Math.max(20, (plot.width - gap * (entries.length + 1)) / Math.max(1, entries.length))
        for (let i = 0; i < entries.length; ++i) {
            const x = plot.left + gap + i * (barWidth + gap)
            if (mouseX >= x && mouseX <= x + barWidth)
                return entries[i].sourceIndex
        }
        return -1
    }

    function coindroidsWindowToolTip(index) {
        const meta = root.coindroidsWindowMeta(index)
        if (!meta || Object.keys(meta).length === 0) return ""
        return String(meta.label || meta.shortLabel || "Droid Trails window")
            + "\nBlocks: " + root.coindroidsMetricNumber(meta.startHeight) + "-" + root.coindroidsMetricNumber(meta.endHeight)
            + "\nDates: " + String(meta.dateRange || "unknown")
            + "\nCandidate outputs: " + root.coindroidsMetricNumber(meta.actionOutputs)
            + "\nTransactions: " + root.coindroidsMetricNumber(meta.actionTransactions)
            + "\nAddresses: " + root.coindroidsMetricNumber(meta.actionAddresses)
            + "\nCandidate DFC: " + root.coindroidsDfcFromSats(meta.actionSats, 2)
            + "\n0.01 DFC action outputs: " + root.coindroidsMetricNumber(meta.exact001Outputs)
            + "\n0.1337 DFC swarm outputs: " + root.coindroidsMetricNumber(meta.exact1337Outputs)
    }

    function coindroidsSelectedDetailText() {
        if (!root.coindroidsWindowZoomed || root.selectedCoindroidsWindowIndex < 0)
            return "Hover a bar for block range, dates, DFC totals, and candidate output detail. Click a bar to zoom into that DEF CON window."
        const meta = root.coindroidsWindowMeta(root.selectedCoindroidsWindowIndex)
        return String(meta.label || "Selected Droid Trails window")
            + " | " + String(meta.dateRange || "dates unavailable")
            + " | " + root.coindroidsDfcFromSats(meta.actionSats, 2)
            + " across " + root.coindroidsMetricNumber(meta.actionOutputs) + " candidate outputs"
    }

    function selectCoindroidsWindow(index) {
        const rows = root.coindroidsWindowRows()
        if (index < 0 || index >= rows.length) return
        root.selectedCoindroidsWindowIndex = index
        root.coindroidsWindowZoomed = true
        root.requestCoindroidsChartRepaint()
    }

    function clearCoindroidsWindowZoom() {
        root.coindroidsWindowZoomed = false
        root.selectedCoindroidsWindowIndex = -1
        root.hoveredCoindroidsWindowIndex = -1
        root.requestCoindroidsChartRepaint()
    }

    function selectCoindroidsWindowFromRow(row) {
        const meta = row && row.meta ? row.meta : ({})
        const wanted = String(meta.shortLabel || meta.label || "")
        if (wanted.length === 0) return
        const rows = root.coindroidsWindowRows()
        for (let i = 0; i < rows.length; ++i) {
            const rowMeta = rows[i].meta || {}
            if (String(rowMeta.shortLabel || rowMeta.label || "") === wanted) {
                root.selectCoindroidsWindow(i)
                return
            }
        }
    }

    function requestCoindroidsChartRepaint() {
        if (coindroidsWindowChart)
            coindroidsWindowChart.requestPaint()
        if (coindroidsChartPopoutCanvas)
            coindroidsChartPopoutCanvas.requestPaint()
        if (coindroidsAttackChart)
            coindroidsAttackChart.requestPaint()
        if (coindroidsAttackPopoutCanvas)
            coindroidsAttackPopoutCanvas.requestPaint()
    }

    function coindroidsAttackRows() {
        return NuService.coindroidsAttackAddressRows || []
    }

    function coindroidsQrLeadRows() {
        const rows = []
        const qrRows = NuService.coindroidsQrSeedRows || []
        for (let i = 0; i < qrRows.length; ++i)
            rows.push(qrRows[i])
        const oloRows = NuService.coindroidsOloRows || []
        for (let j = 0; j < oloRows.length; ++j) {
            const row = oloRows[j] || {}
            const meta = row.meta || {}
            rows.push({
                cells: [
                    "Olo",
                    String(meta.legacyP2sh || (row.cells || [])[1] || ""),
                    String(meta.address || (row.cells || [])[2] || ""),
                    Number(meta.dc25Outputs || (row.cells || [])[3] || 0),
                    String((row.cells || [])[4] || ""),
                    0,
                    "0 DFC",
                    String((row.cells || [])[7] || ""),
                    String((row.cells || [])[8] || "Accepted DC25 lead")
                ],
                meta: meta
            })
        }
        return rows
    }

    function coindroidsAttackEntries() {
        const rows = root.coindroidsAttackRows()
        let entries = []
        for (let i = 0; i < rows.length; ++i)
            entries.push({ row: rows[i], sourceIndex: i })
        entries.sort((a, b) => Number((b.row.meta || {}).dc25Outputs || 0) - Number((a.row.meta || {}).dc25Outputs || 0))
        return entries
    }

    function coindroidsAttackPlot(canvasWidth, canvasHeight) {
        const top = canvasHeight < 380 ? 88 : 104
        const bottom = canvasHeight < 380 ? 48 : 58
        return {
            left: 64,
            right: 24,
            top: top,
            bottom: bottom,
            width: Math.max(1, canvasWidth - 88),
            height: Math.max(1, canvasHeight - top - bottom)
        }
    }

    function coindroidsAttackIndexAt(mouseX, mouseY, canvasWidth, canvasHeight) {
        const entries = root.coindroidsAttackEntries()
        if (entries.length === 0) return -1
        const plot = root.coindroidsAttackPlot(canvasWidth, canvasHeight)
        if (mouseX < plot.left || mouseX > plot.left + plot.width || mouseY < plot.top || mouseY > plot.top + plot.height)
            return -1
        const visibleCount = Math.min(entries.length, canvasWidth < 1100 ? 18 : 28)
        const gap = Math.max(3, Math.min(8, plot.width / Math.max(24, visibleCount * 9)))
        const barWidth = Math.max(9, (plot.width - gap * (visibleCount + 1)) / Math.max(1, visibleCount))
        for (let i = 0; i < visibleCount; ++i) {
            const x = plot.left + gap + i * (barWidth + gap)
            if (mouseX >= x && mouseX <= x + barWidth)
                return entries[i].sourceIndex
        }
        return -1
    }

    function coindroidsAttackMeta(index) {
        const rows = root.coindroidsAttackRows()
        if (index < 0 || index >= rows.length) return ({})
        return rows[index].meta || ({})
    }

    function coindroidsAttackToolTip(index) {
        const meta = root.coindroidsAttackMeta(index)
        if (!meta || Object.keys(meta).length === 0) return ""
        return String(meta.name || meta.address || "DC25 candidate")
            + "\nIndexed address: " + String(meta.address || "")
            + "\nLegacy P2SH: " + String(meta.legacyP2sh || "")
            + "\nDC25 outputs: " + root.coindroidsMetricNumber(meta.dc25Outputs)
            + "\nDC25 DFC: " + Number(meta.dc25Dfc || 0).toLocaleString(Qt.locale(), "f", 4)
            + "\nSignature outputs: " + root.coindroidsMetricNumber(meta.signatureOutputs)
            + "\nSignature ratio: " + Number(meta.signatureRatio || 0).toLocaleString(Qt.locale(), "f", 3)
            + "\nConfidence: " + String(meta.confidence || "candidate")
    }

    function openCoindroidsAttackAddress(index) {
        const meta = root.coindroidsAttackMeta(index)
        if (String(meta.address || "").length > 0)
            NuService.openAddressInExplorer(String(meta.address))
    }

    function chartCoindroidsRelations(key) {
        NuService.loadCoindroidsContactSet(key)
        root.showRelationshipWindow()
    }

    function chartRowsRelationships(name, rows) {
        NuService.loadExplorerContactRows(name, rows || [])
        root.showRelationshipWindow()
    }

    function defcoinTimelineNumber(key) {
        return Number((NuService.defcoinTimelineSummary || {})[key] || 0).toLocaleString(Qt.locale(), "f", 0)
    }

    function defcoinTimelineText(key, fallbackText) {
        const value = (NuService.defcoinTimelineSummary || {})[key]
        if (value === undefined || value === null || String(value).length === 0)
            return fallbackText || "Not loaded"
        return String(value)
    }

    function explorerSupplySats() {
        if (NuService.explorerRichList.length > 0) {
            const meta = NuService.explorerRichList[0].meta || {}
            const total = Number(meta.totalUnspentSats || 0)
            if (total > 0) return total
        }
        return root.richTotalSats()
    }

    function explorerAddressCountText() {
        if (NuService.explorerRichList.length > 0) {
            const meta = NuService.explorerRichList[0].meta || {}
            const count = Number(meta.totalAddressCount || 0)
            if (count > 0) return count.toLocaleString(Qt.locale(), "f", 0)
        }
        return "Not indexed"
    }

    function richRangeSats(firstRank, lastRank) {
        let total = 0
        for (let i = 0; i < NuService.explorerRichList.length; ++i) {
            const row = NuService.explorerRichList[i]
            const rank = Number((row.meta || {}).rank || 0)
            if (rank >= firstRank && rank <= lastRank)
                total += Number((row.meta || {}).balanceSats || 0)
        }
        return total
    }

    function distributionRow(color, label, sats, total, includeInPie) {
        const percent = total > 0 ? (100.0 * Number(sats || 0) / total) : 0
        return {
            cells: [color, label, root.formatDfcFromSats(sats), percent.toFixed(2) + "%"],
            meta: { color: color, label: label, sats: Number(sats || 0), percent: percent, includeInPie: includeInPie }
        }
    }

    function wealthDistributionRows() {
        const total = root.explorerSupplySats()
        const top1_25 = root.richRangeSats(1, 25)
        const top26_50 = root.richRangeSats(26, 50)
        const top51_75 = root.richRangeSats(51, 75)
        const top76_100 = root.richRangeSats(76, 100)
        const top100 = top1_25 + top26_50 + top51_75 + top76_100
        const rest = Math.max(0, total - top100)
        return [
            root.distributionRow("#db38b8", "Ranks 1-25", top1_25, total, true),
            root.distributionRow("#48bd91", "Ranks 26-50", top26_50, total, true),
            root.distributionRow("#3d9ddd", "Ranks 51-75", top51_75, total, true),
            root.distributionRow("#ead934", "Ranks 76-100", top76_100, total, true),
            root.distributionRow("#8b95a1", "101+", rest, total, true),
            root.distributionRow("", "Ranks 1-100 Total", top100, total, false),
            root.distributionRow("", "Total", total, total, false),
            { cells: ["", "Total Wallet Addresses", root.explorerAddressCountText(), ""],
              meta: { includeInPie: false, label: "Total Wallet Addresses" } }
        ]
    }

    function whaleConcentrationRows() {
        const total = root.explorerSupplySats()
        const top1 = root.richRangeSats(1, 1)
        const top2_10 = root.richRangeSats(2, 10)
        const top11_25 = root.richRangeSats(11, 25)
        const top26_100 = root.richRangeSats(26, 100)
        const tracked = top1 + top2_10 + top11_25 + top26_100
        const rest = Math.max(0, total - tracked)
        return [
            root.distributionRow("#f05d4f", "Largest address", top1, total, true),
            root.distributionRow("#ff9f43", "Ranks 2-10", top2_10, total, true),
            root.distributionRow("#f3d447", "Ranks 11-25", top11_25, total, true),
            root.distributionRow("#48b7ff", "Ranks 26-100", top26_100, total, true),
            root.distributionRow("#aeb6bf", "101+", rest, total, true)
        ]
    }

    function distributionSliceAt(x, y, canvasWidth, canvasHeight, rows) {
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        const dx = x - cx
        const dy = y - cy
        const radius = Math.min(canvasWidth, canvasHeight) * 0.40
        const innerRadius = radius * 0.52
        const distance = Math.sqrt(dx * dx + dy * dy)
        if (distance < innerRadius || distance > radius + 18) return ""
        let total = 0
        for (let i = 0; i < rows.length; ++i) {
            const meta = rows[i].meta || {}
            if (meta.includeInPie) total += Number(meta.sats || 0)
        }
        if (total <= 0) return ""
        let angle = Math.atan2(dy, dx)
        angle += Math.PI / 2
        if (angle < 0) angle += Math.PI * 2
        let start = 0
        for (let r = 0; r < rows.length; ++r) {
            const meta = rows[r].meta || {}
            if (!meta.includeInPie) continue
            const pct = Number(meta.sats || 0) / total
            const end = start + Math.PI * 2 * pct
            if (angle >= start && angle <= end) return String(meta.label || "")
            start = end
        }
        return ""
    }

    function drawDistributionPie(ctx, canvasWidth, canvasHeight, rows, title, subtitle, selectedLabel) {
        ctx.reset()
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        const radius = Math.min(canvasWidth, canvasHeight) * 0.40
        const innerRadius = radius * 0.52
        let total = 0
        for (let i = 0; i < rows.length; ++i) {
            const meta = rows[i].meta || {}
            if (meta.includeInPie) total += Number(meta.sats || 0)
        }
        if (total <= 0) {
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
        let start = -Math.PI / 2
        for (let r = 0; r < rows.length; ++r) {
            const meta = rows[r].meta || {}
            if (!meta.includeInPie) continue
            const sats = Number(meta.sats || 0)
            if (sats <= 0) continue
            const end = start + Math.PI * 2 * sats / total
            const selected = String(meta.label || "") === String(selectedLabel || "")
            const mid = (start + end) / 2
            const offset = selected ? 13 : 0
            const sx = cx + Math.cos(mid) * offset
            const sy = cy + Math.sin(mid) * offset
            ctx.beginPath()
            ctx.moveTo(sx + Math.cos(start) * radius, sy + Math.sin(start) * radius)
            ctx.arc(sx, sy, radius, start, end)
            ctx.lineTo(sx + Math.cos(end) * innerRadius, sy + Math.sin(end) * innerRadius)
            ctx.arc(sx, sy, innerRadius, end, start, true)
            ctx.closePath()
            ctx.fillStyle = String(meta.color || "#7f8fa6")
            ctx.fill()
            ctx.strokeStyle = NuTokens.panelBase
            ctx.lineWidth = 2
            ctx.stroke()
            if (selected) {
                ctx.fillStyle = NuTokens.textPrimary
                ctx.font = "700 12px " + NuTokens.bodyFont
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(Number(meta.percent || 0).toFixed(2) + "%", sx + Math.cos(mid) * radius * 0.68, sy + Math.sin(mid) * radius * 0.68)
            }
            start = end
        }
        ctx.beginPath()
        ctx.arc(cx, cy, innerRadius, 0, Math.PI * 2)
        ctx.fillStyle = NuTokens.panelBase
        ctx.fill()
        ctx.fillStyle = NuTokens.textPrimary
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.font = "700 13px " + NuTokens.bodyFont
        ctx.fillText(title, cx, cy - 8)
        ctx.font = "11px " + NuTokens.bodyFont
        ctx.fillStyle = NuTokens.textSecondary
        ctx.fillText(subtitle, cx, cy + 10)
    }

    function contactRows() {
        const rows = []
        for (let i = 0; i < NuService.explorerContacts.length; ++i) {
            const contact = NuService.explorerContacts[i]
            const addresses = contact.addresses || []
            rows.push({
                cells: [String(contact.username || ""), String(contact.addressText || ""), addresses.length],
                meta: { index: i, username: String(contact.username || ""), addresses: addresses, addressText: String(contact.addressText || "") }
            })
        }
        return rows
    }

    function selectContact(row) {
        const meta = row && row.meta ? row.meta : {}
        root.selectedContactIndex = Number(meta.index !== undefined ? meta.index : -1)
        root.selectedContactName = String(meta.username || "")
        if (contactNameField) contactNameField.text = root.selectedContactName
        if (contactAddressArea) contactAddressArea.text = String(meta.addressText || "")
    }

    function clearContactEditor() {
        root.selectedContactIndex = -1
        root.selectedContactName = ""
        if (contactNameField) contactNameField.text = ""
        if (contactAddressArea) contactAddressArea.text = ""
    }

    function selectContactSet(row) {
        const meta = row && row.meta ? row.meta : {}
        root.selectedContactSetName = String(meta.name || "")
        if (contactSetNameField)
            contactSetNameField.text = root.selectedContactSetName
    }

    function activeContactSetLabel() {
        const name = String(NuService.currentExplorerContactSetName || "Default")
        return "Active contact set: " + name
    }

    function contactBalanceMap() {
        const out = ({})
        for (let c = 0; c < NuService.explorerContacts.length; ++c) {
            const contact = NuService.explorerContacts[c]
            out[String(contact.username || "")] = Number(contact.balanceSats || 0)
        }
        return out
    }

    function contactReceivedMap() {
        const out = ({})
        for (let c = 0; c < NuService.explorerContacts.length; ++c) {
            const contact = NuService.explorerContacts[c]
            out[String(contact.username || "")] = Number(contact.receivedSats || 0)
        }
        return out
    }

    function contactGraphCurrentSignature() {
        let parts = [String(NuService.currentExplorerContactSetName || "Default")]
        for (let i = 0; i < NuService.explorerContacts.length; ++i) {
            const contact = NuService.explorerContacts[i]
            parts.push(String(contact.username || "") + ":" + String(contact.addressText || "") + ":" + Number(contact.balanceSats || 0) + ":" + Number(contact.receivedSats || 0))
        }
        for (let r = 0; r < NuService.explorerContactRelationships.length; ++r) {
            const meta = NuService.explorerContactRelationships[r].meta || {}
            parts.push(String(meta.source || "") + ">" + String(meta.target || "") + ":" + Number(meta.amountSats || 0))
        }
        return parts.join("|")
    }

    function ensureContactGraphPositions(canvasWidth, canvasHeight) {
        const contacts = NuService.explorerContacts || []
        const signature = root.contactGraphCurrentSignature()
        if (signature === root.contactGraphSignature)
            return
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        const radius = Math.max(90, Math.min(canvasWidth, canvasHeight) * 0.34)
        const oldPositions = root.contactGraphPositions || ({})
        const positions = ({})
        for (let i = 0; i < contacts.length; ++i) {
            const name = String(contacts[i].username || "")
            const old = oldPositions[name]
            if (old && Number(old.x || 0) > 0 && Number(old.y || 0) > 0) {
                positions[name] = {
                    x: Math.max(38, Math.min(canvasWidth - 38, Number(old.x))),
                    y: Math.max(38, Math.min(canvasHeight - 38, Number(old.y)))
                }
            } else {
                const angle = -Math.PI / 2 + Math.PI * 2 * i / Math.max(1, contacts.length)
                positions[name] = { x: cx + Math.cos(angle) * radius, y: cy + Math.sin(angle) * radius }
            }
        }
        root.contactGraphPositions = positions
        root.contactGraphSignature = signature
    }

    function contactGraphMaxSizeSats() {
        let maxSize = 1
        for (let i = 0; i < NuService.explorerContacts.length; ++i) {
            const contact = NuService.explorerContacts[i]
            maxSize = Math.max(maxSize, Number(contact.balanceSats || 0), Number(contact.receivedSats || 0))
        }
        return maxSize
    }

    function contactGraphNodeRadius(contact) {
        const maxSize = root.contactGraphMaxSizeSats()
        const sizeSats = Math.max(Number((contact || {}).balanceSats || 0), Number((contact || {}).receivedSats || 0))
        return 22 + 34 * Math.sqrt(sizeSats / Math.max(1, maxSize))
    }

    function contactGraphNodeAt(x, y, canvasWidth, canvasHeight) {
        root.ensureContactGraphPositions(canvasWidth, canvasHeight)
        const positions = root.contactGraphPositions || ({})
        for (let i = NuService.explorerContacts.length - 1; i >= 0; --i) {
            const contact = NuService.explorerContacts[i]
            const name = String(contact.username || "")
            const pos = positions[name]
            if (!pos) continue
            const dx = x - Number(pos.x || 0)
            const dy = y - Number(pos.y || 0)
            if (Math.sqrt(dx * dx + dy * dy) <= root.contactGraphNodeRadius(contact) + 8)
                return name
        }
        return ""
    }

    function contactGraphContact(name) {
        const wanted = String(name || "")
        for (let i = 0; i < NuService.explorerContacts.length; ++i) {
            const contact = NuService.explorerContacts[i]
            if (String(contact.username || "") === wanted)
                return contact
        }
        return null
    }

    function contactGraphToolTip(name) {
        const contact = root.contactGraphContact(name)
        if (!contact) return ""
        return String(contact.username || "")
            + "\nCurrent balance: " + String(contact.balanceText || root.formatDfcFromSats(contact.balanceSats || 0))
            + "\nTotal received: " + String(contact.receivedText || root.formatDfcFromSats(contact.receivedSats || 0))
            + "\nTransactions: " + Number(contact.txCount || 0).toLocaleString(Qt.locale(), "f", 0)
            + "\nAddresses: " + String(contact.addressText || "")
    }

    function dragContactGraphNode(name, dx, dy, canvasWidth, canvasHeight) {
        if (String(name || "").length === 0) return
        const positions = root.contactGraphPositions || ({})
        const pos = positions[name]
        if (!pos) return
        positions[name] = {
            x: Math.max(28, Math.min(canvasWidth - 28, Number(pos.x || 0) + dx)),
            y: Math.max(28, Math.min(canvasHeight - 28, Number(pos.y || 0) + dy))
        }
        root.contactGraphPositions = positions
        if (contactGraphCanvas)
            contactGraphCanvas.requestPaint()
    }

    function drawContactGraph(ctx, canvasWidth, canvasHeight) {
        ctx.reset()
        const contacts = NuService.explorerContacts
        const relationships = NuService.explorerContactRelationships
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        root.ensureContactGraphPositions(canvasWidth, canvasHeight)
        const positions = root.contactGraphPositions || ({})
        let maxFlow = 1
        for (let e = 0; e < relationships.length; ++e)
            maxFlow = Math.max(maxFlow, Number((relationships[e].meta || {}).amountSats || 0))
        ctx.lineCap = "round"
        for (let j = 0; j < relationships.length; ++j) {
            const meta = relationships[j].meta || {}
            const source = positions[String(meta.source || "")]
            const target = positions[String(meta.target || "")]
            const amount = Number(meta.amountSats || 0)
            if (!source || !target || amount <= 0) continue
            ctx.strokeStyle = "#48b7ff"
            ctx.globalAlpha = 0.25 + 0.45 * Math.sqrt(amount / maxFlow)
            ctx.lineWidth = 1.5 + 11 * Math.sqrt(amount / maxFlow)
            ctx.beginPath()
            ctx.moveTo(source.x, source.y)
            ctx.lineTo(target.x, target.y)
            ctx.stroke()
        }
        ctx.globalAlpha = 1
        for (let n = 0; n < contacts.length; ++n) {
            const name = String(contacts[n].username || "")
            const pos = positions[name]
            if (!pos) continue
            const contact = contacts[n]
            const balanceSats = Number(contact.balanceSats || 0)
            const receivedSats = Number(contact.receivedSats || 0)
            const nodeRadius = root.contactGraphNodeRadius(contact)
            const wholeDfc = Math.round(balanceSats / 100000000)
            ctx.fillStyle = receivedSats > balanceSats * 1.25 ? "#60c88f" : "#f3d447"
            ctx.strokeStyle = NuTokens.textPrimary
            ctx.lineWidth = name === root.hoveredContactName || name === root.draggingContactName ? 4 : 2
            ctx.beginPath()
            ctx.arc(pos.x, pos.y, nodeRadius, 0, Math.PI * 2)
            ctx.fill()
            ctx.stroke()
            ctx.fillStyle = NuTokens.textPrimary
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            const amountText = wholeDfc.toLocaleString(Qt.locale(), "f", 0) + ".-"
            ctx.font = "800 " + root.movementFittedFontSize(ctx, amountText, nodeRadius * 1.55, 18, 8) + "px " + NuTokens.bodyFont
            ctx.fillText(amountText, pos.x, pos.y - 2)
            ctx.font = "10px " + NuTokens.bodyFont
            ctx.fillText("DFC", pos.x, pos.y + 13)
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "10px " + NuTokens.bodyFont
            ctx.fillText(name.length > 20 ? name.substring(0, 18) + "..." : name, pos.x, pos.y + nodeRadius + 13)
        }
        if (contacts.length === 0) {
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.fillText("Add contacts to chart address relationships.", cx, cy)
        }
    }

    function shortAddress(value) {
        const text = String(value || "")
        if (text.length <= 18) return text
        return text.substring(0, 8) + "..." + text.substring(text.length - 6)
    }

    function movementShortAddress(value) {
        const text = String(value || "")
        if (text.length <= 14) return text
        return text.substring(0, 6) + "..." + text.substring(text.length - 4)
    }

    function movementDfcAmountText(sats) {
        const wholeDfc = Math.round(Number(sats || 0) / 100000000)
        return wholeDfc.toLocaleString(Qt.locale(), "f", 0) + ".-"
    }

    function movementDfcFullText(sats) {
        const wholeDfc = Math.round(Number(sats || 0) / 100000000)
        return wholeDfc.toLocaleString(Qt.locale(), "f", 0) + ".- DFC"
    }

    function movementFittedFontSize(ctx, text, maxWidth, preferredSize, minimumSize) {
        const minSize = Math.max(7, minimumSize || 9)
        const maxSize = Math.max(minSize, preferredSize || 14)
        for (let size = maxSize; size >= minSize; size -= 0.5) {
            ctx.font = "800 " + size + "px " + NuTokens.bodyFont
            let width = String(text || "").length * size * 0.64
            if (ctx.measureText) {
                const measured = ctx.measureText(text)
                if (measured && measured.width !== undefined)
                    width = Number(measured.width) * 1.05
            }
            if (width <= maxWidth)
                return Number(size.toFixed(1))
        }
        return minSize
    }

    function movementNodeColor(node) {
        const incoming = Number((node || {}).incomingSats || 0)
        const outgoing = Number((node || {}).outgoingSats || 0)
        if (incoming > outgoing * 1.25) return "#60c88f"
        if (outgoing > incoming * 1.25) return "#f3d447"
        return "#5db7ff"
    }

    function movementNodeLegendText() {
        return "Node color: yellow net sender, green net receiver, blue mixed or relay. Line thickness follows plotted flow."
    }

    function movementNodeForAddress(address) {
        const wanted = String(address || "")
        if (wanted.length === 0) return null
        const nodes = root.movementGraphData().nodes || []
        for (let i = 0; i < nodes.length; ++i) {
            if (String(nodes[i].address || "") === wanted)
                return nodes[i]
        }
        return null
    }

    function movementNodeToolTip(address) {
        const node = root.movementNodeForAddress(address)
        if (!node) return ""
        return String(node.address || "")
            + "\nPlotted flow: " + root.movementDfcFullText(node.amountSats)
            + "\nInbound: " + root.movementDfcFullText(node.incomingSats)
            + "\nOutbound: " + root.movementDfcFullText(node.outgoingSats)
            + "\nConnections: " + Number(node.edgeCount || 0).toLocaleString(Qt.locale(), "f", 0)
            + "\nDrag to reposition; click without dragging to open in Explorer."
    }

    function movementGraphRows() {
        const rows = NuService.explorerMovements.slice(0)
        if (root.movementGraphSortMode === "Newest") {
            rows.sort(function(a, b) {
                return Number((b.meta || {}).time || 0) - Number((a.meta || {}).time || 0)
            })
        } else {
            rows.sort(function(a, b) {
                return Number((b.meta || {}).amountSats || 0) - Number((a.meta || {}).amountSats || 0)
            })
        }
        return rows.slice(0, Math.max(1, Math.min(50, root.movementGraphLimit)))
    }

    function movementGraphData() {
        const rows = root.movementGraphRows()
        const nodeMap = ({})
        const edgeMap = ({})
        const maxNodes = 100
        const maxEdges = 220
        function ensureNode(address, amount) {
            const key = String(address || "")
            if (key.length === 0) return false
            if (nodeMap[key] === undefined) {
                if (Object.keys(nodeMap).length >= maxNodes) return false
                nodeMap[key] = { address: key, amountSats: 0, incomingSats: 0, outgoingSats: 0, edgeCount: 0 }
            }
            nodeMap[key].amountSats += Number(amount || 0)
            return true
        }
        for (let r = 0; r < rows.length; ++r) {
            const meta = rows[r].meta || {}
            const amount = Number(meta.amountSats || 0)
            if (amount <= 0) continue
            const sources = (meta.sourceAddresses || []).slice(0, 5)
            const targets = (meta.targetAddresses || []).slice(0, 7)
            if (sources.length === 0 || targets.length === 0) continue
            const share = amount / Math.max(1, sources.length * targets.length)
            for (let s = 0; s < sources.length; ++s) {
                for (let t = 0; t < targets.length; ++t) {
                    const source = String(sources[s] || "")
                    const target = String(targets[t] || "")
                    if (source.length === 0 || target.length === 0 || source === target) continue
                    if (!ensureNode(source, share) || !ensureNode(target, share)) continue
                    nodeMap[source].outgoingSats += share
                    nodeMap[source].edgeCount += 1
                    nodeMap[target].incomingSats += share
                    nodeMap[target].edgeCount += 1
                    const key = source + "\n" + target
                    if (edgeMap[key] === undefined)
                        edgeMap[key] = { source: source, target: target, amountSats: 0, txCount: 0 }
                    edgeMap[key].amountSats += share
                    edgeMap[key].txCount += 1
                }
            }
        }
        let nodes = []
        for (const nodeKey in nodeMap) nodes.push(nodeMap[nodeKey])
        let edges = []
        for (const edgeKey in edgeMap) edges.push(edgeMap[edgeKey])
        edges.sort(function(a, b) { return Number(b.amountSats || 0) - Number(a.amountSats || 0) })
        edges = edges.slice(0, maxEdges)
        const used = ({})
        for (let e = 0; e < edges.length; ++e) {
            used[edges[e].source] = true
            used[edges[e].target] = true
        }
        nodes = nodes.filter(function(node) { return used[node.address] === true })
        return { nodes: nodes, edges: edges, rows: rows }
    }

    function movementGraphSurfaceState(canvasKey) {
        const key = String(canvasKey || "main")
        const states = root.movementGraphStates || ({})
        if (!states[key])
            states[key] = { positions: ({}), velocities: ({}), signature: "" }
        root.movementGraphStates = states
        return states[key]
    }

    function resetMovementGraphLayout(canvasKey) {
        const key = String(canvasKey || "")
        const states = root.movementGraphStates || ({})
        if (key.length > 0)
            states[key] = { positions: ({}), velocities: ({}), signature: "" }
        else
            root.movementGraphStates = ({})
        if (key.length > 0)
            root.movementGraphStates = states
        root.hoveredMovementAddress = ""
        root.draggingMovementAddress = ""
        root.movementDragMoved = false
        if (movementGraphCanvas)
            movementGraphCanvas.requestPaint()
        if (movementGraphPopoutCanvas)
            movementGraphPopoutCanvas.requestPaint()
    }

    function movementGraphSignatureForData(data, canvasWidth, canvasHeight) {
        const nodes = (data && data.nodes) ? data.nodes : []
        const edges = (data && data.edges) ? data.edges : []
        let parts = [
            root.movementGraphSortMode,
            root.movementGraphLimit,
            Math.round(root.movementNodeScale * 100),
            Math.round(canvasWidth),
            Math.round(canvasHeight),
            nodes.length,
            edges.length
        ]
        for (let i = 0; i < Math.min(nodes.length, 60); ++i)
            parts.push(String(nodes[i].address || ""))
        return parts.join("|")
    }

    function ensureMovementGraphState(data, canvasWidth, canvasHeight, canvasKey) {
        const nodes = data.nodes || []
        const state = root.movementGraphSurfaceState(canvasKey)
        const signature = root.movementGraphSignatureForData(data, canvasWidth, canvasHeight)
        const reset = signature !== state.signature
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        const radius = Math.max(90, Math.min(canvasWidth, canvasHeight) * 0.34)
        let nextPositions = reset ? ({}) : state.positions
        let nextVelocities = reset ? ({}) : state.velocities
        const seen = ({})
        for (let i = 0; i < nodes.length; ++i) {
            const address = String(nodes[i].address || "")
            if (address.length === 0) continue
            seen[address] = true
            if (!nextPositions[address]) {
                const angle = -Math.PI / 2 + Math.PI * 2 * i / Math.max(1, nodes.length)
                nextPositions[address] = {
                    x: cx + Math.cos(angle) * radius,
                    y: cy + Math.sin(angle) * radius
                }
            }
            if (!nextVelocities[address])
                nextVelocities[address] = { x: 0, y: 0 }
        }
        for (const addressKey in nextPositions) {
            if (seen[addressKey] !== true) {
                delete nextPositions[addressKey]
                delete nextVelocities[addressKey]
            }
        }
        state.signature = signature
        state.positions = nextPositions
        state.velocities = nextVelocities
        if (reset)
            root.settleMovementGraph(data, canvasWidth, canvasHeight, 120, "", canvasKey)
        root.movementNodePositions = state.positions
        root.movementNodeVelocities = state.velocities
        root.movementGraphSignature = state.signature
    }

    function movementNodeRadius(node, maxNode) {
        const scale = Math.max(0.65, Math.min(2.2, Number(root.movementNodeScale || 1)))
        return (22 + 26 * Math.sqrt(Number(node.amountSats || 0) / Math.max(1, maxNode))) * scale
    }

    function movementNodeMargin(node, maxNode) {
        return root.movementNodeRadius(node, maxNode) + 32
    }

    function movementNodeCollisionRadius(node, maxNode) {
        return root.movementNodeRadius(node, maxNode) + 18
    }

    function movementClampedCoordinate(value, lower, upper) {
        if (upper < lower)
            return (lower + upper) / 2
        return Math.max(lower, Math.min(upper, value))
    }

    function movementBoundsForNode(node, maxNode, canvasWidth, canvasHeight) {
        const radius = root.movementNodeRadius(node, maxNode)
        const xMargin = Math.min(radius + 34, Math.max(28, canvasWidth * 0.24))
        const topMargin = Math.min(radius + 18, Math.max(24, canvasHeight * 0.26))
        const bottomMargin = Math.min(radius + 38, Math.max(28, canvasHeight * 0.30))
        return {
            left: xMargin,
            right: canvasWidth - xMargin,
            top: topMargin,
            bottom: canvasHeight - bottomMargin
        }
    }

    function settleMovementGraph(data, canvasWidth, canvasHeight, iterations, pinnedAddress, canvasKey) {
        const nodes = data.nodes || []
        const edges = data.edges || []
        const state = root.movementGraphSurfaceState(canvasKey)
        const positions = state.positions
        const velocities = state.velocities
        const k = Math.sqrt(Math.max(1, canvasWidth * canvasHeight / Math.max(1, nodes.length))) * 0.72
        const pinned = String(pinnedAddress || "")
        let maxNode = 1
        for (let nodeIndex = 0; nodeIndex < nodes.length; ++nodeIndex)
            maxNode = Math.max(maxNode, Number(nodes[nodeIndex].amountSats || 0))
        for (let iter = 0; iter < iterations; ++iter) {
            for (let a = 0; a < nodes.length; ++a) {
                for (let b = a + 1; b < nodes.length; ++b) {
                    const aKey = nodes[a].address
                    const bKey = nodes[b].address
                    const pa = positions[aKey]
                    const pb = positions[bKey]
                    if (!pa || !pb) continue
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    let dist = Math.max(8, Math.sqrt(dx * dx + dy * dy))
                    const idealDistance = root.movementNodeCollisionRadius(nodes[a], maxNode) + root.movementNodeCollisionRadius(nodes[b], maxNode)
                    const overlap = idealDistance - dist
                    const force = Math.min(6.5, (k * k) / dist * 0.018) + (overlap > 0 ? Math.min(12, overlap * 0.20) : 0)
                    dx /= dist
                    dy /= dist
                    if (overlap > 0) {
                        const push = Math.min(18, overlap * 0.22)
                        if (aKey !== pinned) {
                            pa.x += dx * push
                            pa.y += dy * push
                        }
                        if (bKey !== pinned) {
                            pb.x -= dx * push
                            pb.y -= dy * push
                        }
                    }
                    if (aKey !== pinned) {
                        velocities[aKey].x += dx * force
                        velocities[aKey].y += dy * force
                    }
                    if (bKey !== pinned) {
                        velocities[bKey].x -= dx * force
                        velocities[bKey].y -= dy * force
                    }
                }
            }
            for (let e = 0; e < edges.length; ++e) {
                const ps = positions[edges[e].source]
                const pt = positions[edges[e].target]
                if (!ps || !pt) continue
                let dx = pt.x - ps.x
                let dy = pt.y - ps.y
                let dist = Math.max(8, Math.sqrt(dx * dx + dy * dy))
                const force = Math.min(4.0, (dist * dist / k) * 0.00115)
                dx /= dist
                dy /= dist
                if (edges[e].source !== pinned) {
                    velocities[edges[e].source].x += dx * force
                    velocities[edges[e].source].y += dy * force
                }
                if (edges[e].target !== pinned) {
                    velocities[edges[e].target].x -= dx * force
                    velocities[edges[e].target].y -= dy * force
                }
            }
            for (let n = 0; n < nodes.length; ++n) {
                const key = nodes[n].address
                const p = positions[key]
                const v = velocities[key]
                if (!p || !v) continue
                if (key === pinned) {
                    v.x = 0
                    v.y = 0
                    continue
                }
                const bounds = root.movementBoundsForNode(nodes[n], maxNode, canvasWidth, canvasHeight)
                v.x *= 0.72
                v.y *= 0.72
                p.x = root.movementClampedCoordinate(p.x + v.x, bounds.left, bounds.right)
                p.y = root.movementClampedCoordinate(p.y + v.y, bounds.top, bounds.bottom)
            }
        }
        for (let z = 0; z < nodes.length; ++z) {
            const velocity = velocities[nodes[z].address]
            if (!velocity) continue
            velocity.x = 0
            velocity.y = 0
        }
        state.positions = positions
        state.velocities = velocities
    }

    function nudgeConnectedMovementNodes(address, dx, dy, data, canvasWidth, canvasHeight, canvasKey) {
        const target = String(address || "")
        if (target.length === 0) return
        const positions = root.movementGraphSurfaceState(canvasKey).positions
        const edges = data.edges || []
        for (let e = 0; e < edges.length; ++e) {
            let other = ""
            if (edges[e].source === target) other = edges[e].target
            else if (edges[e].target === target) other = edges[e].source
            if (other.length === 0 || !positions[other]) continue
            positions[other].x = Math.max(70, Math.min(canvasWidth - 70, positions[other].x + dx * 0.18))
            positions[other].y = Math.max(64, Math.min(canvasHeight - 64, positions[other].y + dy * 0.18))
        }
    }

    function movementNodeAt(x, y, canvasWidth, canvasHeight, canvasKey) {
        const data = root.movementGraphData()
        root.ensureMovementGraphState(data, canvasWidth, canvasHeight, canvasKey)
        const positions = root.movementGraphSurfaceState(canvasKey).positions
        let maxNode = 1
        for (let i = 0; i < data.nodes.length; ++i)
            maxNode = Math.max(maxNode, Number(data.nodes[i].amountSats || 0))
        for (let n = data.nodes.length - 1; n >= 0; --n) {
            const node = data.nodes[n]
            const pos = positions[node.address]
            if (!pos) continue
            const radius = root.movementNodeRadius(node, maxNode) + 6
            const dx = x - pos.x
            const dy = y - pos.y
            if (Math.sqrt(dx * dx + dy * dy) <= radius) return node.address
        }
        return ""
    }

    function moveMovementNode(address, x, y, canvasWidth, canvasHeight, canvasKey) {
        const key = String(address || "")
        const data = root.movementGraphData()
        root.ensureMovementGraphState(data, canvasWidth, canvasHeight, canvasKey)
        const state = root.movementGraphSurfaceState(canvasKey)
        if (key.length === 0 || !state.positions[key]) return
        let maxNode = 1
        let activeNode = null
        for (let i = 0; i < data.nodes.length; ++i) {
            maxNode = Math.max(maxNode, Number(data.nodes[i].amountSats || 0))
            if (data.nodes[i].address === key)
                activeNode = data.nodes[i]
        }
        const bounds = activeNode
                ? root.movementBoundsForNode(activeNode, maxNode, canvasWidth, canvasHeight)
                : { left: 52, right: canvasWidth - 52, top: 48, bottom: canvasHeight - 48 }
        const nextX = root.movementClampedCoordinate(x, bounds.left, bounds.right)
        const nextY = root.movementClampedCoordinate(y, bounds.top, bounds.bottom)
        const dx = nextX - state.positions[key].x
        const dy = nextY - state.positions[key].y
        state.positions[key].x = nextX
        state.positions[key].y = nextY
        root.nudgeConnectedMovementNodes(key, dx, dy, data, canvasWidth, canvasHeight, canvasKey)
        root.settleMovementGraph(data, canvasWidth, canvasHeight, 10, key, canvasKey)
    }

    function drawMovementGraph(ctx, canvasWidth, canvasHeight, canvasKey) {
        ctx.reset()
        const data = root.movementGraphData()
        const nodes = data.nodes
        const edges = data.edges
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        if (nodes.length === 0 || edges.length === 0) {
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText("Refresh Movements, then choose how many transfers to chart.", cx, cy)
            return
        }

        root.ensureMovementGraphState(data, canvasWidth, canvasHeight, canvasKey)
        const positions = root.movementGraphSurfaceState(canvasKey).positions

        let maxEdge = 1
        let maxNode = 1
        const nodeByAddress = ({})
        for (let edgeIndex = 0; edgeIndex < edges.length; ++edgeIndex)
            maxEdge = Math.max(maxEdge, Number(edges[edgeIndex].amountSats || 0))
        for (let nodeIndex = 0; nodeIndex < nodes.length; ++nodeIndex) {
            maxNode = Math.max(maxNode, Number(nodes[nodeIndex].amountSats || 0))
            nodeByAddress[nodes[nodeIndex].address] = nodes[nodeIndex]
        }

        ctx.textAlign = "left"
        ctx.textBaseline = "middle"
        ctx.font = "11px " + NuTokens.bodyFont
        const legend = [
            { color: "#f3d447", text: "net sender" },
            { color: "#60c88f", text: "net receiver" },
            { color: "#5db7ff", text: "mixed / relay" }
        ]
        let legendX = 12
        for (let legendIndex = 0; legendIndex < legend.length; ++legendIndex) {
            ctx.fillStyle = legend[legendIndex].color
            ctx.beginPath()
            ctx.arc(legendX + 5, 15, 5, 0, Math.PI * 2)
            ctx.fill()
            ctx.fillStyle = NuTokens.textSecondary
            ctx.fillText(legend[legendIndex].text, legendX + 16, 15)
            legendX += 104
        }

        ctx.lineCap = "round"
        for (let edgeDraw = 0; edgeDraw < edges.length; ++edgeDraw) {
            const edge = edges[edgeDraw]
            const source = positions[edge.source]
            const target = positions[edge.target]
            if (!source || !target) continue
            let dx = target.x - source.x
            let dy = target.y - source.y
            const dist = Math.max(1, Math.sqrt(dx * dx + dy * dy))
            dx /= dist
            dy /= dist
            const sourceRadius = root.movementNodeRadius(nodeByAddress[edge.source] || {}, maxNode)
            const targetRadius = root.movementNodeRadius(nodeByAddress[edge.target] || {}, maxNode)
            const startX = source.x + dx * (sourceRadius + 3)
            const startY = source.y + dy * (sourceRadius + 3)
            const endX = target.x - dx * (targetRadius + 4)
            const endY = target.y - dy * (targetRadius + 4)
            if (Math.abs(endX - startX) + Math.abs(endY - startY) < 6) continue
            const strength = Math.sqrt(Number(edge.amountSats || 0) / maxEdge)
            const connected = root.hoveredMovementAddress.length > 0
                    && (edge.source === root.hoveredMovementAddress || edge.target === root.hoveredMovementAddress)
            ctx.strokeStyle = "#48b7ff"
            ctx.globalAlpha = connected ? 0.92 : 0.34 + 0.46 * strength
            ctx.lineWidth = (connected ? 2.8 : 1.6) + 6.2 * strength
            ctx.beginPath()
            ctx.moveTo(startX, startY)
            ctx.lineTo(endX, endY)
            ctx.stroke()

            const arrowLength = Math.max(7, Math.min(14, ctx.lineWidth + 6))
            const arrowWidth = arrowLength * 0.58
            ctx.fillStyle = "#48b7ff"
            ctx.beginPath()
            ctx.moveTo(endX, endY)
            ctx.lineTo(endX - dx * arrowLength + -dy * arrowWidth, endY - dy * arrowLength + dx * arrowWidth)
            ctx.lineTo(endX - dx * arrowLength + dy * arrowWidth, endY - dy * arrowLength + -dx * arrowWidth)
            ctx.closePath()
            ctx.fill()
        }

        ctx.globalAlpha = 1
        for (let nodeDraw = 0; nodeDraw < nodes.length; ++nodeDraw) {
            const node = nodes[nodeDraw]
            const pos = positions[node.address]
            if (!pos) continue
            const nodeRadius = root.movementNodeRadius(node, maxNode)
            const amountText = root.movementDfcAmountText(node.amountSats)
            const hovered = root.hoveredMovementAddress === node.address || root.draggingMovementAddress === node.address
            ctx.fillStyle = root.movementNodeColor(node)
            ctx.strokeStyle = root.hoveredMovementAddress === node.address || root.draggingMovementAddress === node.address ? NuTokens.lineStrong : NuTokens.textPrimary
            ctx.lineWidth = hovered ? 3.0 : 1.7
            ctx.beginPath()
            ctx.arc(pos.x, pos.y, nodeRadius, 0, Math.PI * 2)
            ctx.fill()
            ctx.stroke()

            ctx.fillStyle = NuTokens.textPrimary
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            const numberFontSize = root.movementFittedFontSize(ctx, amountText, Math.max(18, nodeRadius * 1.32), Math.min(22, Math.max(10, nodeRadius * 0.38)), 7.5)
            ctx.font = "800 " + numberFontSize + "px " + NuTokens.bodyFont
            ctx.fillText(amountText, pos.x, pos.y, Math.max(18, nodeRadius * 1.36))

            const addressLabel = root.movementShortAddress(node.address)
            const addressY = pos.y + nodeRadius + 12
            ctx.font = "700 10px " + NuTokens.bodyFont
            let labelWidth = Math.min(132, Math.max(46, addressLabel.length * 5.8))
            if (ctx.measureText) {
                const measuredLabel = ctx.measureText(addressLabel)
                if (measuredLabel && measuredLabel.width !== undefined)
                    labelWidth = Math.min(132, Math.max(46, Number(measuredLabel.width)))
            }
            const labelCenterX = Math.max(labelWidth / 2 + 8, Math.min(canvasWidth - labelWidth / 2 - 8, pos.x))
            ctx.globalAlpha = 0.88
            ctx.fillStyle = NuTokens.backgroundBase
            ctx.fillRect(labelCenterX - labelWidth / 2 - 5, addressY - 8, labelWidth + 10, 17)
            ctx.globalAlpha = 1
            ctx.fillStyle = NuTokens.textPrimary
            ctx.fillText(addressLabel, labelCenterX, addressY, labelWidth)
        }

        ctx.textAlign = "left"
        ctx.textBaseline = "alphabetic"
        ctx.font = "11px " + NuTokens.bodyFont
        ctx.fillStyle = NuTokens.textSecondary
        ctx.fillText("Drag nodes to untangle clusters; click a node to open its address in Explorer.", 12, canvasHeight - 10, Math.max(120, canvasWidth - 24))
    }

    function drawCoindroidsLegendMetric(ctx, x, y, width, color, label, value) {
        ctx.fillStyle = color
        ctx.fillRect(x, y + 4, 12, 12)
        ctx.fillStyle = NuTokens.textPrimary
        ctx.font = "700 17px " + NuTokens.bodyFont
        ctx.textAlign = "left"
        ctx.textBaseline = "alphabetic"
        ctx.fillText(value, x + 20, y + 16, width - 20)
        ctx.fillStyle = NuTokens.textSecondary
        ctx.font = "11px " + NuTokens.bodyFont
        ctx.fillText(label, x + 20, y + 33, width - 20)
    }

    function drawCoindroidsWindowChart(ctx, canvasWidth, canvasHeight) {
        ctx.reset()
        const entries = root.coindroidsChartEntries()
        const allRows = root.coindroidsWindowRows()
        const plot = root.coindroidsChartPlot(canvasWidth, canvasHeight)

        ctx.fillStyle = NuTokens.backgroundBase
        ctx.fillRect(0, 0, canvasWidth, canvasHeight)

        ctx.fillStyle = NuTokens.textPrimary
        ctx.font = "700 16px " + NuTokens.bodyFont
        ctx.textAlign = "left"
        ctx.textBaseline = "alphabetic"
        ctx.fillText(root.coindroidsWindowZoomed && root.selectedCoindroidsWindowIndex >= 0
                     ? root.coindroidsWindowLabel(root.selectedCoindroidsWindowIndex)
                     : "Coindroids Candidate Windows", plot.left, 24, Math.max(220, canvasWidth - plot.left - plot.right))

        if (entries.length === 0) {
            ctx.strokeStyle = NuTokens.lineSubtle
            ctx.lineWidth = 1
            ctx.strokeRect(plot.left, plot.top, plot.width, plot.height)
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText("Refresh Droid Trails to chart Coindroids candidate windows.", canvasWidth / 2, canvasHeight / 2)
            return
        }

        const cardGap = 14
        const cardWidth = Math.max(150, Math.min(260, (canvasWidth - plot.left - plot.right - cardGap * 2) / 3))
        if (root.coindroidsWindowZoomed && root.selectedCoindroidsWindowIndex >= 0) {
            const selectedMeta = root.coindroidsWindowMeta(root.selectedCoindroidsWindowIndex)
            root.drawCoindroidsLegendMetric(ctx, plot.left, 36, cardWidth, "#f3d447", "candidate DFC", root.coindroidsDfcFromSats(selectedMeta.actionSats, 2))
            root.drawCoindroidsLegendMetric(ctx, plot.left + cardWidth + cardGap, 36, cardWidth, "#48b7ff", "candidate outputs", root.coindroidsMetricNumber(selectedMeta.actionOutputs))
            root.drawCoindroidsLegendMetric(ctx, plot.left + (cardWidth + cardGap) * 2, 36, cardWidth, "#f05d4f", "0.1337 swarm outputs", root.coindroidsMetricNumber(selectedMeta.exact1337Outputs))

            const metrics = [
                { label: "Outputs", value: Number(selectedMeta.actionOutputs || 0), color: "#f3d447" },
                { label: "Txs", value: Number(selectedMeta.actionTransactions || 0), color: "#48b7ff" },
                { label: "Addresses", value: Number(selectedMeta.actionAddresses || 0), color: "#60c88f" },
                { label: "0.01", value: Number(selectedMeta.exact001Outputs || 0), color: "#9c8cff" },
                { label: "0.1337", value: Number(selectedMeta.exact1337Outputs || 0), color: "#f05d4f" }
            ]
            let maxMetric = 1
            for (let m = 0; m < metrics.length; ++m)
                maxMetric = Math.max(maxMetric, metrics[m].value)

            ctx.strokeStyle = NuTokens.lineSubtle
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(plot.left, plot.top)
            ctx.lineTo(plot.left, plot.top + plot.height)
            ctx.lineTo(plot.left + plot.width, plot.top + plot.height)
            ctx.stroke()

            const metricGap = Math.max(18, Math.min(38, plot.width / 28))
            const metricWidth = Math.max(44, (plot.width - metricGap * (metrics.length + 1)) / metrics.length)
            for (let i = 0; i < metrics.length; ++i) {
                const metric = metrics[i]
                const x = plot.left + metricGap + i * (metricWidth + metricGap)
                const h = Math.max(4, plot.height * metric.value / maxMetric)
                const y = plot.top + plot.height - h
                ctx.fillStyle = metric.color
                ctx.fillRect(x, y, metricWidth, h)
                ctx.strokeStyle = metric.label === "0.1337" ? NuTokens.textPrimary : NuTokens.lineSubtle
                ctx.lineWidth = metric.label === "0.1337" ? 2 : 1
                ctx.strokeRect(x, y, metricWidth, h)
                ctx.fillStyle = NuTokens.textPrimary
                ctx.font = "700 15px " + NuTokens.bodyFont
                ctx.textAlign = "center"
                ctx.fillText(root.coindroidsMetricNumber(metric.value), x + metricWidth / 2, Math.max(plot.top + 18, y - 8))
                ctx.fillStyle = NuTokens.textSecondary
                ctx.font = "12px " + NuTokens.bodyFont
                ctx.fillText(metric.label, x + metricWidth / 2, plot.top + plot.height + 24)
            }
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "12px " + NuTokens.bodyFont
            ctx.textAlign = "left"
            ctx.fillText("Detailed count view. Use All windows to return to the DEF CON comparison.", plot.left, canvasHeight - 12)
            return
        }

        root.drawCoindroidsLegendMetric(ctx, plot.left, 36, cardWidth, "#f3d447", "candidate outputs", root.coindroidsMetricNumber(root.coindroidsWindowTotal("actionOutputs")))
        root.drawCoindroidsLegendMetric(ctx, plot.left + cardWidth + cardGap, 36, cardWidth, "#f05d4f", "0.1337 swarm outputs", root.coindroidsMetricNumber(root.coindroidsWindowTotal("exact1337Outputs")))
        root.drawCoindroidsLegendMetric(ctx, plot.left + (cardWidth + cardGap) * 2, 36, cardWidth, "#48b7ff", "0.01 action outputs", root.coindroidsMetricNumber(root.coindroidsWindowTotal("exact001Outputs")))

        let maxOutputs = 0
        for (let i = 0; i < allRows.length; ++i)
            maxOutputs = Math.max(maxOutputs, Number((allRows[i].meta || {}).actionOutputs || 0))

        ctx.strokeStyle = NuTokens.lineSubtle
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(plot.left, plot.top)
        ctx.lineTo(plot.left, plot.top + plot.height)
        ctx.lineTo(plot.left + plot.width, plot.top + plot.height)
        ctx.stroke()
        if (maxOutputs <= 0) return

        const barGap = Math.max(10, Math.min(28, plot.width / Math.max(18, entries.length * 5)))
        const barWidth = Math.max(20, (plot.width - barGap * (entries.length + 1)) / Math.max(1, entries.length))
        for (let r = 0; r < entries.length; ++r) {
            const meta = entries[r].row.meta || {}
            const sourceIndex = entries[r].sourceIndex
            const outputs = Number(meta.actionOutputs || 0)
            const exact1337 = Number(meta.exact1337Outputs || 0)
            const x = plot.left + barGap + r * (barWidth + barGap)
            const h = Math.max(4, plot.height * outputs / maxOutputs)
            const y = plot.top + plot.height - h
            const hovered = root.hoveredCoindroidsWindowIndex === sourceIndex
            ctx.fillStyle = exact1337 > 0 ? "#f3d447" : "#48b7ff"
            ctx.globalAlpha = hovered ? 1.0 : 0.92
            ctx.fillRect(x, y, barWidth, h)
            if (exact1337 > 0) {
                const swarmHeight = Math.max(3, h * exact1337 / Math.max(1, outputs))
                ctx.fillStyle = "#f05d4f"
                ctx.fillRect(x, plot.top + plot.height - swarmHeight, barWidth, swarmHeight)
            }
            ctx.globalAlpha = 1.0
            ctx.strokeStyle = hovered ? NuTokens.textPrimary : NuTokens.lineSubtle
            ctx.lineWidth = hovered ? 2 : 1
            ctx.strokeRect(x, y, barWidth, h)
            ctx.fillStyle = NuTokens.textPrimary
            ctx.font = "700 14px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.fillText(root.coindroidsMetricNumber(outputs), x + barWidth / 2, Math.max(plot.top + 18, y - 8))
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "12px " + NuTokens.bodyFont
            const label = String(meta.shortLabel || meta.label || "").replace("DEF CON ", "DC")
            ctx.fillText(label, x + barWidth / 2, plot.top + plot.height + 24)
        }

        ctx.fillStyle = NuTokens.textSecondary
        ctx.font = "12px " + NuTokens.bodyFont
        ctx.textAlign = "left"
        ctx.fillText("Hover for exact block/date details. Click a DEF CON bar to zoom into its count profile.", plot.left, canvasHeight - 12)
    }

    function drawCoindroidsAttackChart(ctx, canvasWidth, canvasHeight) {
        ctx.reset()
        const entries = root.coindroidsAttackEntries()
        const plot = root.coindroidsAttackPlot(canvasWidth, canvasHeight)
        ctx.fillStyle = NuTokens.backgroundBase
        ctx.fillRect(0, 0, canvasWidth, canvasHeight)

        ctx.fillStyle = NuTokens.textPrimary
        ctx.font = "700 16px " + NuTokens.bodyFont
        ctx.textAlign = "left"
        ctx.textBaseline = "alphabetic"
        ctx.fillText("DC25 Attack-Address Cohort", plot.left, 24, Math.max(220, canvasWidth - plot.left - plot.right))

        if (entries.length === 0) {
            ctx.strokeStyle = NuTokens.lineSubtle
            ctx.lineWidth = 1
            ctx.strokeRect(plot.left, plot.top, plot.width, plot.height)
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText("Refresh Droid Trails to load the DC25 attack-address forensics dataset.", canvasWidth / 2, canvasHeight / 2)
            return
        }

        const visibleCount = Math.min(entries.length, canvasWidth < 1100 ? 18 : 28)
        const topRows = entries.slice(0, visibleCount)
        let maxOutputs = 1
        let signatureTotal = 0
        let outputTotal = 0
        for (let i = 0; i < entries.length; ++i) {
            const meta = entries[i].row.meta || {}
            maxOutputs = Math.max(maxOutputs, Number(meta.dc25Outputs || 0))
            signatureTotal += Number(meta.signatureOutputs || 0)
            outputTotal += Number(meta.dc25Outputs || 0)
        }
        const cardGap = 14
        const cardWidth = Math.max(150, Math.min(260, (canvasWidth - plot.left - plot.right - cardGap * 2) / 3))
        root.drawCoindroidsLegendMetric(ctx, plot.left, 38, cardWidth, "#48b7ff", "candidate rows", root.coindroidsMetricNumber(entries.length))
        root.drawCoindroidsLegendMetric(ctx, plot.left + cardWidth + cardGap, 38, cardWidth, "#60c88f", "DC25 outputs", root.coindroidsMetricNumber(outputTotal))
        root.drawCoindroidsLegendMetric(ctx, plot.left + (cardWidth + cardGap) * 2, 38, cardWidth, "#f3d447", "signature outputs", root.coindroidsMetricNumber(signatureTotal))

        ctx.strokeStyle = NuTokens.lineSubtle
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(plot.left, plot.top)
        ctx.lineTo(plot.left, plot.top + plot.height)
        ctx.lineTo(plot.left + plot.width, plot.top + plot.height)
        ctx.stroke()

        const gap = Math.max(3, Math.min(8, plot.width / Math.max(24, visibleCount * 9)))
        const barWidth = Math.max(9, (plot.width - gap * (visibleCount + 1)) / Math.max(1, visibleCount))
        for (let i = 0; i < topRows.length; ++i) {
            const meta = topRows[i].row.meta || {}
            const sourceIndex = topRows[i].sourceIndex
            const outputs = Number(meta.dc25Outputs || 0)
            const ratio = Number(meta.signatureRatio || 0)
            const signatureOutputs = Number(meta.signatureOutputs || 0)
            const x = plot.left + gap + i * (barWidth + gap)
            const h = Math.max(4, plot.height * outputs / maxOutputs)
            const y = plot.top + plot.height - h
            const hovered = root.hoveredCoindroidsAttackIndex === sourceIndex
            const confidence = String(meta.confidence || "")
            ctx.fillStyle = confidence.indexOf("Seed") >= 0 ? "#60c88f" : (confidence.indexOf("Broad") >= 0 ? "#9c8cff" : "#48b7ff")
            ctx.globalAlpha = hovered ? 1.0 : 0.92
            ctx.fillRect(x, y, barWidth, h)
            if (signatureOutputs > 0) {
                const signatureHeight = Math.max(3, h * Math.min(1, ratio))
                ctx.fillStyle = "#f3d447"
                ctx.fillRect(x, plot.top + plot.height - signatureHeight, barWidth, signatureHeight)
            }
            ctx.globalAlpha = 1.0
            ctx.strokeStyle = hovered ? NuTokens.textPrimary : NuTokens.lineSubtle
            ctx.lineWidth = hovered ? 2 : 1
            ctx.strokeRect(x, y, barWidth, h)
            ctx.fillStyle = NuTokens.textPrimary
            ctx.font = "700 12px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.fillText(root.coindroidsMetricNumber(outputs), x + barWidth / 2, Math.max(plot.top + 16, y - 6), Math.max(28, barWidth * 2.2))
        }

        ctx.fillStyle = NuTokens.textSecondary
        ctx.font = "12px " + NuTokens.bodyFont
        ctx.textAlign = "left"
        ctx.fillText("Showing the highest-output attack-address candidates. Green bars are QR-confirmed seeds; violet bars are broad-cohort candidates. Click a bar to open the indexed M-address.", plot.left, canvasHeight - 12, Math.max(160, canvasWidth - plot.left - plot.right))
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

    function shareFromCell(cellText, row) {
        const meta = row && row.meta ? row.meta : {}
        if (meta.percentBasisPoints !== undefined && meta.percentBasisPoints !== null)
            return Math.max(0, Number(meta.percentBasisPoints) / 100.0)
        const parsed = parseFloat(String(cellText || "0").replace("%", ""))
        return isNaN(parsed) ? 0 : Math.max(0, parsed)
    }

    onActiveChanged: {
        if (active && !root.summaryRequested) {
            root.summaryRequested = true
            NuService.refreshExplorerRecentLookups()
        }
        if (active)
            root.applyPreferredTab()
        root.maybeRefreshAnalyticsForTab()
    }

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
            if (holderPiePopoutCanvas)
                holderPiePopoutCanvas.requestPaint()
            if (wealthDistributionPie)
                wealthDistributionPie.requestPaint()
            if (supplyBandsPopoutCanvas)
                supplyBandsPopoutCanvas.requestPaint()
            if (whaleConcentrationPie)
                whaleConcentrationPie.requestPaint()
            if (whaleLensPopoutCanvas)
                whaleLensPopoutCanvas.requestPaint()
            if (contactGraphCanvas)
                contactGraphCanvas.requestPaint()
            if (movementGraphCanvas)
                movementGraphCanvas.requestPaint()
            if (movementGraphPopoutCanvas)
                movementGraphPopoutCanvas.requestPaint()
            if (coindroidsWindowChart)
                coindroidsWindowChart.requestPaint()
            if (coindroidsChartPopoutCanvas)
                coindroidsChartPopoutCanvas.requestPaint()
            if (timelinePie)
                timelinePie.requestPaint()
        }
    }

    NuPageHeader {
        Layout.fillWidth: true
        visible: explorerTabs.currentIndex !== 3
        title: root.sectionTitle
        detail: root.sectionDetail
    }

    RowLayout {
        Layout.fillWidth: true
        visible: explorerTabs.currentIndex === 3
        spacing: NuTokens.spaceLg

        ColumnLayout {
            Layout.fillWidth: true
            spacing: NuTokens.spaceXs

            Label {
                Layout.fillWidth: true
                text: root.sectionTitle
                color: NuTokens.textPrimary
                font.pixelSize: root.width > 0 && root.width < 900 ? NuTokens.fontBodyLarge : NuTokens.fontTitle
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            NuSelectableText {
                Layout.fillWidth: true
                text: root.sectionDetail
                visible: root.sectionDetail.length > 0
                textColor: NuTokens.textSecondary
                textPixelSize: NuTokens.fontSmall
            }
        }

        NuActionButton {
            Layout.preferredWidth: 116
            Layout.alignment: Qt.AlignTop
            text: NuService.coindroidsScanning ? "Scanning" : "Refresh"
            enabled: !NuService.coindroidsScanning
            primary: !NuService.coindroidsScanning
            helpText: "Rebuild Coindroids candidate windows, endpoint clusters, payout winners, and detection-rule evidence from the local Explorer index."
            onClicked: root.refreshCoindroids()
        }

        NuActionButton {
            Layout.preferredWidth: 116
            Layout.alignment: Qt.AlignTop
            text: "Pop out"
            helpText: "Open the selected Droid Trails tab in a maximized window."
            onClicked: root.popOutCoindroidsTab()
        }

        NuActionButton {
            Layout.preferredWidth: 96
            Layout.alignment: Qt.AlignTop
            text: "PDF"
            helpText: "Open the bundled Coindroids forensics story report placeholder in the default macOS PDF app."
            onClicked: NuService.openCoindroidsReportPdf()
        }
    }

    NuTabBar {
        Layout.fillWidth: true
        visible: explorerTabs.currentIndex === 3
        currentIndex: root.coindroidsDetailTab
        onCurrentIndexChanged: root.coindroidsDetailTab = currentIndex
        NuTabButton { text: "Droid Trails" }
        NuTabButton { text: "DC25 Payout Hunt" }
        NuTabButton { text: "DC25 Attack Chain" }
    }

    NuPanel {
        id: explorerStatusPanel
        visible: explorerTabs.currentIndex === 4
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Math.max(184, explorerStatusContent.implicitHeight + padding * 2) : 0
        Layout.minimumHeight: visible ? Math.max(184, explorerStatusContent.implicitHeight + padding * 2) : 0
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
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm
                        Label {
                            Layout.fillWidth: true
                            text: "Explorer index status"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        NuActionButton {
                            Layout.preferredWidth: 74
                            text: "Copy"
                            helpText: "Copy the visible Explorer index and analytics status text."
                            onClicked: {
                                NuService.copyText(NuService.explorerIndexStatus + "\n" + NuService.explorerAnalyticsStatus)
                            }
                        }
                    }
                    Basic.TextArea {
                        id: explorerIndexStatusArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(22, Math.min(44, contentHeight + 2))
                        text: NuService.explorerIndexStatus
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        activeFocusOnTab: true
                        background: Item {}
                        padding: 0
                        clip: true
                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: explorerIndexStatusArea.activeFocus && explorerIndexStatusArea.selectedText.length > 0
                            onActivated: NuService.copyText(explorerIndexStatusArea.selectedText)
                        }
                    }
                    Basic.TextArea {
                        id: explorerAnalyticsStatusArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(22, Math.min(44, contentHeight + 2))
                        text: NuService.explorerAnalyticsStatus
                        color: NuTokens.textMuted
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        activeFocusOnTab: true
                        background: Item {}
                        padding: 0
                        clip: true
                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: explorerAnalyticsStatusArea.activeFocus && explorerAnalyticsStatusArea.selectedText.length > 0
                            onActivated: NuService.copyText(explorerAnalyticsStatusArea.selectedText)
                        }
                    }
                }

                NuActionButton {
                    Layout.preferredWidth: 148
                    Layout.alignment: Qt.AlignTop
                    text: "Refresh stats"
                    helpText: "Reload holder atlas and movement summaries from the local SQLite explorer index."
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
                NuMetricRow { label: "Largest holders"; value: String(NuService.explorerRichList.length) }
                NuMetricRow { label: "Holder checkpoints"; value: String(NuService.explorerTop100TimelineEventCount) }
                NuMetricRow { label: "Movements"; value: String(NuService.explorerMovements.length) }
            }
        }
    }

    Item {
        id: explorerTabs
        Layout.fillWidth: true
        Layout.preferredHeight: 0
        visible: false
        property int currentIndex: 0
        onCurrentIndexChanged: root.maybeRefreshAnalyticsForTab()
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        currentIndex: root.contentIndexForTab(explorerTabs.currentIndex)

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
                        helpText: "Show the matching item in the Explorer results panel."
                        onClicked: NuService.searchExplorer(searchField.text)
                    }
                }

                NuPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(220, Math.min(340, root.height * 0.3))
                    visible: root.explorerResultHtml.length > 0

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: NuTokens.spaceSm

                        Label {
                            Layout.fillWidth: true
                            text: "Lookup result"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 2
                        }

                        Basic.ScrollView {
                            id: explorerResultScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: availableWidth
                            Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
                            clip: true

                            TextEdit {
                                width: Math.max(1, explorerResultScroll.availableWidth)
                                readOnly: true
                                selectByMouse: true
                                persistentSelection: true
                                textFormat: TextEdit.RichText
                                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                text: root.explorerResultHtml
                                color: NuTokens.textPrimary
                                selectedTextColor: NuTokens.textInverse
                                selectionColor: NuTokens.lineStrong
                                font.pixelSize: NuTokens.fontBody
                                onLinkActivated: NuService.openExplorerLink(link)
                            }
                        }
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

                        NuSelectableText {
                            Layout.fillWidth: true
                            text: NuService.coindroidsStatus
                            textColor: NuTokens.textSecondary
                            textPixelSize: NuTokens.fontSmall
                        }

	                Basic.ScrollView {
	                    id: coindroidsScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
                    clip: true

	                        ColumnLayout {
	                        width: Math.max(1, coindroidsScroll.availableWidth)
	                        spacing: NuTokens.spaceMd

	                        ColumnLayout {
	                            Layout.fillWidth: true
	                            visible: root.coindroidsDetailTab === 0
	                            spacing: NuTokens.spaceMd

	                        NuSelectableText {
	                            Layout.fillWidth: true
	                            text: "Coindroids ran through recognizable on-chain actions: registration or sync sends, attacks, shield and cover sends, item purchases, settlement payouts, refunds, and ammunition spillage. This view mines the local Defcoin explorer index for those patterns without depending on the dormant Coindroids API.\n\nCoindroids left two different stories on Defcoin: published contest results from the game operators, and local on-chain patterns that can be rediscovered from blocks. The headline published payout was " + root.coindroidsText("publishedLargestWinner", "ModemBot1138") + " at " + root.coindroidsText("publishedLargestWinnerAmount", "100.0605 DFC") + "; the smaller " + root.coindroidsText("largestWinnerAmountRounded", "not loaded") + " figure below is a different measurement, the largest address in the early 0.1337 DFC launch-swarm pattern."
	                            textColor: NuTokens.textPrimary
	                            textPixelSize: NuTokens.fontSmall
	                            textWeight: Font.DemiBold
	                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceLg
                            NuMetricRow { label: "Candidate DFC sent"; value: root.coindroidsText("actionAmountRounded", "Not loaded") }
                            NuMetricRow { label: "Strongest window"; value: root.coindroidsText("strongestWindowAmount", "Not loaded") }
                            NuMetricRow { label: "Published payout"; value: root.coindroidsText("publishedLargestWinnerAmount", "100.0605 DFC") }
                            NuMetricRow { label: "Launch-swarm winner"; value: root.coindroidsText("largestWinnerAmountRounded", "Not loaded") }
                            NuMetricRow { label: "Swarm DFC"; value: root.coindroidsText("launch1337AmountRounded", "Not loaded") }
                            NuMetricRow { label: "Swarm recipients"; value: root.coindroidsNumber("launch1337Recipients") }
                            NuMetricRow { label: "DEF CON windows"; value: root.coindroidsNumber("windowCount") }
                            NuMetricRow { label: "Action outputs"; value: root.coindroidsNumber("actionOutputs") }
                            NuMetricRow { label: "Candidate txs"; value: root.coindroidsNumber("actionTransactions") }
                            NuMetricRow { label: "2014 responses"; value: root.coindroidsNumber("vanityResponseCount") }
                            NuMetricRow { label: "OP_RETURN leads"; value: root.coindroidsNumber("opReturnCandidateCount") }
                            NuMetricRow { label: "Bot/reload leads"; value: root.coindroidsNumber("botCandidateCount") }
                            NuMetricRow { label: "Launch 0.01 sends"; value: root.coindroidsNumber("launch001Outputs") }
                            NuMetricRow { label: "0.1337 swarm"; value: root.coindroidsNumber("launch1337Outputs") }
                        }

		                        NuDataTable {
		                            Layout.fillWidth: true
		                            Layout.preferredHeight: 260
                            tableId: "internalExplorerCoindroidsPublishedAnchors"
                            columns: ["Published anchor", "Source event/date", "Value", "Why it matters"]
                            columnTypes: ["text", "text", "text", "text"]
                            columnWeights: [1.5, 1.05, 1.35, 3.2]
                            rows: NuService.coindroidsPublishedRows
                            emptyText: "Published Coindroids anchors appear after a Droid Trails refresh."
		                            defaultSortColumn: -1
		                        }

		                        NuSelectableText {
		                            Layout.fillWidth: true
		                            text: "DFC amounts in Droid Trails tables are rounded for readability; exact satoshi values remain in each row's metadata and linked explorer records."
		                            textColor: NuTokens.textSecondary
		                            textPixelSize: NuTokens.fontTiny
		                        }

		                        NuSelectableText {
		                            Layout.fillWidth: true
		                            text: "Winner terms are kept separate: published payout winner is from the Coindroids recap, Top Droid is the contest winner by final purse/bounty, and launch-swarm winner is the largest local recipient in the early exact-0.1337 DFC output cluster."
		                            textColor: NuTokens.textSecondary
		                            textPixelSize: NuTokens.fontSmall
		                        }

	                        RowLayout {
	                            Layout.fillWidth: true
	                            Label {
	                                Layout.fillWidth: true
	                                text: "Launch-swarm recipients"
	                                color: NuTokens.textPrimary
	                                font.pixelSize: NuTokens.fontSmall
	                                font.weight: Font.DemiBold
	                            }
	                            NuActionButton {
	                                Layout.preferredWidth: 184
	                                text: "Chart Relationships"
	                                enabled: NuService.coindroidsWinnerRows.length > 0
	                                helpText: "Load addresses from this table into a fresh relationship set and open the relationship graph."
	                                onClicked: root.chartRowsRelationships("Coindroids launch-swarm recipients", NuService.coindroidsWinnerRows)
	                            }
	                        }
	                        NuDataTable {
	                            Layout.fillWidth: true
	                            Layout.preferredHeight: 300
                            tableId: "internalExplorerCoindroidsWinners"
                            columns: ["Address", "Total", "Outputs", "Txs", "Largest", "Blocks", "Range"]
                            columnTypes: ["address", "amount", "number", "number", "amount", "number", "text"]
                            columnWeights: [3.2, 1.0, 0.7, 0.7, 0.9, 0.7, 0.9]
                            rows: NuService.coindroidsWinnerRows
                            emptyText: "0.13370000 DFC payout/spillage winners appear after a Droid Trails refresh."
                            defaultSortColumn: 1
                            defaultSortAscending: false
                            onRowActivated: (row) => root.openRow(row)
                        }

	                        NuSelectableText {
	                            Layout.fillWidth: true
	                            text: "Processing shift anchor: " + root.coindroidsText("transitionDate", "2017-07-25") + " - " + root.coindroidsText("transitionLabel", "Defcoin mempool support added") + ". Early Coindroids analysis weights exact fractional DFC outputs. Later analysis must preserve OP_RETURN payload hex/text because action type, target, and weapon semantics can move into transaction metadata while confirmations still control state changes, inventory, and payouts."
	                            textColor: NuTokens.textPrimary
	                            textPixelSize: NuTokens.fontSmall
	                            textWeight: Font.DemiBold
	                        }

                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 230
                            tableId: "internalExplorerCoindroidsPhases"
                            columns: ["Era", "Date", "Anchor", "Forensic meaning", "App signal"]
                            columnTypes: ["text", "date", "text", "text", "text"]
                            columnWeights: [1.2, 0.85, 1.0, 3.3, 1.45]
                            rows: NuService.coindroidsPhaseRows
                            emptyText: "Refresh Droid Trails to load Coindroids phase anchors."
                            defaultSortColumn: -1
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceMd

	                            NuSelectableText {
	                                Layout.fillWidth: true
	                                text: root.coindroidsSelectedDetailText()
	                                textColor: NuTokens.textSecondary
	                                textPixelSize: NuTokens.fontSmall
	                            }

                            NuActionButton {
                                Layout.preferredWidth: 118
                                text: "All windows"
                                visible: root.coindroidsWindowZoomed
                                helpText: "Return the Droid Trails chart to the DEF CON window comparison."
                                onClicked: root.clearCoindroidsWindowZoom()
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 340
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            border.width: 1
                            radius: NuTokens.radiusSmall
                            Canvas {
                                id: coindroidsWindowChart
                                anchors.fill: parent
                                anchors.margins: NuTokens.spaceMd
                                onPaint: root.drawCoindroidsWindowChart(getContext("2d"), width, height)

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: root.hoveredCoindroidsWindowIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    ToolTip.visible: containsMouse && root.coindroidsWindowToolTip(root.hoveredCoindroidsWindowIndex).length > 0
                                    ToolTip.text: root.coindroidsWindowToolTip(root.hoveredCoindroidsWindowIndex)
                                    ToolTip.delay: NuTokens.tooltipDelay
                                    ToolTip.timeout: NuTokens.tooltipTimeout
                                    onPositionChanged: (mouse) => {
                                        root.hoveredCoindroidsWindowIndex = root.coindroidsWindowIndexAt(mouse.x, mouse.y, coindroidsWindowChart.width, coindroidsWindowChart.height)
                                        coindroidsWindowChart.requestPaint()
                                        if (coindroidsChartPopoutCanvas)
                                            coindroidsChartPopoutCanvas.requestPaint()
                                    }
                                    onExited: {
                                        root.hoveredCoindroidsWindowIndex = -1
                                        coindroidsWindowChart.requestPaint()
                                        if (coindroidsChartPopoutCanvas)
                                            coindroidsChartPopoutCanvas.requestPaint()
                                    }
                                    onClicked: (mouse) => {
                                        const index = root.coindroidsWindowIndexAt(mouse.x, mouse.y, coindroidsWindowChart.width, coindroidsWindowChart.height)
                                        if (index >= 0)
                                            root.selectCoindroidsWindow(index)
                                    }
                                }
                            }
                        }

	                        NuSelectableText {
	                            Layout.fillWidth: true
	                            text: "The strongest local signal is the DEF CON 22 launch cluster: " + root.coindroidsNumber("launch001Outputs") + " exact 0.01 DFC action-cost outputs and " + root.coindroidsNumber("launch1337Outputs") + " exact 0.13370000 DFC payout/spillage outputs to " + root.coindroidsNumber("launch1337Recipients") + " addresses."
	                            textColor: NuTokens.textSecondary
	                            textPixelSize: NuTokens.fontSmall
	                        }

                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 230
                            tableId: "internalExplorerCoindroidsWindows"
                            columns: ["Window", "Blocks", "Dates", "Outputs", "Txs", "Addresses", "DFC*", "0.01", "0.1337", "Signal"]
                            columnTypes: ["text", "text", "date", "number", "number", "number", "amount", "number", "number", "text"]
                            columnWeights: [1.7, 1.0, 1.25, 0.72, 0.7, 0.82, 0.9, 0.56, 0.72, 1.15]
                            rows: NuService.coindroidsWindowRows
                            emptyText: "Refresh Droid Trails to calculate Coindroids candidate windows."
                            defaultSortColumn: -1
                            onRowActivated: (row) => root.selectCoindroidsWindowFromRow(row)
                        }

                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 260
                            tableId: "internalExplorerCoindroidsVanityResponses"
                            columns: ["Txid", "Block", "Date", "Roles", "Outputs", "Decoded stats", "Stat dust"]
                            columnTypes: ["hash", "number", "date", "number", "number", "text", "amount"]
                            columnWeights: [2.4, 0.7, 1.35, 0.55, 0.65, 3.4, 0.8]
                            rows: NuService.coindroidsVanityRows
                            emptyText: "No 2014 vanity battle-response candidates found in the indexed range yet."
                            defaultSortColumn: 1
                            defaultSortAscending: true
                            onRowActivated: (row) => root.openRow(row)
                        }

                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 280
                            tableId: "internalExplorerCoindroidsOpReturn"
                            columns: ["Txid", "Vout", "Block", "Date", "Window", "Bytes", "DFC", "Payload preview"]
                            columnTypes: ["hash", "number", "number", "date", "text", "number", "amount", "text"]
                            columnWeights: [2.4, 0.45, 0.65, 1.35, 1.0, 0.5, 0.75, 3.2]
                            rows: NuService.coindroidsOpReturnRows
                            emptyText: "No post-pivot OP_RETURN payload candidates are indexed yet. Reindex after this build to populate the OP_RETURN table from raw block scriptPubKeys."
                            defaultSortColumn: 2
	                            defaultSortAscending: true
	                            onRowActivated: (row) => root.openRow(row)
	                        }

	                        RowLayout {
	                            Layout.fillWidth: true
	                            Label {
	                                Layout.fillWidth: true
	                                text: "Candidate endpoints"
	                                color: NuTokens.textPrimary
	                                font.pixelSize: NuTokens.fontSmall
	                                font.weight: Font.DemiBold
	                            }
	                            NuActionButton {
	                                Layout.preferredWidth: 184
	                                text: "Chart Relationships"
	                                enabled: NuService.coindroidsEndpointRows.length > 0
	                                helpText: "Load endpoint addresses from this table into a fresh relationship set and open the relationship graph."
	                                onClicked: root.chartRowsRelationships("Coindroids endpoint candidates", NuService.coindroidsEndpointRows)
	                            }
	                        }
	                        NuDataTable {
	                            Layout.fillWidth: true
	                            Layout.preferredHeight: 320
                            tableId: "internalExplorerCoindroidsEndpoints"
                            columns: ["Kind", "Window", "Address", "Amount", "Outputs", "Txs", "Total", "Blocks"]
                            columnTypes: ["text", "text", "address", "amount", "number", "number", "amount", "text"]
                            columnWeights: [1.45, 1.1, 3.0, 0.9, 0.65, 0.6, 1.0, 0.9]
                            rows: NuService.coindroidsEndpointRows
                            emptyText: "Candidate Coindroids endpoints appear after a Droid Trails refresh."
                            defaultSortColumn: 4
                            defaultSortAscending: false
                            onRowActivated: (row) => root.openRow(row)
                        }

                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            tableId: "internalExplorerCoindroidsBotReload"
                            columns: ["Signal", "Focus", "Window / block", "Amount", "Outputs", "Txs/Addrs", "Total", "Evidence"]
                            columnTypes: ["text", "hash", "text", "amount", "number", "number", "amount", "text"]
                            columnWeights: [1.35, 2.6, 1.2, 0.9, 0.65, 0.75, 0.9, 3.0]
                            rows: NuService.coindroidsBotRows
                            emptyText: "No bot/reload candidates found yet. These are neutral automation-shape leads, not accusations."
                            defaultSortColumn: 4
                            defaultSortAscending: false
                            onRowActivated: (row) => root.openRow(row)
                        }

                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 230
                            tableId: "internalExplorerCoindroidsEvidence"
                            columns: ["Signal", "Detection rule", "Confidence"]
                            columnTypes: ["text", "text", "text"]
                            columnWeights: [1.1, 3.8, 1.0]
                            rows: NuService.coindroidsEvidenceRows
	                            emptyText: "Detection rules appear after a Droid Trails refresh."
	                            defaultSortColumn: -1
	                        }
	                        }

	                        ColumnLayout {
	                            Layout.fillWidth: true
	                            visible: root.coindroidsDetailTab === 1
	                            spacing: NuTokens.spaceMd

		                            NuSelectableText {
		                                Layout.fillWidth: true
		                                text: "DC25 Payout Hunt treats the published Coindroids leaderboard as a point-in-time contest record. It looks for addresses whose historical balance reached a listed amount during the DC25 game and settlement window, then scores supporting signals such as exact payout-size outputs and repeated action-range activity."
		                                textColor: NuTokens.textPrimary
		                                textPixelSize: NuTokens.fontSmall
		                                textWeight: Font.DemiBold
		                            }

	                            Flow {
	                                Layout.fillWidth: true
	                                spacing: NuTokens.spaceLg
	                                NuMetricRow { label: "Payout leads"; value: root.coindroidsNumber("payoutCandidateCount") }
	                                NuMetricRow { label: "Game address leads"; value: root.coindroidsNumber("gameAddressLeadCount") }
	                                NuMetricRow { label: "Published top subset"; value: root.coindroidsText("dc25PublishedTopPayoutTotal", "206.2045 DFC") }
	                                NuMetricRow { label: "Published payout total"; value: root.coindroidsText("dc25PublishedOverallPayoutTotal", "227.046 DFC") }
	                            }

		                            NuSelectableText {
		                                Layout.fillWidth: true
		                                text: root.coindroidsText("dc25PayoutHuntNote", "Published DC25 payout values are treated as point-in-time contest/payout measurements. The scanner looks for historical balances reached during the DC25 settlement window, not final or current wallet balances.")
		                                textColor: NuTokens.textSecondary
		                                textPixelSize: NuTokens.fontSmall
		                            }

	                            RowLayout {
	                                Layout.fillWidth: true
	                                spacing: NuTokens.spaceMd
		                                NuSelectableText {
		                                    Layout.fillWidth: true
		                                    text: "Exact amount hits are still only leads when several addresses collide on the same amount. Near hits are useful for reconstructing gameplay, but require human review before naming an address as a player."
		                                    textColor: NuTokens.textSecondary
		                                    textPixelSize: NuTokens.fontSmall
		                                }
	                                NuActionButton {
	                                    Layout.preferredWidth: 156
	                                    text: "Save to Contacts"
	                                    primary: true
	                                    enabled: NuService.coindroidsGameAddressRows.length > 0
	                                    helpText: "Append Coindroids game-address leads to the active Explorer Contacts set without overwriting existing contacts."
	                                    onClicked: NuService.importCoindroidsGameContacts()
	                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 172
		                                    text: "Chart Relationships"
		                                    enabled: NuService.coindroidsAttackAddressRows.length > 0
		                                    helpText: "Load the prebuilt DC25 investigation contact set and open its relationship chart."
		                                    onClicked: root.chartCoindroidsRelations("dc25-investigation")
		                                }
		                            }

		                            RowLayout {
		                                Layout.fillWidth: true
		                                Label {
		                                    Layout.fillWidth: true
		                                    text: "Payout candidates"
		                                    color: NuTokens.textPrimary
		                                    font.pixelSize: NuTokens.fontSmall
		                                    font.weight: Font.DemiBold
		                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 184
		                                    text: "Chart Relationships"
		                                    enabled: NuService.coindroidsPayoutRows.length > 0
		                                    helpText: "Load payout candidate addresses from this table into a fresh relationship set and open the relationship graph."
		                                    onClicked: root.chartRowsRelationships("Coindroids DC25 payout candidates", NuService.coindroidsPayoutRows)
		                                }
		                            }
		                            NuDataTable {
		                                Layout.fillWidth: true
		                                Layout.preferredHeight: 360
	                                tableId: "internalExplorerCoindroidsDc25PayoutHunt"
	                                columns: ["Droid", "Published", "Candidate address", "Point balance", "At block / date", "Difference", "Confidence", "Evidence"]
	                                columnTypes: ["text", "amount", "address", "amount", "text", "text", "text", "text"]
	                                columnWeights: [1.0, 0.85, 2.4, 1.0, 1.55, 0.85, 0.85, 3.5]
	                                rows: NuService.coindroidsPayoutRows
	                                emptyText: "Refresh Droid Trails to run the DC25 historical point-balance payout hunt."
	                                defaultSortColumn: 6
		                                defaultSortAscending: true
		                                onRowActivated: (row) => root.openRow(row)
		                            }

		                            RowLayout {
		                                Layout.fillWidth: true
		                                Label {
		                                    Layout.fillWidth: true
		                                    text: "Game address leads"
		                                    color: NuTokens.textPrimary
		                                    font.pixelSize: NuTokens.fontSmall
		                                    font.weight: Font.DemiBold
		                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 184
		                                    text: "Chart Relationships"
		                                    enabled: NuService.coindroidsGameAddressRows.length > 0
		                                    helpText: "Load game-address leads from this table into a fresh relationship set and open the relationship graph."
		                                    onClicked: root.chartRowsRelationships("Coindroids game address leads", NuService.coindroidsGameAddressRows)
		                                }
		                            }
		                            NuDataTable {
		                                Layout.fillWidth: true
		                                Layout.preferredHeight: 360
	                                tableId: "internalExplorerCoindroidsGameAddressLeads"
	                                columns: ["Role", "Name", "Address", "Amount / marker", "Score", "Confidence", "Evidence"]
	                                columnTypes: ["text", "text", "address", "text", "number", "text", "text"]
	                                columnWeights: [1.35, 1.05, 2.4, 0.95, 0.55, 0.8, 3.4]
	                                rows: NuService.coindroidsGameAddressRows
		                                emptyText: "Refresh Droid Trails to load named leads, payout leads, and action-pattern address leads."
	                                defaultSortColumn: 4
	                                defaultSortAscending: false
	                                onRowActivated: (row) => root.openRow(row)
	                            }
	                        }

	                        ColumnLayout {
	                            Layout.fillWidth: true
	                            visible: root.coindroidsDetailTab === 2
	                            spacing: NuTokens.spaceMd

		                            NuSelectableText {
		                                Layout.fillWidth: true
		                                text: "The DC25 chain-forensics pass turns the Coindroids story from a payout list into an address ecosystem: eight named DC25 leads including Olo, a broad attack-address cohort matching the published 65 fully activated droids, stricter exact-amount signature candidates, and funding source/ammo clips."
		                                textColor: NuTokens.textPrimary
		                                textPixelSize: NuTokens.fontSmall
		                                textWeight: Font.DemiBold
		                            }

	                            Flow {
	                                Layout.fillWidth: true
	                                spacing: NuTokens.spaceLg
	                                NuMetricRow { label: "Attack rows"; value: root.coindroidsNumber("dc25AttackAddressRowCount") }
	                                NuMetricRow { label: "Broad cohort"; value: root.coindroidsNumber("broadCandidateCount") }
	                                NuMetricRow { label: "Strict signatures"; value: root.coindroidsNumber("strictSignatureActualCount") }
		                                NuMetricRow { label: "Named leads"; value: root.coindroidsNumber("dc25NamedLeadCount") }
	                                NuMetricRow { label: "Source clips"; value: root.coindroidsNumber("dc25SourceAmmoRowCount") }
	                                NuMetricRow { label: "Candidate DFC"; value: root.coindroidsDfcSummary("candidateDfcTotal", 2) }
	                                NuMetricRow { label: "QR DC25 DFC"; value: root.coindroidsDfcSummary("qrDc25DfcTotal", 2) }
	                                NuMetricRow { label: "Top source txs"; value: root.coindroidsNumber("topSourceAttackTxs") }
	                            }

		                            NuSelectableText {
		                                Layout.fillWidth: true
		                                text: root.coindroidsText("addressEncodingNote", "QR-card addresses are legacy 3... P2SH encodings. Nu Explore indexes the same scripts as current M... P2SH addresses; both forms are shown when available.")
		                                textColor: NuTokens.textSecondary
		                                textPixelSize: NuTokens.fontSmall
		                            }

	                            Flow {
	                                Layout.fillWidth: true
	                                spacing: NuTokens.spaceMd
	                                NuActionButton {
	                                    Layout.preferredWidth: 136
		                                    text: "Chart 8 leads"
		                                    enabled: NuService.coindroidsQrSeedRows.length > 0
		                                    helpText: "Load the eight named DC25 leads, including Olo, as a saved Contact Set and open the relationship chart."
		                                    onClicked: root.chartCoindroidsRelations("dc25-qr-seeds")
	                                }
	                                NuActionButton {
	                                    Layout.preferredWidth: 162
	                                    text: "Chart cohort"
	                                    primary: true
	                                    enabled: NuService.coindroidsAttackAddressRows.length > 0
	                                    helpText: "Load the DC25 attack-address cohort as a saved Contact Set and open the relationship chart."
	                                    onClicked: root.chartCoindroidsRelations("dc25-attack-cohort")
	                                }
	                                NuActionButton {
	                                    Layout.preferredWidth: 168
	                                    text: "Chart sources"
	                                    enabled: NuService.coindroidsSourceAmmoRows.length > 0
	                                    helpText: "Load source/ammo-clip addresses as a saved Contact Set and open the relationship chart."
	                                    onClicked: root.chartCoindroidsRelations("dc25-source-ammo")
	                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 132
		                                    text: "Chart Olo"
		                                    enabled: NuService.coindroidsOloRows.length > 0
		                                    helpText: "Load Olo as its own Contact Set and open the relationship chart."
		                                    onClicked: root.chartCoindroidsRelations("dc25-olo")
		                                }
	                                NuActionButton {
	                                    Layout.preferredWidth: 154
	                                    text: "Chart all DC25"
	                                    enabled: NuService.coindroidsAttackAddressRows.length > 0
	                                    helpText: "Load the combined DC25 investigation Contact Set and open the relationship chart."
	                                    onClicked: root.chartCoindroidsRelations("dc25-investigation")
	                                }
	                                NuActionButton {
	                                    Layout.preferredWidth: 116
	                                    text: "Pop out"
	                                    enabled: NuService.coindroidsAttackAddressRows.length > 0
	                                    helpText: "Open the DC25 attack-address cohort chart in a larger window."
	                                    onClicked: root.showChartWindow(coindroidsAttackWindow)
	                                }
	                                NuActionButton {
	                                    Layout.preferredWidth: 116
	                                    text: "PDF"
	                                    helpText: "Open the bundled Coindroids forensics story report placeholder in the default macOS PDF app."
	                                    onClicked: NuService.openCoindroidsReportPdf()
	                                }
	                            }

	                            Rectangle {
	                                Layout.fillWidth: true
	                                Layout.preferredHeight: 340
	                                color: NuTokens.backgroundBase
	                                border.color: NuTokens.lineSubtle
	                                border.width: 1
	                                radius: NuTokens.radiusSmall
	                                Canvas {
	                                    id: coindroidsAttackChart
	                                    anchors.fill: parent
	                                    anchors.margins: NuTokens.spaceMd
	                                    onPaint: root.drawCoindroidsAttackChart(getContext("2d"), width, height)

	                                    MouseArea {
	                                        anchors.fill: parent
	                                        hoverEnabled: true
	                                        cursorShape: root.hoveredCoindroidsAttackIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
	                                        ToolTip.visible: containsMouse && root.coindroidsAttackToolTip(root.hoveredCoindroidsAttackIndex).length > 0
	                                        ToolTip.text: root.coindroidsAttackToolTip(root.hoveredCoindroidsAttackIndex)
	                                        ToolTip.delay: NuTokens.tooltipDelay
	                                        ToolTip.timeout: NuTokens.tooltipTimeout
	                                        onPositionChanged: (mouse) => {
	                                            root.hoveredCoindroidsAttackIndex = root.coindroidsAttackIndexAt(mouse.x, mouse.y, coindroidsAttackChart.width, coindroidsAttackChart.height)
	                                            root.requestCoindroidsChartRepaint()
	                                        }
	                                        onExited: {
	                                            root.hoveredCoindroidsAttackIndex = -1
	                                            root.requestCoindroidsChartRepaint()
	                                        }
	                                        onClicked: (mouse) => root.openCoindroidsAttackAddress(root.coindroidsAttackIndexAt(mouse.x, mouse.y, coindroidsAttackChart.width, coindroidsAttackChart.height))
	                                    }
	                                }
	                            }

		                            NuSelectableText {
		                                Layout.fillWidth: true
		                                text: root.coindroidsText("oloNote", "Olo is included as the eighth named DC25 lead. The clipped-address evidence aligns with the chain signature and current indexed M-form address.")
		                                textColor: NuTokens.textSecondary
		                                textPixelSize: NuTokens.fontSmall
		                            }

		                            RowLayout {
		                                Layout.fillWidth: true
		                                Label {
		                                    Layout.fillWidth: true
		                                    text: "Eight named DC25 leads"
		                                    color: NuTokens.textPrimary
		                                    font.pixelSize: NuTokens.fontSmall
		                                    font.weight: Font.DemiBold
		                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 184
		                                    text: "Chart Relationships"
		                                    enabled: root.coindroidsQrLeadRows().length > 0
		                                    helpText: "Load the eight named DC25 lead addresses from this table into a fresh relationship set and open the relationship graph."
		                                    onClicked: root.chartRowsRelationships("Coindroids DC25 named leads", root.coindroidsQrLeadRows())
		                                }
		                            }
		                            NuDataTable {
		                                Layout.fillWidth: true
		                                Layout.preferredHeight: 300
	                                tableId: "internalExplorerCoindroidsQrSeeds"
	                                columns: ["Droid", "Legacy QR P2SH", "Indexed M P2SH", "DC25 outs", "DC25 DFC", "Photo outs", "Photo DFC", "Blocks", "UTC range"]
	                                columnTypes: ["text", "address", "address", "number", "amount", "number", "amount", "text", "date"]
	                                columnWeights: [0.9, 2.1, 2.1, 0.7, 0.85, 0.72, 0.85, 0.8, 1.7]
		                                rows: root.coindroidsQrLeadRows()
		                                emptyText: "Refresh Droid Trails to load the eight named DC25 lead addresses."
	                                defaultSortColumn: 3
		                                defaultSortAscending: false
		                                onRowActivated: (row) => root.openRow(row)
		                            }

		                            RowLayout {
		                                Layout.fillWidth: true
		                                Label {
		                                    Layout.fillWidth: true
		                                    text: "Attack-address cohort"
		                                    color: NuTokens.textPrimary
		                                    font.pixelSize: NuTokens.fontSmall
		                                    font.weight: Font.DemiBold
		                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 184
		                                    text: "Chart Relationships"
		                                    enabled: NuService.coindroidsAttackAddressRows.length > 0
		                                    helpText: "Load attack-address cohort rows into a fresh relationship set and open the relationship graph."
		                                    onClicked: root.chartRowsRelationships("Coindroids DC25 attack-address cohort", NuService.coindroidsAttackAddressRows)
		                                }
		                            }
		                            NuDataTable {
		                                Layout.fillWidth: true
		                                Layout.preferredHeight: 360
	                                tableId: "internalExplorerCoindroidsAttackAddresses"
	                                columns: ["Name / lead", "Legacy 3-form", "Indexed M-form", "Outputs", "DC25 DFC", "Signature outs", "Ratio", "Blocks", "Confidence"]
	                                columnTypes: ["text", "address", "address", "number", "amount", "number", "number", "text", "text"]
	                                columnWeights: [1.1, 2.05, 2.05, 0.65, 0.82, 0.8, 0.55, 0.8, 1.2]
	                                rows: NuService.coindroidsAttackAddressRows
	                                emptyText: "Refresh Droid Trails to load the 65-address DC25 attack cohort and signature candidates."
	                                defaultSortColumn: 3
		                                defaultSortAscending: false
		                                onRowActivated: (row) => root.openRow(row)
		                            }

		                            RowLayout {
		                                Layout.fillWidth: true
		                                Label {
		                                    Layout.fillWidth: true
		                                    text: "Source/ammo clips"
		                                    color: NuTokens.textPrimary
		                                    font.pixelSize: NuTokens.fontSmall
		                                    font.weight: Font.DemiBold
		                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 184
		                                    text: "Chart Relationships"
		                                    enabled: NuService.coindroidsSourceAmmoRows.length > 0
		                                    helpText: "Load source/ammo addresses from this table into a fresh relationship set and open the relationship graph."
		                                    onClicked: root.chartRowsRelationships("Coindroids DC25 source ammo", NuService.coindroidsSourceAmmoRows)
		                                }
		                            }
		                            NuDataTable {
		                                Layout.fillWidth: true
		                                Layout.preferredHeight: 330
	                                tableId: "internalExplorerCoindroidsSourceAmmo"
	                                columns: ["Source address", "Attack txs", "Input UTXOs", "Targets", "Input DFC", "Source blocks", "Score"]
	                                columnTypes: ["address", "number", "number", "number", "amount", "text", "number"]
	                                columnWeights: [2.8, 0.75, 0.75, 0.65, 1.1, 0.95, 0.55]
	                                rows: NuService.coindroidsSourceAmmoRows
	                                emptyText: "Refresh Droid Trails to load source/ammo-clip candidates."
	                                defaultSortColumn: 1
		                                defaultSortAscending: false
		                                onRowActivated: (row) => root.openRow(row)
		                            }

		                            RowLayout {
		                                Layout.fillWidth: true
		                                Label {
		                                    Layout.fillWidth: true
		                                    text: "Olo"
		                                    color: NuTokens.textPrimary
		                                    font.pixelSize: NuTokens.fontSmall
		                                    font.weight: Font.DemiBold
		                                }
		                                NuActionButton {
		                                    Layout.preferredWidth: 184
		                                    text: "Chart Relationships"
		                                    enabled: NuService.coindroidsOloRows.length > 0
		                                    helpText: "Load Olo from this table into a fresh relationship set and open the relationship graph."
		                                    onClicked: root.chartRowsRelationships("Coindroids DC25 Olo", NuService.coindroidsOloRows)
		                                }
		                            }
		                            NuDataTable {
		                                Layout.fillWidth: true
		                                Layout.preferredHeight: 170
	                                tableId: "internalExplorerCoindroidsOlo"
	                                columns: ["Lead", "Legacy 3-form", "Indexed M-form", "Outputs", "DC25 DFC", "Signature outs", "Ratio", "Status", "Notes"]
	                                columnTypes: ["text", "address", "address", "number", "amount", "number", "number", "text", "text"]
	                                columnWeights: [0.9, 2.0, 2.0, 0.6, 0.8, 0.72, 0.5, 0.95, 2.5]
	                                rows: NuService.coindroidsOloRows
		                                emptyText: "Refresh Droid Trails to load Olo."
	                                defaultSortColumn: -1
	                                onRowActivated: (row) => root.openRow(row)
	                            }
	                        }
	                    }
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
                        helpText: "Clear only the block, transaction, Holder Atlas, and movement index. Recent manual lookups are kept."
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm
                    Label {
                        Layout.fillWidth: true
                        text: "Holder timeline index"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 74
                        text: "Copy"
                        helpText: "Copy the holder timeline status or error text."
                        onClicked: {
                            NuService.copyText(NuService.explorerTop100Status)
                        }
                    }
                }

                Basic.TextArea {
                    id: top100StatusArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(24, Math.min(56, contentHeight + 2))
                    text: NuService.explorerTop100Status
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    activeFocusOnTab: true
                    background: Item {}
                    padding: 0
                    Shortcut {
                        sequences: [StandardKey.Copy]
                        enabled: top100StatusArea.activeFocus && top100StatusArea.selectedText.length > 0
                        onActivated: NuService.copyText(top100StatusArea.selectedText)
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Holder timeline can scan through block " + NuService.explorerIndexTip + ", the Explorer indexed height."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
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
                        helpText: "First block height to include when rebuilding the sparse holder over-time index."
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
                        onTextChanged: {
                            if (activeFocus && !root.top100UpdatingEndField)
                                root.top100EndEdited = true
                        }
                        Component.onCompleted: root.initializeTop100EndField(false)
                    }
                    NuActionButton {
                        width: 132
                        text: NuService.explorerTop100Scanning ? "Scanning" : "Start scan"
                        enabled: !NuService.explorerTop100Scanning && !NuService.explorerIndexing
                        primary: enabled
                        helpText: "Build the exact sparse holder timeline from local balance deltas."
                        onClicked: NuService.startExplorerTop100Timeline(parseInt(top100StartField.text) || 0,
                                                                          top100EndField.text.length > 0 ? parseInt(top100EndField.text) : NuService.explorerIndexTip)
                    }
                    NuActionButton {
                        width: 112
                        text: "Pause scan"
                        enabled: NuService.explorerTop100Scanning
                        helpText: "Pause the holder timeline scan after the current chunk."
                        onClicked: NuService.stopExplorerTop100Timeline()
                    }
                    NuActionButton {
                        width: 152
                        text: "Scan remaining"
                        enabled: !NuService.explorerTop100Scanning && !NuService.explorerIndexing
                        helpText: "Scan the next missing holder timeline range between block 0 and the indexed tip."
                        onClicked: NuService.scanRemainingExplorerTop100Timeline()
                    }
                    NuActionButton {
                        width: 138
                        text: "Clear timeline"
                        enabled: !NuService.explorerTop100Scanning && !NuService.explorerIndexing
                        danger: true
                        helpText: "Delete only the holder over-time checkpoint rows and ranges."
                        onClicked: NuService.resetExplorerTop100Timeline()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    spacing: NuTokens.spaceMd

                    NuCheckBox {
                        text: "High intensity (uses more resources)"
                        checked: NuService.explorerTop100FocusedIndexing
                        helpText: "When enabled, Nu uses larger Explorer and Holder Atlas batches, larger SQLite cache settings, fewer UI refreshes, and tries to raise indexing priority. Use this for a dedicated indexing run on a mostly idle machine."
                        onToggled: NuService.explorerTop100FocusedIndexing = checked
                    }

                    Label {
                        Layout.fillWidth: true
                        text: NuService.explorerTop100FocusedIndexing
                              ? "High intensity is active; Nu will favor indexing speed over lighter background behavior."
                              : "Cooperative mode backs off only when system load is already high."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
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
            Basic.ScrollView {
                id: top100Scroll
                anchors.fill: parent
                clip: true
                contentWidth: availableWidth

            ColumnLayout {
                width: Math.max(820, top100Scroll.availableWidth)
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg

                    Canvas {
                        id: richPie
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 220
                        onPaint: root.drawRichPie(getContext("2d"), width, height)

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            ToolTip.visible: containsMouse && root.richHoverText(root.hoveredRichRank).length > 0
                            ToolTip.text: root.richHoverText(root.hoveredRichRank)
                            ToolTip.delay: NuTokens.tooltipDelay
                            ToolTip.timeout: NuTokens.tooltipTimeout
                            onPositionChanged: (mouse) => {
                                root.hoveredRichRank = root.richSliceAt(mouse.x, mouse.y, richPie.width, richPie.height)
                            }
                            onExited: root.hoveredRichRank = -1
                            onClicked: (mouse) => {
                                const rank = root.richSliceAt(mouse.x, mouse.y, richPie.width, richPie.height)
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
                            text: "Largest Holders"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "The richest indexed addresses ranked by current unspent balance. This is the direct holder leaderboard and is complete only through the indexed block height shown above."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceMd
                            NuActionButton {
                                width: 150
                                text: "Refresh holders"
                                enabled: NuService.explorerIndexedBlockCount > 0
                                         && NuService.explorerIndexTip > 0
                                         && NuService.explorerIndexHeight > NuService.explorerIndexTip
                                         && !NuService.explorerIndexing
                                helpText: "Reload the largest-holder table after the local Explorer index is complete, usually after new blocks arrive."
                                onClicked: root.refreshAnalytics("rich")
                            }
                            NuActionButton {
                                width: 118
                                text: "Timeline"
                                enabled: NuService.explorerTop100TimelineEventCount > 0
                                helpText: "Open the sparse largest-holder over-time animation window."
                                onClicked: {
                                    root.loadTimelineSnapshotAtPosition(1)
                                    root.showChartWindow(top100TimelineWindow)
                                }
                            }
                            NuActionButton {
                                width: 118
                                text: "Pop out"
                                helpText: "Open the largest-holder pie in a maximized chart window."
                                onClicked: root.showChartWindow(holderPieWindow)
                            }
                            NuMetricRow { label: "Rows"; value: String(NuService.explorerRichList.length) }
                            NuMetricRow { label: "Coverage"; value: NuService.explorerIndexedBlockCount + " blocks" }
                            NuMetricRow { label: "Timeline"; value: NuService.explorerTop100TimelineEventCount + " checkpoints" }
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: NuService.explorerIndexing || NuService.explorerIndexHeight <= NuService.explorerIndexTip
                            text: "Refresh holders enables after the Explorer index reaches the current chain tip; until then this pane shows the latest cached partial result."
                            color: NuTokens.textMuted
                            font.pixelSize: NuTokens.fontTiny
                            wrapMode: Text.WordWrap
                        }
                        Basic.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(22, Math.min(48, contentHeight + 2))
                            text: NuService.explorerAnalyticsStatus
                            color: NuTokens.textMuted
                            font.pixelSize: NuTokens.fontTiny
                            wrapMode: Text.WordWrap
                            readOnly: true
                            selectByMouse: true
                            persistentSelection: true
                            background: Item {}
                            padding: 0
                            Shortcut {
                                sequences: [StandardKey.Copy]
                                enabled: activeFocus && selectedText.length > 0
                                onActivated: NuService.copyText(selectedText)
                            }
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 520
                    tableId: "internalExplorerRichList"
                    columns: ["", "Rank", "Address", "Balance", "Share", "Received", "Txs", "UTXOs"]
                    columnTooltips: [
                        "Pie-chart color used for this rich-list entry.",
                        "Current rank by unspent balance.",
                        "Defcoin address in the local Explorer index.",
                        "Current unspent balance for this address.",
                        "Share of the indexed spendable supply represented by this address.",
                        "Total DFC received by outputs to this address in the local Explorer index.",
                        "Transactions touching this address in the local Explorer index. One transaction can create or spend several outputs, so this is related to UTXOs but not the same count.",
                        "Unspent transaction outputs currently controlled by this address. UTXOs are individual spendable pieces; mining payouts often create many small UTXOs, while later consolidation can reduce UTXOs without reducing transaction history."
                    ]
                    columnTypes: ["swatch", "number", "address", "amount", "number", "amount", "number", "number"]
                    columnWeights: [0.25, 0.45, 3.1, 1.1, 0.75, 1.1, 0.55, 0.55]
                    rows: NuService.explorerRichList
                    emptyText: "Largest holders appear after the Explorer index contains spendable outputs."
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: NuTokens.lineSubtle
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Supply Bands"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 118
                        text: "Pop out"
                        helpText: "Open the Supply Bands pie in a maximized chart window."
                        onClicked: root.showChartWindow(supplyBandsWindow)
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "A banded view of how indexed supply is split across the first 25, next 25, third 25, fourth 25, and all other addresses."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    Canvas {
                        id: wealthDistributionPie
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 260
                        onPaint: root.drawDistributionPie(getContext("2d"), width, height, root.wealthDistributionRows(), "Supply", "bands", root.selectedWealthGroup)
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: (mouse) => {
                                const label = root.distributionSliceAt(mouse.x, mouse.y, wealthDistributionPie.width, wealthDistributionPie.height, root.wealthDistributionRows())
                                root.selectedWealthGroup = root.selectedWealthGroup === label ? "" : label
                                wealthDistributionPie.requestPaint()
                            }
                        }
                    }
                    NuDataTable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 360
                        tableId: "internalExplorerWealthDistribution"
                        columns: ["", "Group", "Amount", "%"]
                        columnTypes: ["swatch", "text", "amount", "number"]
                        columnWeights: [0.25, 1.4, 1.2, 0.55]
                        rows: root.wealthDistributionRows()
                        emptyText: "Build the Explorer index and refresh holders to calculate supply bands."
                        defaultSortColumn: -1
                        rowSelectionEnabled: true
                        plainClickSelectsRows: true
                        rowKeyMetaField: "label"
                        onRowSelectionChanged: (keys) => {
                            root.selectedWealthGroup = keys.length > 0 ? String(keys[0]) : ""
                            wealthDistributionPie.requestPaint()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Whale Lens"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 118
                        text: "Pop out"
                        helpText: "Open the Whale Lens pie in a maximized chart window."
                        onClicked: root.showChartWindow(whaleLensWindow)
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "A concentration view that isolates the largest address, ranks 2-10, ranks 11-25, ranks 26-100, and everyone else."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    Canvas {
                        id: whaleConcentrationPie
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 260
                        onPaint: root.drawDistributionPie(getContext("2d"), width, height, root.whaleConcentrationRows(), "Whale", "lens", root.selectedWhaleGroup)
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: (mouse) => {
                                const label = root.distributionSliceAt(mouse.x, mouse.y, whaleConcentrationPie.width, whaleConcentrationPie.height, root.whaleConcentrationRows())
                                root.selectedWhaleGroup = root.selectedWhaleGroup === label ? "" : label
                                whaleConcentrationPie.requestPaint()
                            }
                        }
                    }
                    NuDataTable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260
                        tableId: "internalExplorerWhaleConcentration"
                        columns: ["", "Group", "Amount", "%"]
                        columnTypes: ["swatch", "text", "amount", "number"]
                        columnWeights: [0.25, 1.4, 1.2, 0.55]
                        rows: root.whaleConcentrationRows()
                        emptyText: "Build the Explorer index and refresh holders to calculate concentration."
                        defaultSortColumn: -1
                        rowSelectionEnabled: true
                        plainClickSelectsRows: true
                        rowKeyMetaField: "label"
                        onRowSelectionChanged: (keys) => {
                            root.selectedWhaleGroup = keys.length > 0 ? String(keys[0]) : ""
                            whaleConcentrationPie.requestPaint()
                        }
                    }
                }
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
                            text: "Large non-coinbase flow outputs from the local explorer index. Adjust the DFC threshold, then refresh."
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
                        helpText: "Minimum output value to include in movement rows."
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.refreshAnalytics("movements")
                                event.accepted = true
                            }
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: "Refresh"
                        primary: true
                        helpText: "Reload movement rows using the selected DFC threshold."
                        onClicked: root.refreshAnalytics("movements")
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 380
                    color: NuTokens.backgroundBase
                    border.color: NuTokens.lineSubtle
                    border.width: 1
                    radius: NuTokens.radiusSmall

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: NuTokens.spaceMd
                        spacing: NuTokens.spaceSm

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceMd

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 220
                                spacing: 2
                                Label {
                                    Layout.fillWidth: true
                                    text: "Movement network"
                                    color: NuTokens.textPrimary
                                    font.pixelSize: NuTokens.fontBodyLarge
                                    font.weight: Font.DemiBold
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: "Charts source-to-destination address flow from loaded high-value outputs. Node size follows total plotted DFC flow."
                                    color: NuTokens.textSecondary
                                    font.pixelSize: NuTokens.fontSmall
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                }
                            }

                            Flow {
                                Layout.maximumWidth: 650
                                Layout.preferredWidth: Math.min(650, Math.max(360, root.width * 0.46))
                                Layout.preferredHeight: implicitHeight
                                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                                spacing: NuTokens.spaceMd

                                RowLayout {
                                    spacing: NuTokens.spaceSm
                                    Label {
                                        text: "Sort"
                                        color: NuTokens.textSecondary
                                        font.pixelSize: NuTokens.fontSmall
                                    }
                                    NuComboBox {
                                        id: movementGraphSort
                                        Layout.preferredWidth: 120
                                        model: ["Largest", "Newest"]
                                        currentIndex: root.movementGraphSortMode === "Newest" ? 1 : 0
                                        helpText: "Choose whether the graph uses the largest loaded movements or the newest loaded movements first."
                                        onActivated: {
                                            root.movementGraphSortMode = currentText
                                            movementGraphCanvas.requestPaint()
                                        }
                                    }
                                }

                                RowLayout {
                                    spacing: NuTokens.spaceSm
                                    Label {
                                        text: "Top " + root.movementGraphLimit
                                        color: NuTokens.textSecondary
                                        font.pixelSize: NuTokens.fontSmall
                                    }
                                    Basic.Slider {
                                        id: movementGraphLimitSlider
                                        Layout.preferredWidth: 140
                                        from: 5
                                        to: 50
                                        stepSize: 5
                                        snapMode: Basic.Slider.SnapAlways
                                        value: root.movementGraphLimit
                                        ToolTip.visible: hovered || pressed
                                        ToolTip.text: "Plot " + Math.round(value) + " movement outputs"
                                        ToolTip.delay: NuTokens.tooltipDelay
                                        onMoved: {
                                            root.movementGraphLimit = Math.round(value)
                                            movementGraphCanvas.requestPaint()
                                        }
                                    }
                                }

                                RowLayout {
                                    spacing: NuTokens.spaceSm
                                    Label {
                                        text: "Nodes " + Number(root.movementNodeScale).toLocaleString(Qt.locale(), "f", 1) + "x"
                                        color: NuTokens.textSecondary
                                        font.pixelSize: NuTokens.fontSmall
                                    }
                                    Basic.Slider {
                                        id: movementNodeScaleSlider
                                        Layout.preferredWidth: 130
                                        from: 0.6
                                        to: 1.9
                                        stepSize: 0.1
                                        snapMode: Basic.Slider.SnapAlways
                                        value: root.movementNodeScale
                                        ToolTip.visible: hovered || pressed
                                        ToolTip.text: "Scale movement nodes to " + Number(value).toLocaleString(Qt.locale(), "f", 1) + "x"
                                        ToolTip.delay: NuTokens.tooltipDelay
                                        onMoved: {
                                            root.movementNodeScale = Number(value)
                                            movementGraphCanvas.requestPaint()
                                            if (movementGraphPopoutCanvas)
                                                movementGraphPopoutCanvas.requestPaint()
                                        }
                                    }
                                }

                                NuActionButton {
                                    width: 76
                                    height: 42
                                    text: "Fit"
                                    helpText: "Reset dragged movement nodes and rerun the graph layout."
                                    onClicked: root.resetMovementGraphLayout("main")
                                }

                                NuActionButton {
                                    width: 118
                                    height: 42
                                    text: "Pop out"
                                    helpText: "Open the movement network in a maximized interactive graph window."
                                    onClicked: root.showChartWindow(movementGraphWindow)
                                }
                            }
                        }

                        Canvas {
                            id: movementGraphCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onPaint: root.drawMovementGraph(getContext("2d"), width, height, "main")
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.hoveredMovementAddress.length > 0 || root.draggingMovementAddress.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                ToolTip.visible: containsMouse && root.hoveredMovementAddress.length > 0
                                ToolTip.text: root.movementNodeToolTip(root.hoveredMovementAddress)
                                ToolTip.delay: NuTokens.tooltipDelay
                                ToolTip.timeout: NuTokens.tooltipTimeout
                                onPressed: (mouse) => {
                                    const address = root.movementNodeAt(mouse.x, mouse.y, movementGraphCanvas.width, movementGraphCanvas.height, "main")
                                    root.draggingMovementAddress = address
                                    root.movementDragLastX = mouse.x
                                    root.movementDragLastY = mouse.y
                                    root.movementDragMoved = false
                                    mouse.accepted = address.length > 0
                                }
                                onPositionChanged: (mouse) => {
                                    if (root.draggingMovementAddress.length > 0) {
                                        const dx = mouse.x - root.movementDragLastX
                                        const dy = mouse.y - root.movementDragLastY
                                        if (Math.abs(dx) + Math.abs(dy) > 2)
                                            root.movementDragMoved = true
                                        root.moveMovementNode(root.draggingMovementAddress, mouse.x, mouse.y, movementGraphCanvas.width, movementGraphCanvas.height, "main")
                                        root.movementDragLastX = mouse.x
                                        root.movementDragLastY = mouse.y
                                        movementGraphCanvas.requestPaint()
                                        return
                                    }
                                    root.hoveredMovementAddress = root.movementNodeAt(mouse.x, mouse.y, movementGraphCanvas.width, movementGraphCanvas.height, "main")
                                    movementGraphCanvas.requestPaint()
                                }
                                onReleased: {
                                    const address = root.draggingMovementAddress
                                    const shouldOpen = address.length > 0 && !root.movementDragMoved
                                    root.draggingMovementAddress = ""
                                    root.hoveredMovementAddress = ""
                                    movementGraphCanvas.requestPaint()
                                    if (shouldOpen)
                                        NuService.openAddressInExplorer(address)
                                }
                                onExited: {
                                    if (root.draggingMovementAddress.length === 0) {
                                        root.hoveredMovementAddress = ""
                                        movementGraphCanvas.requestPaint()
                                    }
                                }
                            }
                        }
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
                        columns: ["Tx Hash", "Amount", "Timestamp", "Height", "Output", "Target"]
                        columnTypes: ["hash", "amount", "date", "number", "number", "number"]
                        columnWeights: [3.6, 1.1, 1.4, 0.75, 0.65, 0.75]
                        rows: root.movementPageRows(movementTableHost.rowsPerPage)
                        emptyText: "Large movement outputs appear after the Explorer index contains non-coinbase outputs above the selected threshold."
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
                            text: "Contact address map"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Create local username-to-address groups, then chart indexed value flows between those saved contacts. Contact data stays in local Nu settings."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 138
                        text: "Pop out"
                        helpText: "Open the contact editor in a separate window."
                        onClicked: {
                            contactEditorWindow.show()
                            contactEditorWindow.raise()
                            contactEditorWindow.requestActivate()
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 160
                        text: "Chart Relationships"
	                        primary: true
	                        helpText: "Build an indexed relationship graph from saved contact addresses."
	                        onClicked: root.showRelationshipWindow()
	                    }
                    Basic.TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(22, Math.min(48, contentHeight + 2))
                        text: NuService.explorerAnalyticsStatus
                        color: NuTokens.textMuted
                        font.pixelSize: NuTokens.fontTiny
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        background: Item {}
                        padding: 0
                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: activeFocus && selectedText.length > 0
                            onActivated: NuService.copyText(selectedText)
                        }
	                    }
	                }

	                RowLayout {
	                    Layout.fillWidth: true
	                    Layout.preferredHeight: 150
	                    spacing: NuTokens.spaceMd

	                    ColumnLayout {
	                        Layout.preferredWidth: Math.max(360, root.width * 0.32)
	                        Layout.fillHeight: true
	                        spacing: NuTokens.spaceXs
	                        Label {
	                            Layout.fillWidth: true
	                            text: root.activeContactSetLabel()
	                            color: NuTokens.textPrimary
	                            font.pixelSize: NuTokens.fontSmall
	                            font.weight: Font.DemiBold
	                            wrapMode: Text.WordWrap
	                        }
	                        NuTextField {
	                            id: contactSetNameField
	                            Layout.fillWidth: true
	                            text: NuService.currentExplorerContactSetName
	                            placeholderText: "contact set name"
	                            helpText: "Name for the saved group of contacts used by the relationship graph."
	                        }
	                        Flow {
	                            Layout.fillWidth: true
	                            spacing: NuTokens.spaceSm
	                            NuActionButton {
	                                width: 76
	                                text: "Load"
	                                enabled: root.selectedContactSetName.length > 0 || contactSetNameField.text.length > 0
	                                helpText: "Load the selected saved contact set into the relationship graph."
	                                onClicked: {
	                                    NuService.loadExplorerContactSet(root.selectedContactSetName.length > 0 ? root.selectedContactSetName : contactSetNameField.text)
	                                    root.clearContactEditor()
	                                    contactSetNameField.text = NuService.currentExplorerContactSetName
	                                }
	                            }
	                            NuActionButton {
	                                width: 96
	                                text: "Save set"
	                                primary: true
	                                helpText: "Save the currently visible contacts into this named contact set. A new name works as Save As."
	                                onClicked: {
	                                    NuService.saveExplorerContactSet(contactSetNameField.text)
	                                    root.selectedContactSetName = contactSetNameField.text
	                                }
	                            }
	                            NuActionButton {
	                                width: 98
	                                text: "New empty"
	                                helpText: "Create and load a new empty contact set."
	                                onClicked: {
	                                    NuService.createExplorerContactSet(contactSetNameField.text)
	                                    root.selectedContactSetName = contactSetNameField.text
	                                    root.clearContactEditor()
	                                }
	                            }
	                            NuActionButton {
	                                width: 92
	                                text: "Rename"
	                                enabled: contactSetNameField.text.length > 0
	                                helpText: "Rename the selected set, or the active set if no row is selected."
	                                onClicked: {
	                                    NuService.renameExplorerContactSet(root.selectedContactSetName.length > 0 ? root.selectedContactSetName : NuService.currentExplorerContactSetName,
	                                                                       contactSetNameField.text)
	                                    root.selectedContactSetName = contactSetNameField.text
	                                }
	                            }
	                            NuActionButton {
	                                width: 82
	                                text: "Delete"
	                                danger: true
	                                enabled: root.selectedContactSetName.length > 0 || contactSetNameField.text.length > 0
	                                helpText: "Delete the selected saved contact set."
	                                onClicked: {
	                                    NuService.deleteExplorerContactSet(root.selectedContactSetName.length > 0 ? root.selectedContactSetName : contactSetNameField.text)
	                                    root.selectedContactSetName = ""
	                                    contactSetNameField.text = NuService.currentExplorerContactSetName
	                                    root.clearContactEditor()
	                                }
	                            }
	                        }
	                    }

	                    NuDataTable {
	                        Layout.fillWidth: true
	                        Layout.fillHeight: true
	                        tableId: "internalExplorerContactSets"
	                        columns: ["Set", "Contacts", "Addresses", "Saved"]
	                        columnTypes: ["text", "number", "number", "date"]
	                        columnWeights: [1.6, 0.55, 0.65, 1.4]
	                        rows: NuService.explorerContactSets
	                        emptyText: "No contact sets saved yet."
	                        rowSelectionEnabled: true
	                        plainClickSelectsRows: true
	                        rowKeyMetaField: "name"
	                        onRowSelectionChanged: (keys) => {
	                            root.selectedContactSetName = keys.length > 0 ? String(keys[0]) : ""
	                            if (root.selectedContactSetName.length > 0)
	                                contactSetNameField.text = root.selectedContactSetName
	                        }
	                        onRowActivated: (row) => root.selectContactSet(row)
	                    }
	                }

	                RowLayout {
	                    Layout.fillWidth: true
	                    Layout.preferredHeight: 150
                    spacing: NuTokens.spaceMd

                    ColumnLayout {
                        Layout.preferredWidth: Math.max(260, root.width * 0.28)
                        Layout.fillHeight: true
                        spacing: NuTokens.spaceXs
                        Label { text: "Username"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                        NuTextField {
                            id: contactNameField
                            Layout.fillWidth: true
                            placeholderText: "username, handle, or person"
                            helpText: "Local display name for a person, pool, project, or account cluster."
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceSm
                            NuActionButton {
                                Layout.fillWidth: true
                                text: root.selectedContactIndex >= 0 ? "Update" : "Add"
                                primary: true
                                helpText: "Save this local contact with the listed addresses."
                                onClicked: NuService.saveExplorerContact(contactNameField.text, contactAddressArea.text, root.selectedContactIndex)
                            }
                            NuActionButton {
                                Layout.preferredWidth: 82
                                text: "Clear"
                                helpText: "Clear the contact editor."
                                onClicked: root.clearContactEditor()
                            }
                            NuActionButton {
                                Layout.preferredWidth: 92
                                text: "Delete"
                                danger: true
                                enabled: root.selectedContactIndex >= 0
                                helpText: "Delete the selected local contact mapping."
                                onClicked: {
                                    NuService.deleteExplorerContact(root.selectedContactIndex)
                                    root.clearContactEditor()
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: NuTokens.spaceXs
                        Label { text: "Addresses"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                        Basic.TextArea {
                            id: contactAddressArea
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: "One or more Defcoin addresses, separated by commas or lines"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WrapAnywhere
                            selectByMouse: true
                            persistentSelection: true
                            background: Rectangle {
                                radius: NuTokens.radiusSmall
                                color: NuTokens.panelBase
                                border.color: contactAddressArea.activeFocus ? NuTokens.lineStrong : NuTokens.lineSubtle
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: NuTokens.spaceMd
                    NuDataTable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        tableId: "internalExplorerContacts"
                        columns: ["User", "Addresses", "Count"]
                        columnTypes: ["text", "address", "number"]
                        columnWeights: [1.0, 3.0, 0.45]
                        rows: root.contactRows()
                        emptyText: "No saved contact mappings yet."
                        rowSelectionEnabled: true
                        plainClickSelectsRows: true
                        rowKeyMetaField: "index"
                        onRowSelectionChanged: (keys) => {
                            if (keys.length === 0) {
                                root.clearContactEditor()
                                return
                            }
                            const wanted = Number(keys[0])
                            const rows = root.contactRows()
                            for (let i = 0; i < rows.length; ++i) {
                                if (Number((rows[i].meta || {}).index) === wanted) {
                                    root.selectContact(rows[i])
                                    return
                                }
                            }
                        }
                        onRowActivated: (row) => root.selectContact(row)
                    }
                    NuDataTable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        tableId: "internalExplorerContactRelationships"
                        columns: ["From", "To", "Total Flow", "Txs"]
                        columnTypes: ["text", "text", "amount", "number"]
                        columnWeights: [1.0, 1.0, 1.0, 0.45]
                        rows: NuService.explorerContactRelationships
                        emptyText: "No indexed contact-to-contact flows found yet."
                        defaultSortColumn: 2
                        defaultSortAscending: false
                    }
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
                            text: "/r/Defcoin Timeline"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "A curated chronology of subreddit events merged with official annual DEF CON anchors, focused on what changed Defcoin's public utility, community coordination, chain security, and conference culture."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 118
                        text: "Reload"
                        helpText: "Reload bundled /r/Defcoin timeline data."
                        onClicked: root.refreshDefcoinTimeline()
                    }
                    NuActionButton {
                        Layout.preferredWidth: 118
                        text: "Pop out"
                        helpText: "Open the /r/Defcoin timeline in a maximized window."
                        onClicked: root.showChartWindow(defcoinTimelineWindow)
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow { label: "Events"; value: root.defcoinTimelineNumber("includedRows") }
                    NuMetricRow { label: "Subreddit"; value: root.defcoinTimelineNumber("includedSubredditRows") }
                    NuMetricRow { label: "DEF CON anchors"; value: root.defcoinTimelineNumber("includedHistoryRows") }
                    NuMetricRow { label: "Removed"; value: root.defcoinTimelineNumber("removedRows") }
                    NuMetricRow { label: "Range"; value: root.defcoinTimelineText("firstDate", "-") + " to " + root.defcoinTimelineText("lastDate", "-") }
                }

                Basic.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(24, Math.min(54, contentHeight + 2))
                    text: NuService.defcoinTimelineStatus
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    background: Item {}
                    padding: 0
                }

                Basic.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    text: NuService.defcoinTimelineCriteria
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    background: Rectangle {
                        color: NuTokens.backgroundBase
                        radius: NuTokens.radiusSmall
                        border.color: NuTokens.lineSubtle
                    }
                    padding: NuTokens.spaceSm
                    Shortcut {
                        sequences: [StandardKey.Copy]
                        enabled: activeFocus && selectedText.length > 0
                        onActivated: NuService.copyText(selectedText)
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "internalExplorerDefcoinRedditTimeline"
                    columns: ["Date", "Category", "Event", "Status", "Event record", "Why included", "Source"]
                    columnTypes: ["date", "text", "text", "text", "text", "text", "link"]
                    columnWeights: [0.65, 1.0, 1.5, 0.85, 2.6, 2.25, 1.2]
                    columnLinkMetaFields: ["", "", "", "", "", "", "url"]
                    columnSortMetaFields: ["sortDate", "", "", "", "", "", ""]
                    rows: NuService.defcoinTimelineRows
                    emptyText: "Reload /r/Defcoin timeline data to populate historical events."
                    defaultSortColumn: 0
                    defaultSortAscending: true
                    restoreSavedColumnWidths: true
                    onRowActivated: (row) => root.openTimelineRow(row)
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
                            text: "Hover a point for exact indexed values; click it to open the matching Explorer row."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                    Flow {
                        Layout.preferredWidth: Math.max(660, Math.min(760, root.width * 0.62))
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        spacing: NuTokens.spaceSm
                        RowLayout {
                            width: 210
                            spacing: NuTokens.spaceSm
                            Label {
                                text: "Chart"
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                            }
                            NuComboBox {
                                id: networkPulseMetricCombo
                                Layout.fillWidth: true
                                Layout.preferredWidth: 150
                                model: ["Hashrate", "Difficulty", "Block time"]
                                currentIndex: root.networkPulseMetric === "Difficulty" ? 1 : (root.networkPulseMetric === "Block time" ? 2 : 0)
                                helpText: "Choose which macro network series is drawn."
                                onActivated: {
                                    root.networkPulseMetric = currentText
                                    networkPulseChart.requestPaint()
                                    if (networkPulsePopoutCanvas)
                                        networkPulsePopoutCanvas.requestPaint()
                                }
                            }
                        }
                        RowLayout {
                            width: 220
                            spacing: NuTokens.spaceSm
                            Label {
                                text: "Sample"
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                            }
                            NuComboBox {
                                id: networkPulseWindowCombo
                                Layout.fillWidth: true
                                Layout.preferredWidth: 150
                                model: ["30 blocks", "120 blocks", "720 blocks", "2016 blocks"]
                                currentIndex: root.networkPulseWindowBlocks === 30 ? 0 : (root.networkPulseWindowBlocks === 720 ? 2 : (root.networkPulseWindowBlocks === 2016 ? 3 : 1))
                                helpText: "Choose the minimum block span represented by each sampled history point."
                                onActivated: {
                                    const windows = [30, 120, 720, 2016]
                                    root.networkPulseWindowBlocks = windows[Math.max(0, currentIndex)]
                                    root.refreshNetworkPulse()
                                }
                            }
                        }
                        NuActionButton {
                            width: 104
                            implicitHeight: 40
                            text: "Refresh"
                            helpText: "Rebuild Network Pulse chart data from the local Explorer index."
                            onClicked: root.refreshNetworkPulse()
                        }
                        NuActionButton {
                            width: 104
                            implicitHeight: 40
                            text: "Pop out"
                            helpText: "Open the Network Pulse chart in a maximized window."
                            onClicked: root.showChartWindow(networkPulseWindow)
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow { label: "Hashrate"; value: NuService.recentNetworkHashrate }
                    NuMetricRow { label: "Difficulty"; value: NuService.networkDifficulty }
                    NuMetricRow { label: "Avg block"; value: NuService.recentAverageBlockTime }
                    NuMetricRow { label: "Samples"; value: root.networkPulseNumber("sampleRows") }
                    NuMetricRow { label: "Window"; value: root.networkPulseText("windowBlocks", "120") + " blocks" }
                    NuMetricRow {
                        label: "Dates"
                        value: root.networkPulseText("firstDate", "-") + " to " + root.networkPulseText("lastDate", "-")
                        valueMaximumWidth: 260
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm
                    Basic.TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(22, Math.min(42, contentHeight + 2))
                        text: NuService.networkPulseStatus
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        background: Item {}
                        padding: 0
                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: activeFocus && selectedText.length > 0
                            onActivated: NuService.copyText(selectedText)
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 72
                        implicitHeight: 36
                        text: "Copy"
                        helpText: "Copy the current Network Pulse status text."
                        onClicked: NuService.copyText(NuService.networkPulseStatus)
                    }
                }

                Rectangle {
                    id: networkPulseChartFrame
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(190, Math.min(280, root.height * 0.24))
                    Layout.maximumHeight: 300
                    radius: NuTokens.radiusSmall
                    color: NuTokens.panelBase
                    border.color: NuTokens.lineSubtle
                    clip: true

                    ToolTip.visible: networkPulseMouse.containsMouse && root.hoveredNetworkPulseIndex >= 0
                    ToolTip.text: root.networkPulseHoverText(root.hoveredNetworkPulseIndex)
                    ToolTip.delay: NuTokens.tooltipDelay

                    Canvas {
                        id: networkPulseChart
                        anchors.fill: parent
                        anchors.margins: NuTokens.spaceSm
                        onPaint: root.drawNetworkPulseChart(getContext("2d"), width, height)
                    }
                    MouseArea {
                        id: networkPulseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: (mouse) => {
                            root.hoveredNetworkPulseIndex = root.networkPulseIndexAt(mouse.x - NuTokens.spaceSm, mouse.y - NuTokens.spaceSm, networkPulseChart.width, networkPulseChart.height)
                            networkPulseChart.requestPaint()
                        }
                        onExited: {
                            root.hoveredNetworkPulseIndex = -1
                            networkPulseChart.requestPaint()
                        }
                        onClicked: (mouse) => {
                            const index = root.networkPulseIndexAt(mouse.x - NuTokens.spaceSm, mouse.y - NuTokens.spaceSm, networkPulseChart.width, networkPulseChart.height)
                            const rows = root.networkPulseRows()
                            if (index >= 0 && index < rows.length)
                                root.openRow(rows[index])
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 170
                    Layout.preferredHeight: Math.max(170, Math.min(260, root.height * 0.24))
                    tableId: "internalExplorerNetworkPulse"
                    columns: ["Height", "Date", "Avg Block", "Difficulty", "Est. Hashrate", "Span", "Txs"]
                    columnTypes: ["number", "date", "text", "number", "text", "text", "number"]
                    columnWeights: [0.65, 1.05, 0.75, 0.85, 1.05, 0.8, 0.45]
                    rows: NuService.networkPulseHistoryRows
                    emptyText: "Build or refresh the Explorer index, then refresh Network Pulse history."
                    defaultSortColumn: 0
                    defaultSortAscending: true
                    restoreSavedColumnWidths: true
                    onRowActivated: (row) => root.openRow(row)
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
            const span = Math.max(timelineRange.minSpan, timelineRange.end - timelineRange.start)
            const nextStart = Math.min(1 - span, timelineRange.start + 0.01)
            timelineRange.start = nextStart
            timelineRange.end = Math.min(1, nextStart + span)
            root.loadTimelineSnapshotAtPosition((timelineRange.start + timelineRange.end) / 2)
            if (timelineRange.end >= 1) root.timelinePlaying = false
        }
    }

    Item {
        Layout.preferredWidth: 0
        Layout.preferredHeight: 0
        visible: false

        Window {
            id: defcoinTimelineWindow
            width: 1280
            height: 900
            minimumWidth: 860
            minimumHeight: 620
            visible: false
            title: "/r/Defcoin Timeline"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "/r/Defcoin Timeline"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTitle
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: root.defcoinTimelineNumber("includedRows") + " events"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                    }
                    NuActionButton {
                        Layout.preferredWidth: 110
                        text: "Reload"
                        helpText: "Reload bundled /r/Defcoin timeline data."
                        onClicked: root.refreshDefcoinTimeline()
                    }
                }

                Basic.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    text: NuService.defcoinTimelineCriteria
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    background: Rectangle {
                        color: NuTokens.panelBase
                        radius: NuTokens.radiusSmall
                        border.color: NuTokens.lineSubtle
                    }
                    padding: NuTokens.spaceSm
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "internalExplorerDefcoinRedditTimelinePopout"
                    columns: ["Date", "Category", "Event", "Status", "Event record", "Why included", "Source"]
                    columnTypes: ["date", "text", "text", "text", "text", "text", "link"]
                    columnWeights: [0.65, 1.0, 1.5, 0.85, 2.6, 2.25, 1.2]
                    columnLinkMetaFields: ["", "", "", "", "", "", "url"]
                    columnSortMetaFields: ["sortDate", "", "", "", "", "", ""]
                    rows: NuService.defcoinTimelineRows
                    emptyText: "Reload /r/Defcoin timeline data to populate historical events."
                    defaultSortColumn: 0
                    defaultSortAscending: true
                    restoreSavedColumnWidths: true
                    onRowActivated: (row) => root.openTimelineRow(row)
                }
            }
        }

        Window {
            id: networkPulseWindow
            width: 1280
            height: 900
            minimumWidth: 820
            minimumHeight: 620
            visible: false
            title: "Network Pulse"
            color: NuTokens.backgroundBase
            onVisibleChanged: if (visible) Qt.callLater(function() { networkPulsePopoutCanvas.requestPaint() })

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceXs
                        Label {
                            Layout.fillWidth: true
                            text: "Network Pulse"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontTitle
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Hover a point for exact indexed values; click it to open the matching Explorer row."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                    Flow {
                        Layout.preferredWidth: Math.max(560, Math.min(760, networkPulseWindow.width * 0.55))
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        spacing: NuTokens.spaceSm
                        RowLayout {
                            width: 212
                            spacing: NuTokens.spaceSm
                            Label {
                                text: "Chart"
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                            }
                            NuComboBox {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 150
                                model: ["Hashrate", "Difficulty", "Block time"]
                                currentIndex: root.networkPulseMetric === "Difficulty" ? 1 : (root.networkPulseMetric === "Block time" ? 2 : 0)
                                helpText: "Choose which macro network series is drawn."
                                onActivated: {
                                    root.networkPulseMetric = currentText
                                    networkPulsePopoutCanvas.requestPaint()
                                    if (networkPulseChart)
                                        networkPulseChart.requestPaint()
                                }
                            }
                        }
                        RowLayout {
                            width: 222
                            spacing: NuTokens.spaceSm
                            Label {
                                text: "Sample"
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                            }
                            NuComboBox {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 150
                                model: ["30 blocks", "120 blocks", "720 blocks", "2016 blocks"]
                                currentIndex: root.networkPulseWindowBlocks === 30 ? 0 : (root.networkPulseWindowBlocks === 720 ? 2 : (root.networkPulseWindowBlocks === 2016 ? 3 : 1))
                                helpText: "Choose the minimum block span represented by each sampled history point."
                                onActivated: {
                                    const windows = [30, 120, 720, 2016]
                                    root.networkPulseWindowBlocks = windows[Math.max(0, currentIndex)]
                                    root.refreshNetworkPulse()
                                }
                            }
                        }
                        NuActionButton {
                            width: 104
                            implicitHeight: 40
                            text: "Refresh"
                            helpText: "Rebuild Network Pulse chart data from the local Explorer index."
                            onClicked: root.refreshNetworkPulse()
                        }
                        NuActionButton {
                            width: 88
                            implicitHeight: 40
                            text: "Close"
                            onClicked: networkPulseWindow.close()
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow { label: "Hashrate"; value: NuService.recentNetworkHashrate }
                    NuMetricRow { label: "Difficulty"; value: NuService.networkDifficulty }
                    NuMetricRow { label: "Avg block"; value: NuService.recentAverageBlockTime }
                    NuMetricRow { label: "Samples"; value: root.networkPulseNumber("sampleRows") }
                    NuMetricRow { label: "Stride"; value: root.networkPulseText("strideBlocks", "-") + " blocks" }
                    NuMetricRow {
                        label: "Range"
                        value: root.networkPulseText("firstDate", "-") + " to " + root.networkPulseText("lastDate", "-")
                        valueMaximumWidth: 300
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm
                    Basic.TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(24, Math.min(46, contentHeight + 2))
                        text: NuService.networkPulseStatus
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        background: Item {}
                        padding: 0
                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: activeFocus && selectedText.length > 0
                            onActivated: NuService.copyText(selectedText)
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 72
                        implicitHeight: 36
                        text: "Copy"
                        helpText: "Copy the current Network Pulse status text."
                        onClicked: NuService.copyText(NuService.networkPulseStatus)
                    }
                }

                Rectangle {
                    id: networkPulsePopoutFrame
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 360
                    Layout.preferredHeight: Math.max(380, networkPulseWindow.height * 0.52)
                    radius: NuTokens.radiusSmall
                    color: NuTokens.panelBase
                    border.color: NuTokens.lineSubtle
                    clip: true

                    ToolTip.visible: networkPulsePopoutMouse.containsMouse && root.hoveredNetworkPulseIndex >= 0
                    ToolTip.text: root.networkPulseHoverText(root.hoveredNetworkPulseIndex)
                    ToolTip.delay: NuTokens.tooltipDelay

                    Canvas {
                        id: networkPulsePopoutCanvas
                        anchors.fill: parent
                        anchors.margins: NuTokens.spaceMd
                        onPaint: root.drawNetworkPulseChart(getContext("2d"), width, height)
                    }
                    MouseArea {
                        id: networkPulsePopoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: (mouse) => {
                            root.hoveredNetworkPulseIndex = root.networkPulseIndexAt(mouse.x - NuTokens.spaceMd, mouse.y - NuTokens.spaceMd, networkPulsePopoutCanvas.width, networkPulsePopoutCanvas.height)
                            networkPulsePopoutCanvas.requestPaint()
                        }
                        onExited: {
                            root.hoveredNetworkPulseIndex = -1
                            networkPulsePopoutCanvas.requestPaint()
                        }
                        onClicked: (mouse) => {
                            const index = root.networkPulseIndexAt(mouse.x - NuTokens.spaceMd, mouse.y - NuTokens.spaceMd, networkPulsePopoutCanvas.width, networkPulsePopoutCanvas.height)
                            const rows = root.networkPulseRows()
                            if (index >= 0 && index < rows.length)
                                root.openRow(rows[index])
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 180
                    Layout.preferredHeight: Math.max(190, networkPulseWindow.height * 0.24)
                    tableId: "internalExplorerNetworkPulsePopout"
                    columns: ["Height", "Date", "Avg Block", "Difficulty", "Est. Hashrate", "Span", "Txs"]
                    columnTypes: ["number", "date", "text", "number", "text", "text", "number"]
                    columnWeights: [0.65, 1.05, 0.75, 0.85, 1.05, 0.8, 0.45]
                    rows: NuService.networkPulseHistoryRows
                    emptyText: "Build or refresh the Explorer index, then refresh Network Pulse history."
                    defaultSortColumn: 0
                    defaultSortAscending: true
                    restoreSavedColumnWidths: true
                    onRowActivated: (row) => root.openRow(row)
                }
            }
        }

        Window {
            id: holderPieWindow
            width: 1120
            height: 820
            minimumWidth: 760
            minimumHeight: 560
            visible: false
            title: "Largest Holders"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Largest Holders"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
                Canvas {
                    id: holderPiePopoutCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawRichPie(getContext("2d"), width, height)
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        ToolTip.visible: containsMouse && root.richHoverText(root.hoveredRichRank).length > 0
                        ToolTip.text: root.richHoverText(root.hoveredRichRank)
                        ToolTip.delay: NuTokens.tooltipDelay
                        ToolTip.timeout: NuTokens.tooltipTimeout
                        onPositionChanged: (mouse) => {
                            root.hoveredRichRank = root.richSliceAt(mouse.x, mouse.y, holderPiePopoutCanvas.width, holderPiePopoutCanvas.height)
                        }
                        onExited: root.hoveredRichRank = -1
                        onClicked: (mouse) => {
                            const rank = root.richSliceAt(mouse.x, mouse.y, holderPiePopoutCanvas.width, holderPiePopoutCanvas.height)
                            root.selectedRichRank = root.selectedRichRank === rank ? -1 : rank
                            holderPiePopoutCanvas.requestPaint()
                            richPie.requestPaint()
                        }
                    }
                }
            }
        }

        Window {
            id: supplyBandsWindow
            width: 1120
            height: 820
            minimumWidth: 760
            minimumHeight: 560
            visible: false
            title: "Supply Bands"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Supply Bands"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
                Canvas {
                    id: supplyBandsPopoutCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawDistributionPie(getContext("2d"), width, height, root.wealthDistributionRows(), "Supply", "bands", root.selectedWealthGroup)
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: (mouse) => {
                            const label = root.distributionSliceAt(mouse.x, mouse.y, supplyBandsPopoutCanvas.width, supplyBandsPopoutCanvas.height, root.wealthDistributionRows())
                            root.selectedWealthGroup = root.selectedWealthGroup === label ? "" : label
                            supplyBandsPopoutCanvas.requestPaint()
                            wealthDistributionPie.requestPaint()
                        }
                    }
                }
                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    tableId: "internalExplorerWealthDistributionPopout"
                    columns: ["", "Group", "Amount", "%"]
                    columnTypes: ["swatch", "text", "amount", "number"]
                    columnWeights: [0.25, 1.4, 1.2, 0.55]
                    rows: root.wealthDistributionRows()
                    emptyText: "Build the Explorer index and refresh holders to calculate supply bands."
                    defaultSortColumn: -1
                    rowSelectionEnabled: true
                    plainClickSelectsRows: true
                    rowKeyMetaField: "label"
                    onRowSelectionChanged: (keys) => {
                        root.selectedWealthGroup = keys.length > 0 ? String(keys[0]) : ""
                        supplyBandsPopoutCanvas.requestPaint()
                        wealthDistributionPie.requestPaint()
                    }
                }
            }
        }

        Window {
            id: whaleLensWindow
            width: 1120
            height: 820
            minimumWidth: 760
            minimumHeight: 560
            visible: false
            title: "Whale Lens"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Whale Lens"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
                Canvas {
                    id: whaleLensPopoutCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawDistributionPie(getContext("2d"), width, height, root.whaleConcentrationRows(), "Whale", "lens", root.selectedWhaleGroup)
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: (mouse) => {
                            const label = root.distributionSliceAt(mouse.x, mouse.y, whaleLensPopoutCanvas.width, whaleLensPopoutCanvas.height, root.whaleConcentrationRows())
                            root.selectedWhaleGroup = root.selectedWhaleGroup === label ? "" : label
                            whaleLensPopoutCanvas.requestPaint()
                            whaleConcentrationPie.requestPaint()
                        }
                    }
                }
                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    tableId: "internalExplorerWhaleConcentrationPopout"
                    columns: ["", "Group", "Amount", "%"]
                    columnTypes: ["swatch", "text", "amount", "number"]
                    columnWeights: [0.25, 1.4, 1.2, 0.55]
                    rows: root.whaleConcentrationRows()
                    emptyText: "Build the Explorer index and refresh holders to calculate concentration."
                    defaultSortColumn: -1
                    rowSelectionEnabled: true
                    plainClickSelectsRows: true
                    rowKeyMetaField: "label"
                    onRowSelectionChanged: (keys) => {
                        root.selectedWhaleGroup = keys.length > 0 ? String(keys[0]) : ""
                        whaleLensPopoutCanvas.requestPaint()
                        whaleConcentrationPie.requestPaint()
                    }
                }
            }
        }

        Window {
            id: movementGraphWindow
            width: 1280
            height: 900
            minimumWidth: 860
            minimumHeight: 620
            visible: false
            title: "Movement Network"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    Label {
                        Layout.fillWidth: true
                        text: "Movement Network"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTitle
                        font.weight: Font.DemiBold
                    }
                    Label { text: "Sort"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuComboBox {
                        Layout.preferredWidth: 120
                        model: ["Largest", "Newest"]
                        currentIndex: root.movementGraphSortMode === "Newest" ? 1 : 0
                        onActivated: {
                            root.movementGraphSortMode = currentText
                            movementGraphPopoutCanvas.requestPaint()
                            movementGraphCanvas.requestPaint()
                        }
                    }
                    Label {
                        text: "Top " + root.movementGraphLimit
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    Basic.Slider {
                        Layout.preferredWidth: 150
                        from: 5
                        to: 50
                        stepSize: 5
                        snapMode: Basic.Slider.SnapAlways
                        value: root.movementGraphLimit
                        onMoved: {
                            root.movementGraphLimit = Math.round(value)
                            movementGraphPopoutCanvas.requestPaint()
                            movementGraphCanvas.requestPaint()
                        }
                    }
                    Label {
                        text: "Nodes " + Number(root.movementNodeScale).toLocaleString(Qt.locale(), "f", 1) + "x"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    Basic.Slider {
                        Layout.preferredWidth: 150
                        from: 0.6
                        to: 1.9
                        stepSize: 0.1
                        snapMode: Basic.Slider.SnapAlways
                        value: root.movementNodeScale
                        ToolTip.visible: hovered || pressed
                        ToolTip.text: "Scale movement nodes to " + Number(value).toLocaleString(Qt.locale(), "f", 1) + "x"
                        ToolTip.delay: NuTokens.tooltipDelay
                        onMoved: {
                            root.movementNodeScale = Number(value)
                            movementGraphPopoutCanvas.requestPaint()
                            movementGraphCanvas.requestPaint()
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 76
                        text: "Fit"
                        helpText: "Reset dragged movement nodes and rerun the graph layout."
                        onClicked: root.resetMovementGraphLayout("popout")
                    }
                }

                Canvas {
                    id: movementGraphPopoutCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawMovementGraph(getContext("2d"), width, height, "popout")
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.hoveredMovementAddress.length > 0 || root.draggingMovementAddress.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        ToolTip.visible: containsMouse && root.hoveredMovementAddress.length > 0
                        ToolTip.text: root.movementNodeToolTip(root.hoveredMovementAddress)
                        ToolTip.delay: NuTokens.tooltipDelay
                        ToolTip.timeout: NuTokens.tooltipTimeout
                        onPressed: (mouse) => {
                            const address = root.movementNodeAt(mouse.x, mouse.y, movementGraphPopoutCanvas.width, movementGraphPopoutCanvas.height, "popout")
                            root.draggingMovementAddress = address
                            root.movementDragLastX = mouse.x
                            root.movementDragLastY = mouse.y
                            root.movementDragMoved = false
                            mouse.accepted = address.length > 0
                        }
                        onPositionChanged: (mouse) => {
                            if (root.draggingMovementAddress.length > 0) {
                                const dx = mouse.x - root.movementDragLastX
                                const dy = mouse.y - root.movementDragLastY
                                if (Math.abs(dx) + Math.abs(dy) > 2)
                                    root.movementDragMoved = true
                                root.moveMovementNode(root.draggingMovementAddress, mouse.x, mouse.y, movementGraphPopoutCanvas.width, movementGraphPopoutCanvas.height, "popout")
                                root.movementDragLastX = mouse.x
                                root.movementDragLastY = mouse.y
                                movementGraphPopoutCanvas.requestPaint()
                                movementGraphCanvas.requestPaint()
                                return
                            }
                            root.hoveredMovementAddress = root.movementNodeAt(mouse.x, mouse.y, movementGraphPopoutCanvas.width, movementGraphPopoutCanvas.height, "popout")
                            movementGraphPopoutCanvas.requestPaint()
                        }
                        onReleased: {
                            const address = root.draggingMovementAddress
                            const shouldOpen = address.length > 0 && !root.movementDragMoved
                            root.draggingMovementAddress = ""
                            root.hoveredMovementAddress = ""
                            movementGraphPopoutCanvas.requestPaint()
                            movementGraphCanvas.requestPaint()
                            if (shouldOpen)
                                NuService.openAddressInExplorer(address)
                        }
                        onExited: {
                            if (root.draggingMovementAddress.length === 0) {
                                root.hoveredMovementAddress = ""
                                movementGraphPopoutCanvas.requestPaint()
                            }
                        }
                    }
                }
            }
        }

        Window {
            id: coindroidsChartWindow
            width: 1680
            height: 960
            minimumWidth: 1080
            minimumHeight: 760
            visible: false
            title: "Droid Trails"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceSm
                spacing: NuTokens.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Droid Trails"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 118
                        text: "All windows"
                        visible: root.coindroidsWindowZoomed
                        helpText: "Return the Droid Trails chart to the DEF CON window comparison."
                        onClicked: root.clearCoindroidsWindowZoom()
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: NuService.coindroidsScanning ? "Scanning" : "Refresh"
                        enabled: !NuService.coindroidsScanning
                        onClicked: root.refreshCoindroids()
                    }
	                }

	                Basic.ScrollView {
	                    id: coindroidsChartPopoutScroll
	                    Layout.fillWidth: true
	                    Layout.fillHeight: true
	                    contentWidth: availableWidth
	                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
	                    clip: true

	                    ColumnLayout {
	                        width: Math.max(1, coindroidsChartPopoutScroll.availableWidth)
	                        spacing: NuTokens.spaceSm

	                Label {
	                    Layout.fillWidth: true
	                    text: root.coindroidsSelectedDetailText()
	                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }

                Canvas {
                    id: coindroidsChartPopoutCanvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(320, Math.min(500, coindroidsChartWindow.height * 0.46))
                    onPaint: root.drawCoindroidsWindowChart(getContext("2d"), width, height)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.hoveredCoindroidsWindowIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        ToolTip.visible: containsMouse && root.coindroidsWindowToolTip(root.hoveredCoindroidsWindowIndex).length > 0
                        ToolTip.text: root.coindroidsWindowToolTip(root.hoveredCoindroidsWindowIndex)
                        ToolTip.delay: NuTokens.tooltipDelay
                        ToolTip.timeout: NuTokens.tooltipTimeout
                        onPositionChanged: (mouse) => {
                            root.hoveredCoindroidsWindowIndex = root.coindroidsWindowIndexAt(mouse.x, mouse.y, coindroidsChartPopoutCanvas.width, coindroidsChartPopoutCanvas.height)
                            coindroidsChartPopoutCanvas.requestPaint()
                            if (coindroidsWindowChart)
                                coindroidsWindowChart.requestPaint()
                        }
                        onExited: {
                            root.hoveredCoindroidsWindowIndex = -1
                            coindroidsChartPopoutCanvas.requestPaint()
                            if (coindroidsWindowChart)
                                coindroidsWindowChart.requestPaint()
                        }
                        onClicked: (mouse) => {
                            const index = root.coindroidsWindowIndexAt(mouse.x, mouse.y, coindroidsChartPopoutCanvas.width, coindroidsChartPopoutCanvas.height)
                            if (index >= 0)
                                root.selectCoindroidsWindow(index)
                        }
                    }
                }
                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(278, Math.min(310, coindroidsChartWindow.height * 0.28))
                    tableId: "internalExplorerCoindroidsWindowsPopout"
                    columns: ["Window", "Blocks", "Dates", "Outputs", "Txs", "Addresses", "DFC*", "0.01", "0.1337", "Signal"]
                    columnTypes: ["text", "text", "date", "number", "number", "number", "amount", "number", "number", "text"]
                    columnWeights: [1.7, 1.0, 1.25, 0.72, 0.7, 0.82, 0.9, 0.56, 0.72, 1.15]
                    rows: NuService.coindroidsWindowRows
                    emptyText: "Refresh Droid Trails to calculate Coindroids candidate windows."
                    defaultSortColumn: -1
                    compact: true
                    fontPixelSize: 15
                    onRowActivated: (row) => root.selectCoindroidsWindowFromRow(row)
                }
                Label {
                    Layout.fillWidth: true
                    text: "* DFC values are rounded for readability."
                    color: NuTokens.textSecondary
	                    font.pixelSize: NuTokens.fontTiny
	                    wrapMode: Text.WordWrap
	                }
	                    }
	                }
	            }
	        }

        Window {
            id: coindroidsPayoutWindow
            width: 1680
            height: 960
            minimumWidth: 1120
            minimumHeight: 760
            visible: false
            title: "DC25 Payout Hunt"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceSm
                spacing: NuTokens.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "DC25 Payout Hunt"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 184
                        text: "Chart Relationships"
                        primary: true
                        enabled: NuService.coindroidsPayoutRows.length > 0
                        onClicked: root.chartRowsRelationships("Coindroids DC25 payout candidates", NuService.coindroidsPayoutRows)
                    }
                    NuActionButton {
                        Layout.preferredWidth: 106
                        text: "PDF"
                        onClicked: NuService.openCoindroidsReportPdf()
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: NuService.coindroidsScanning ? "Scanning" : "Refresh"
                        enabled: !NuService.coindroidsScanning
                        onClicked: root.refreshCoindroids()
	                    }
	                }

	                Basic.ScrollView {
	                    id: coindroidsPayoutPopoutScroll
	                    Layout.fillWidth: true
	                    Layout.fillHeight: true
	                    contentWidth: availableWidth
	                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
	                    clip: true

	                    ColumnLayout {
	                        width: Math.max(1, coindroidsPayoutPopoutScroll.availableWidth)
	                        spacing: NuTokens.spaceSm

	                NuSelectableText {
	                    Layout.fillWidth: true
	                    text: root.coindroidsText("dc25PayoutHuntNote", "Published DC25 payout values are treated as point-in-time contest/payout measurements. The scanner looks for historical balances reached during the DC25 settlement window, not final or current wallet balances.")
                    textColor: NuTokens.textSecondary
                    textPixelSize: NuTokens.fontSmall
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow { label: "Payout leads"; value: root.coindroidsNumber("payoutCandidateCount") }
                    NuMetricRow { label: "Game address leads"; value: root.coindroidsNumber("gameAddressLeadCount") }
                    NuMetricRow { label: "Published top subset"; value: root.coindroidsText("dc25PublishedTopPayoutTotal", "206.2045 DFC") }
                    NuMetricRow { label: "Published payout total"; value: root.coindroidsText("dc25PublishedOverallPayoutTotal", "227.046 DFC") }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(310, Math.min(390, coindroidsPayoutWindow.height * 0.42))
                    tableId: "internalExplorerCoindroidsDc25PayoutHuntPopout"
                    columns: ["Droid", "Published", "Candidate address", "Point balance", "At block / date", "Difference", "Confidence", "Evidence"]
                    columnTypes: ["text", "amount", "address", "amount", "text", "text", "text", "text"]
                    columnWeights: [1.0, 0.85, 2.4, 1.0, 1.55, 0.85, 0.85, 3.5]
                    rows: NuService.coindroidsPayoutRows
                    emptyText: "Refresh Droid Trails to run the DC25 historical point-balance payout hunt."
                    defaultSortColumn: 6
                    defaultSortAscending: true
                    compact: true
                    fontPixelSize: 15
                    onRowActivated: (row) => root.openRow(row)
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Game address leads"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontSmall
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 184
                        text: "Chart Relationships"
                        enabled: NuService.coindroidsGameAddressRows.length > 0
                        onClicked: root.chartRowsRelationships("Coindroids game address leads", NuService.coindroidsGameAddressRows)
                    }
                }

	                NuDataTable {
	                    Layout.fillWidth: true
	                    Layout.preferredHeight: Math.max(300, Math.min(380, coindroidsPayoutWindow.height * 0.32))
	                    tableId: "internalExplorerCoindroidsGameAddressLeadsPopout"
                    columns: ["Role", "Name", "Address", "Amount / marker", "Score", "Confidence", "Evidence"]
                    columnTypes: ["text", "text", "address", "text", "number", "text", "text"]
                    columnWeights: [1.35, 1.05, 2.4, 0.95, 0.55, 0.8, 3.4]
                    rows: NuService.coindroidsGameAddressRows
                    emptyText: "Refresh Droid Trails to load named leads, payout leads, and action-pattern address leads."
                    defaultSortColumn: 4
                    defaultSortAscending: false
                    compact: true
	                    fontPixelSize: 15
	                    onRowActivated: (row) => root.openRow(row)
	                }
	                    }
	                }
	            }
	        }

        Window {
            id: coindroidsAttackWindow
            width: 1680
            height: 960
            minimumWidth: 1120
            minimumHeight: 760
            visible: false
            title: "DC25 Attack Chain"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceSm
                spacing: NuTokens.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "DC25 Attack Chain"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
	                    }
	                    NuActionButton {
	                        Layout.preferredWidth: 136
	                        text: "Chart 8 leads"
	                        enabled: root.coindroidsQrLeadRows().length > 0
	                        onClicked: root.chartRowsRelationships("Coindroids DC25 named leads", root.coindroidsQrLeadRows())
	                    }
	                    NuActionButton {
	                        Layout.preferredWidth: 136
	                        text: "Chart cohort"
                        primary: true
                        enabled: NuService.coindroidsAttackAddressRows.length > 0
                        onClicked: root.chartCoindroidsRelations("dc25-attack-cohort")
                    }
                    NuActionButton {
                        Layout.preferredWidth: 144
                        text: "Chart sources"
                        enabled: NuService.coindroidsSourceAmmoRows.length > 0
                        onClicked: root.chartCoindroidsRelations("dc25-source-ammo")
                    }
                    NuActionButton {
                        Layout.preferredWidth: 106
                        text: "PDF"
                        onClicked: NuService.openCoindroidsReportPdf()
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: NuService.coindroidsScanning ? "Scanning" : "Refresh"
                        enabled: !NuService.coindroidsScanning
                        onClicked: root.refreshCoindroids()
	                    }
	                }

	                Basic.ScrollView {
	                    id: coindroidsAttackPopoutScroll
	                    Layout.fillWidth: true
	                    Layout.fillHeight: true
	                    contentWidth: availableWidth
	                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
	                    clip: true

	                    ColumnLayout {
	                        width: Math.max(1, coindroidsAttackPopoutScroll.availableWidth)
	                        spacing: NuTokens.spaceSm

		                NuSelectableText {
		                    Layout.fillWidth: true
		                    text: root.coindroidsText("cohortNote", "The 65-row broad small-output P2SH cohort matches the published DC25 count of fully activated Defcoin droids; stricter rows meet the exact-amount signature scan.")
	                    textColor: NuTokens.textSecondary
	                    textPixelSize: NuTokens.fontSmall
	                }

                Canvas {
                    id: coindroidsAttackPopoutCanvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(360, Math.min(520, coindroidsAttackWindow.height * 0.5))
                    onPaint: root.drawCoindroidsAttackChart(getContext("2d"), width, height)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.hoveredCoindroidsAttackIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        ToolTip.visible: containsMouse && root.coindroidsAttackToolTip(root.hoveredCoindroidsAttackIndex).length > 0
                        ToolTip.text: root.coindroidsAttackToolTip(root.hoveredCoindroidsAttackIndex)
                        ToolTip.delay: NuTokens.tooltipDelay
                        ToolTip.timeout: NuTokens.tooltipTimeout
                        onPositionChanged: (mouse) => {
                            root.hoveredCoindroidsAttackIndex = root.coindroidsAttackIndexAt(mouse.x, mouse.y, coindroidsAttackPopoutCanvas.width, coindroidsAttackPopoutCanvas.height)
                            root.requestCoindroidsChartRepaint()
                        }
                        onExited: {
                            root.hoveredCoindroidsAttackIndex = -1
                            root.requestCoindroidsChartRepaint()
                        }
                        onClicked: (mouse) => root.openCoindroidsAttackAddress(root.coindroidsAttackIndexAt(mouse.x, mouse.y, coindroidsAttackPopoutCanvas.width, coindroidsAttackPopoutCanvas.height))
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(278, Math.min(320, coindroidsAttackWindow.height * 0.3))
                    tableId: "internalExplorerCoindroidsAttackAddressesPopout"
                    columns: ["Name / lead", "Legacy 3-form", "Indexed M-form", "Outputs", "DC25 DFC", "Signature outs", "Ratio", "Blocks", "Confidence"]
                    columnTypes: ["text", "address", "address", "number", "amount", "number", "number", "text", "text"]
                    columnWeights: [1.1, 2.05, 2.05, 0.65, 0.82, 0.8, 0.55, 0.8, 1.2]
                    rows: NuService.coindroidsAttackAddressRows
                    emptyText: "Refresh Droid Trails to load the DC25 attack-address cohort."
                    defaultSortColumn: 3
                    defaultSortAscending: false
                    compact: true
                    fontPixelSize: 15
                    onRowActivated: (row) => root.openRow(row)
                }

                Label {
                    Layout.fillWidth: true
                    text: "Rows open in the explorer. Relationship buttons load named Contact Sets that also remain available from the Contacts screen."
                    color: NuTokens.textSecondary
	                    font.pixelSize: NuTokens.fontTiny
	                    wrapMode: Text.WordWrap
	                }
	                    }
	                }
	            }
	        }

        Window {
            id: top100TimelineWindow
            width: 1040
            height: 760
            minimumWidth: 760
            minimumHeight: 560
            visible: false
            title: "Holder Timeline"
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
                    text: "Holder Timeline"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.maximumWidth: Math.max(220, top100TimelineWindow.width * 0.32)
                    text: NuService.explorerTop100TimelineEventCount + " checkpoints"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }
                NuActionButton {
                    Layout.preferredWidth: 94
                    text: root.timelinePlaying ? "Pause" : "Play"
                    helpText: "Animate the pie chart forward through stored largest-holder timeline checkpoints."
                    onClicked: root.timelinePlaying = !root.timelinePlaying
                }
            }

            Canvas {
                id: timelinePie
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(420, top100TimelineWindow.width - 80)
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
                        totalPct += root.shareFromCell(rows[i].cells[3], rows[i])
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
                        ctx.fillText("Build holder timeline", cx, cy)
                        return
                    }
                    let start = -Math.PI / 2
                    for (let r = 0; r < rows.length; ++r) {
                        const pct = root.shareFromCell(rows[r].cells[3], rows[r])
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
                    ctx.fillText("Holders", cx, cy - 8)
                    ctx.font = "12px " + NuTokens.bodyFont
                    ctx.fillStyle = NuTokens.textSecondary
                    ctx.fillText("timeline shares", cx, cy + 12)
                }
            }

            Label {
                Layout.fillWidth: true
                text: root.timelineSnapshotHeaderText()
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontBody
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            NuTimelineWindow {
                id: timelineRange
                Layout.fillWidth: true
                label: ""
                start: 0
                end: 1
                minSpan: 0.01
                onViewportChanged: (s, e) => root.loadTimelineSnapshotAtPosition((s + e) / 2)
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
                emptyText: "No holder timeline snapshot loaded."
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

        Window {
            id: contactEditorWindow
            width: 920
            height: 640
            minimumWidth: 720
            minimumHeight: 500
            visible: false
            title: "Explorer Contacts"
            color: NuTokens.backgroundBase
            property int selectedIndex: -1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Explorer Contacts"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
	                Label {
	                    Layout.fillWidth: true
	                    text: root.activeContactSetLabel() + ". Local contact mappings can group one or more addresses under a username, handle, pool, or project name."
	                    color: NuTokens.textSecondary
	                    font.pixelSize: NuTokens.fontSmall
	                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuTextField {
                        id: contactEditorNameField
                        Layout.preferredWidth: 240
                        placeholderText: "username"
                    }
                    NuTextField {
                        id: contactEditorAddressField
                        Layout.fillWidth: true
                        placeholderText: "addresses, comma separated"
                    }
                    NuActionButton {
                        Layout.preferredWidth: 90
                        text: contactEditorWindow.selectedIndex >= 0 ? "Update" : "Save"
                        primary: true
                        onClicked: NuService.saveExplorerContact(contactEditorNameField.text, contactEditorAddressField.text, contactEditorWindow.selectedIndex)
                    }
                    NuActionButton {
                        Layout.preferredWidth: 82
                        text: "New"
                        onClicked: {
                            contactEditorWindow.selectedIndex = -1
                            contactEditorNameField.text = ""
                            contactEditorAddressField.text = ""
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 88
                        text: "Delete"
                        danger: true
                        enabled: contactEditorWindow.selectedIndex >= 0
                        onClicked: {
                            NuService.deleteExplorerContact(contactEditorWindow.selectedIndex)
                            contactEditorWindow.selectedIndex = -1
                            contactEditorNameField.text = ""
                            contactEditorAddressField.text = ""
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "internalExplorerContactsPopout"
                    columns: ["User", "Addresses", "Count"]
                    columnTypes: ["text", "address", "number"]
                    columnWeights: [1.0, 3.4, 0.45]
                    rows: root.contactRows()
                    emptyText: "No saved contact mappings yet."
                    rowSelectionEnabled: true
                    plainClickSelectsRows: true
                    rowKeyMetaField: "index"
                    onRowActivated: (row) => {
                        const meta = row.meta || {}
                        contactEditorWindow.selectedIndex = Number(meta.index !== undefined ? meta.index : -1)
                        contactEditorNameField.text = String(meta.username || "")
                        contactEditorAddressField.text = String(meta.addressText || "")
                    }
                }
            }
        }

        Window {
            id: contactGraphWindow
            width: 1040
            height: 760
            minimumWidth: 760
            minimumHeight: 560
            visible: false
            title: "Contact Relationship Graph"
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    Label {
                        Layout.fillWidth: true
                        text: "Contact Relationship Graph"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTitle
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        Layout.preferredWidth: 110
                        text: "Refresh"
                        onClicked: {
                            NuService.refreshExplorerContactRelationships()
                            contactGraphCanvas.requestPaint()
                        }
                    }
                }
	                Label {
	                    Layout.fillWidth: true
		                    text: root.activeContactSetLabel() + ". Drag nodes to rearrange the map. Node size follows current balance or historical received value when the current balance is zero. Line thickness follows indexed direct spend flow between saved contact groups."
	                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
                Canvas {
                    id: contactGraphCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawContactGraph(getContext("2d"), width, height)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.hoveredContactName.length > 0 || root.draggingContactName.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        ToolTip.visible: containsMouse && root.contactGraphToolTip(root.hoveredContactName).length > 0
                        ToolTip.text: root.contactGraphToolTip(root.hoveredContactName)
                        ToolTip.delay: NuTokens.tooltipDelay
                        ToolTip.timeout: NuTokens.tooltipTimeout
                        onPositionChanged: (mouse) => {
                            if (root.draggingContactName.length > 0) {
                                const dx = mouse.x - root.contactDragLastX
                                const dy = mouse.y - root.contactDragLastY
                                if (Math.abs(dx) + Math.abs(dy) > 0.5)
                                    root.contactDragMoved = true
                                root.dragContactGraphNode(root.draggingContactName, dx, dy, contactGraphCanvas.width, contactGraphCanvas.height)
                                root.contactDragLastX = mouse.x
                                root.contactDragLastY = mouse.y
                            } else {
                                root.hoveredContactName = root.contactGraphNodeAt(mouse.x, mouse.y, contactGraphCanvas.width, contactGraphCanvas.height)
                                contactGraphCanvas.requestPaint()
                            }
                        }
                        onPressed: (mouse) => {
                            root.draggingContactName = root.contactGraphNodeAt(mouse.x, mouse.y, contactGraphCanvas.width, contactGraphCanvas.height)
                            root.hoveredContactName = root.draggingContactName
                            root.contactDragLastX = mouse.x
                            root.contactDragLastY = mouse.y
                            root.contactDragMoved = false
                            contactGraphCanvas.requestPaint()
                        }
                        onReleased: {
                            const contact = root.contactGraphContact(root.draggingContactName)
                            const shouldOpen = contact && !root.contactDragMoved
                            root.draggingContactName = ""
                            contactGraphCanvas.requestPaint()
                            if (shouldOpen) {
                                const addresses = contact.addresses || []
                                if (addresses.length > 0)
                                    NuService.openAddressInExplorer(String(addresses[0]))
                            }
                        }
                        onExited: {
                            if (root.draggingContactName.length === 0) {
                                root.hoveredContactName = ""
                                contactGraphCanvas.requestPaint()
                            }
                        }
                    }
                }
                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    tableId: "internalExplorerContactGraphFlows"
                    columns: ["From", "To", "Total Flow", "Txs"]
                    columnTypes: ["text", "text", "amount", "number"]
                    columnWeights: [1.0, 1.0, 1.0, 0.45]
                    rows: NuService.explorerContactRelationships
                    emptyText: "No indexed contact-to-contact flows found yet."
                    defaultSortColumn: 2
                    defaultSortAscending: false
                }
            }
        }
    }
}
