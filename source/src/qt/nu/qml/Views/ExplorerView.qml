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
    property bool analyticsRequested: false
    property bool summaryRequested: false
    property var timelineSnapshot: ({ rows: [], height: -1, status: "No Top 100 timeline snapshot loaded." })
    property bool timelinePlaying: false
    property bool top100EndInitialized: false
    property bool top100EndEdited: false
    property bool top100UpdatingEndField: false
    property int selectedContactIndex: -1
    property string selectedContactName: ""
    readonly property real indexProgress: NuService.explorerIndexTip > 0
                                          ? Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
                                          : 0

    Connections {
        target: NuService
        function onExplorerChanged() {
            if (!top100EndField || root.top100EndEdited || NuService.explorerIndexTip <= 0) return
            if (!root.top100EndInitialized || top100EndField.text.length === 0)
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

    function refreshAnalytics(scope) {
        root.movementPage = 0
        root.analyticsRequested = true
        NuService.refreshExplorerAnalytics(root.movementThresholdCoins(), scope || "all")
    }

    function maybeRefreshAnalyticsForTab() {
        if (!root.active || root.analyticsRequested || !explorerTabs) return
        if (explorerTabs.currentIndex === 2)
            root.refreshAnalytics("rich")
        else if (explorerTabs.currentIndex === 3)
            root.refreshAnalytics("movements")
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

    function formatDfcFromSats(sats) {
        const value = Number(sats || 0) / 100000000.0
        return value.toLocaleString(Qt.locale(), "f", 8) + " DFC"
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
            root.distributionRow("#db38b8", "Top 1-25", top1_25, total, true),
            root.distributionRow("#48bd91", "Top 26-50", top26_50, total, true),
            root.distributionRow("#3d9ddd", "Top 51-75", top51_75, total, true),
            root.distributionRow("#ead934", "Top 76-100", top76_100, total, true),
            root.distributionRow("#8b95a1", "101+", rest, total, true),
            root.distributionRow("", "Top 1-100 Total", top100, total, false),
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
        const distance = Math.sqrt(dx * dx + dy * dy)
        if (distance > radius + 18) return ""
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
            ctx.moveTo(sx, sy)
            ctx.arc(sx, sy, radius, start, end)
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

    function contactBalanceMap() {
        const out = ({})
        for (let c = 0; c < NuService.explorerContacts.length; ++c) {
            const contact = NuService.explorerContacts[c]
            out[String(contact.username || "")] = 0
        }
        const ownerByAddress = ({})
        for (let i = 0; i < NuService.explorerContacts.length; ++i) {
            const contact = NuService.explorerContacts[i]
            const addresses = contact.addresses || []
            for (let a = 0; a < addresses.length; ++a)
                ownerByAddress[String(addresses[a])] = String(contact.username || "")
        }
        for (let r = 0; r < NuService.explorerRichList.length; ++r) {
            const meta = NuService.explorerRichList[r].meta || {}
            const owner = ownerByAddress[String(meta.address || "")]
            if (owner !== undefined) out[owner] += Number(meta.balanceSats || 0)
        }
        return out
    }

    function drawContactGraph(ctx, canvasWidth, canvasHeight) {
        ctx.reset()
        const contacts = NuService.explorerContacts
        const relationships = NuService.explorerContactRelationships
        const cx = canvasWidth / 2
        const cy = canvasHeight / 2
        const radius = Math.max(80, Math.min(canvasWidth, canvasHeight) * 0.34)
        const balances = root.contactBalanceMap()
        let maxBalance = 1
        for (const name in balances) maxBalance = Math.max(maxBalance, Number(balances[name] || 0))
        const positions = ({})
        for (let i = 0; i < contacts.length; ++i) {
            const name = String(contacts[i].username || "")
            const angle = -Math.PI / 2 + Math.PI * 2 * i / Math.max(1, contacts.length)
            positions[name] = { x: cx + Math.cos(angle) * radius, y: cy + Math.sin(angle) * radius }
        }
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
            ctx.globalAlpha = 0.35
            ctx.lineWidth = 1 + 8 * amount / maxFlow
            ctx.beginPath()
            ctx.moveTo(source.x, source.y)
            ctx.lineTo(target.x, target.y)
            ctx.stroke()
        }
        ctx.globalAlpha = 1
        for (let n = 0; n < contacts.length; ++n) {
            const name = String(contacts[n].username || "")
            const pos = positions[name]
            const nodeRadius = 14 + 24 * Math.sqrt(Number(balances[name] || 0) / maxBalance)
            ctx.fillStyle = "#f3d447"
            ctx.strokeStyle = NuTokens.textPrimary
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(pos.x, pos.y, nodeRadius, 0, Math.PI * 2)
            ctx.fill()
            ctx.stroke()
            ctx.fillStyle = NuTokens.textPrimary
            ctx.font = "700 12px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText(name, pos.x, pos.y)
        }
        if (contacts.length === 0) {
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.fillText("Add contacts to chart address relationships.", cx, cy)
        }
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
            if (wealthDistributionPie)
                wealthDistributionPie.requestPaint()
            if (whaleConcentrationPie)
                whaleConcentrationPie.requestPaint()
            if (contactGraphCanvas)
                contactGraphCanvas.requestPaint()
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
        Layout.preferredHeight: Math.max(184, explorerStatusContent.implicitHeight + padding * 2)
        Layout.minimumHeight: Math.max(184, explorerStatusContent.implicitHeight + padding * 2)
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
                            width: 74
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
                        focusPolicy: Qt.StrongFocus
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
                        focusPolicy: Qt.StrongFocus
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
                NuMetricRow { label: "Top 100 checkpoints"; value: String(NuService.explorerTop100TimelineEventCount) }
                NuMetricRow { label: "Movements"; value: String(NuService.explorerMovements.length) }
            }
        }
    }

    NuTabBar {
        id: explorerTabs
        Layout.fillWidth: true
        onCurrentIndexChanged: root.maybeRefreshAnalyticsForTab()
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm
                    Label {
                        Layout.fillWidth: true
                        text: "Top 100 timeline index"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    NuActionButton {
                        width: 74
                        text: "Copy"
                        helpText: "Copy the Top 100 timeline status or error text."
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
                    focusPolicy: Qt.StrongFocus
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
                    text: "Top 100 timeline can scan through block " + NuService.explorerIndexTip + ", the Explorer indexed height."
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
                        helpText: "Delete only the Top 100 over-time checkpoint rows and ranges."
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
                        helpText: "When enabled, Nu uses larger Explorer and Top 100 batches, larger SQLite cache settings, fewer UI refreshes, and tries to raise indexing priority. Use this for a dedicated indexing run on a mostly idle machine."
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
                                enabled: NuService.explorerIndexedBlockCount > 0
                                         && NuService.explorerIndexTip > 0
                                         && NuService.explorerIndexHeight > NuService.explorerIndexTip
                                         && !NuService.explorerIndexing
                                helpText: "Reload the Top 100 table after the local Explorer index is complete, usually after new blocks arrive."
                                onClicked: root.refreshAnalytics("rich")
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
                            NuMetricRow { label: "Timeline"; value: NuService.explorerTop100TimelineEventCount + " checkpoints" }
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: NuService.explorerIndexing || NuService.explorerIndexHeight <= NuService.explorerIndexTip
                            text: "Refresh Top 100 enables after the Explorer index reaches the current chain tip; until then this pane shows the latest cached partial result."
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: NuTokens.lineSubtle
                }

                Label {
                    Layout.fillWidth: true
                    text: "Wealth Distribution"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "Grouped like the eIquidus rich-list view: four Top 100 bands plus every indexed address outside the Top 100."
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
                        onPaint: root.drawDistributionPie(getContext("2d"), width, height, root.wealthDistributionRows(), "Wealth", "distribution", root.selectedWealthGroup)
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
                        emptyText: "Build the Explorer index and refresh Top 100 to calculate wealth distribution."
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

                Label {
                    Layout.fillWidth: true
                    text: "Whale Concentration"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "A Pareto-style concentration view separates the largest address, the next nine addresses, the rest of the Top 25, the rest of the Top 100, and everyone else."
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
                        onPaint: root.drawDistributionPie(getContext("2d"), width, height, root.whaleConcentrationRows(), "Whale", "concentration", root.selectedWhaleGroup)
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
                        emptyText: "Build the Explorer index and refresh Top 100 to calculate concentration."
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
                        text: "Chart relationships"
                        primary: true
                        helpText: "Build an indexed relationship graph from saved contact addresses."
                        onClicked: {
                            NuService.refreshExplorerContactRelationships()
                            contactGraphCanvas.requestPaint()
                            contactGraphWindow.show()
                            contactGraphWindow.raise()
                            contactGraphWindow.requestActivate()
                        }
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
                    Layout.maximumWidth: Math.max(220, top100TimelineWindow.width * 0.32)
                    text: NuService.explorerTop100TimelineEventCount + " checkpoints"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }
                NuActionButton {
                    Layout.preferredWidth: 94
                    text: root.timelinePlaying ? "Pause" : "Play"
                    helpText: "Animate the pie chart forward through stored Top 100 timeline checkpoints."
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
                        ctx.fillText("Build Top 100 timeline", cx, cy)
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
                    ctx.fillText("Top 100", cx, cy - 8)
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
                    text: "Local contact mappings can group one or more addresses under a username, handle, pool, or project name."
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
                    text: "Node size is based on saved addresses that also appear in the current Top 100. Line thickness is based on indexed direct spend flow between saved contact groups."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
                Canvas {
                    id: contactGraphCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawContactGraph(getContext("2d"), width, height)
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
