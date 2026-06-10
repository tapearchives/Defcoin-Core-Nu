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
    property int initialTab: 0
    property int initialPeerView: 0
    property bool trafficPaused: false
    property var frozenTrafficSamples: []
    property real trafficWindowStart: 0
    property real trafficWindowEnd: 1
    property string logFilterError: ""
    property int shownLogLineCount: 0
    property int logPopoutFontSize: 12
    property var logFilterPresetModel: []
    property string peerSortKey: ""
    property bool peerSortAscending: true
    property string peerSimpleSortKey: ""
    property bool peerSimpleSortAscending: true
    property string peerDetailedSortKey: ""
    property bool peerDetailedSortAscending: true
    property bool detailsMode: root.initialPeerView === 1
    property var statusRows: []
    property var selectedPeerNodeIds: []
    property var selectedBannedPeerKeys: []
    readonly property int trafficMaxChartSeconds: 7 * 24 * 60 * 60
    property var simplePeerColumns: ["Node", "Dir", "IP Address: Port", "Methods", "Ping", "Sent", "Rec'd", "User Agent"]
    property var simplePeerTypes: ["number", "text", "ipport", "center", "duration", "bytes", "bytes", "text"]
    property var simplePeerSortKeys: ["node", "direction", "ip", "transportMethods", "ping", "sent", "received", "userAgent"]
    property var simplePeerWeights: [0.38, 0.24, 1.7, 0.46, 0.42, 0.42, 0.42, 1.35]
    property var simplePeerMinimums: [48, 34, 132, 66, 52, 58, 58, 92]
    property var simplePeerMaximums: [64, 42, 390, 92, 74, 82, 82, 280]
    property var simplePeerTooltips: [
        "Backend peer connection ID for this session.",
        "Litecoin/Core getpeerinfo convention. In = inbound: the remote peer opened the connection into this node. Out = outbound: this node opened the connection to the peer.",
        "Peer endpoint, including IP address and TCP port.",
        "Transport methods that have successfully exchanged data with this peer during this Nu session: TCP, UDP, or TCP+UDP.",
        "Current round-trip latency reported by the backend. This is Core's P2P ping time, not the same as an ICMP ping command in Terminal; ICMP can differ because it uses a different protocol and may be filtered or prioritized differently.",
        "Total bytes sent to this peer since the connection opened.",
        "Total bytes received from this peer since the connection opened.",
        "Software name and version reported by the peer."
    ]
    readonly property int legacyDetailedLanColumnStart: 4
    readonly property int detailedFastSyncColumnIndex: 9
    property var detailedPeerColumns: ["Node", "Dir.", "IP", "Port", "Reverse\nDNS Name", "Seed Source /\nLAN Workstation Name", "Protocol\nVersion", "Magic", "Services", "Fast\nSync\nAvail", "Methods", "Ping", "Min Ping", "Sent", "Rec'd", "User Agent", "Connection Time", "Start\nHeight", "Last Send", "Last Recv", "Last TX", "Last Block", "Synced\nHeaders", "Synced\nBlocks", "Conn Type", "Network", "Addr\nEntries", "Min Fee\nFilter"]
    property var detailedPeerTypes: ["number", "text", "ipport", "number", "reverseDns", "seedLanSource", "number", "text", "center", "center", "center", "duration", "duration", "bytes", "bytes", "text", "date", "number", "date", "date", "date", "date", "number", "number", "text", "text", "number", "amount"]
    property var detailedPeerSortKeys: ["node", "direction", "ip", "port", "reverseDns", "knownDns", "protocol", "magic", "services", "fastSyncAvailable", "transportMethods", "ping", "minPing", "sent", "received", "userAgent", "connectionTime", "startHeight", "lastSend", "lastRecv", "lastTx", "lastBlock", "syncedHeaders", "syncedBlocks", "connectionType", "network", "addrEntries", "minFeeFilter"]
    property var detailedPeerSortMetaFields: ["", "", "", "", "reverseDnsSort", "knownDnsSort", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
    property var detailedPeerWeights: [0.34, 0.28, 1.05, 0.34, 1.05, 1.35, 0.5, 0.55, 0.42, 0.42, 0.42, 0.46, 0.5, 0.42, 0.42, 1.35, 1.05, 0.55, 1.05, 1.05, 1.05, 1.05, 0.62, 0.62, 0.8, 0.58, 0.62, 0.76]
    property var detailedPeerMinimums: [44, 34, 128, 46, 90, 164, 62, 74, 54, 58, 58, 58, 58, 58, 58, 92, 130, 70, 130, 130, 130, 130, 80, 80, 84, 64, 76, 90]
    property var detailedPeerMaximums: [62, 42, 330, 70, 240, 340, 82, 92, 80, 68, 68, 78, 84, 82, 82, 260, 168, 96, 168, 168, 168, 168, 108, 108, 136, 110, 108, 130]
    property var detailedPeerTooltips: [
        "Backend peer connection ID for this session.",
        "Litecoin/Core getpeerinfo convention. In = inbound: the remote peer opened the connection into this node. Out = outbound: this node opened the connection to the peer.",
        "Peer IP address without the port. IPv4 values use fixed-width octet spacing so dots align.",
        "Peer TCP port.",
        "Best-effort reverse DNS name for the peer IP address. Blank means no reverse DNS name has resolved yet.",
        "Configured seed/source domain or confirmed LAN workstation name associated with this peer address. LAN rows show a small local-network icon before the name; hover the cell for the discovery source such as Bonjour, SMB/NetBIOS, host-name resolution, or optional nmap output.",
        "P2P protocol version reported by the peer.",
        "Actual network message-start bytes selected for this peer, such as defc014e or fbc0b6db.",
        "Compact service flags advertised by the peer. Hover an entry for the full service-bit names and meanings.",
        "UDP fast-sync capability state. Advertised means bit 29 is present but no UDP probe has succeeded yet. Probe sent means Nu has sent a UDP negotiation probe. No reply means the probe timed out or failed. Yes means a valid UDP Fast Sync response was received.",
        "Transport methods that have successfully exchanged data with this peer during this Nu session: TCP means normal peer sync bytes; UDP means fast-sync block data; TCP+UDP means both.",
        "Current round-trip latency reported by the backend. This is Core's P2P ping time, not the same as an ICMP ping command in Terminal; ICMP can differ because it uses a different protocol and may be filtered or prioritized differently.",
        "Best observed ping for this connection.",
        "Total bytes sent to this peer since the connection opened.",
        "Total bytes received from this peer since the connection opened.",
        "Software name and version reported by the peer.",
        "Local time when this peer connection opened.",
        "Block height the peer reported during version negotiation.",
        "Local time of the last message sent to this peer.",
        "Local time of the last message received from this peer.",
        "Local time of the last valid transaction received from this peer.",
        "Local time of the last block received from this peer.",
        "Last header height currently known in common with this peer. Unknown means the backend has not established one yet.",
        "Last block height currently known in common with this peer. Unknown means the backend has not established one yet.",
        "Backend connection type, such as outbound-full-relay, inbound, manual, or block-relay.",
        "Network transport used by the peer, such as ipv4, ipv6, onion, or i2p.",
        "Cumulative addr/addrv2 relay entries processed from this peer during this connection after Defcoin user-agent and port filters. This is not a unique node count; one peer can send up to about 1000 address records in one response.",
        "Minimum transaction relay fee rate this peer has announced with its feefilter policy, displayed as DFC per kilobyte."
    ]

    function normalizeDetailedPeerCells(row) {
        let cells = []
        if (row && row.cells !== undefined) cells = row.cells.slice()
        else if (row) cells = row.slice()

        function looksLikeLanMarker(value) {
            const text = String(value === undefined || value === null ? "" : value).trim()
            return text.length === 0 || text === "LAN" || text === "-"
        }

        function looksLikeFastSyncValue(value) {
            const text = String(value === undefined || value === null ? "" : value).trim()
            return text === "Yes" || text === "No" || text === "Off" || text === "Advertised" || text === "Probe sent"
                    || text === "No reply" || text === "Checking" || text === "TBA" || text === "Failed" || text === "-"
        }

        if (cells.length === root.detailedPeerColumns.length + 1
                && looksLikeLanMarker(cells[root.legacyDetailedLanColumnStart])) {
            cells.splice(root.legacyDetailedLanColumnStart, 1)
        }
        if (cells.length > root.detailedFastSyncColumnIndex
                && !looksLikeFastSyncValue(cells[root.detailedFastSyncColumnIndex])) {
            cells.splice(root.detailedFastSyncColumnIndex, 0, "Checking", "-")
        }
        while (cells.length < root.detailedPeerColumns.length) cells.push("")
        if (cells.length > root.detailedPeerColumns.length) cells = cells.slice(0, root.detailedPeerColumns.length)
        return cells
    }

    function displayedDetailedPeerRows() {
        const source = NuService.peerRowsDetailed || []
        let rows = []
        for (let r = 0; r < source.length; ++r) {
            const row = source[r]
            const rawCells = row && row.cells !== undefined ? row.cells : row
            const legacyLanRow = rawCells
                                  && rawCells.length === root.detailedPeerColumns.length + 1
                                  && String(rawCells[root.legacyDetailedLanColumnStart] || "").trim() === "LAN"
            const cells = normalizeDetailedPeerCells(row)
            let meta = ({})
            if (row && row.meta !== undefined) {
                for (let key in row.meta) meta[key] = row.meta[key]
            }
            if (legacyLanRow && meta.isLanPeer === undefined) meta.isLanPeer = true
            if (meta.cellTooltips !== undefined && meta.cellTooltips !== null
                    && meta.cellTooltips.length === root.detailedPeerColumns.length + 1) {
                let tips = meta.cellTooltips.slice()
                tips.splice(root.legacyDetailedLanColumnStart, 1)
                meta.cellTooltips = tips
            }
            rows.push({ "cells": cells, "meta": meta })
        }
        return rows
    }

    function selectedPeerRowIds() {
        const source = peersTable ? peersTable.selectedDataRowKeys() : root.selectedPeerNodeIds
        let ids = []
        for (let i = 0; source && i < source.length; ++i) {
            const clean = String(source[i] === undefined || source[i] === null ? "" : source[i]).trim()
            if (/^[0-9]+$/.test(clean) && ids.indexOf(clean) < 0) ids.push(clean)
        }
        return ids
    }

    function selectedSinglePeerRowId() {
        const ids = selectedPeerRowIds()
        return ids.length === 1 ? ids[0] : ""
    }

    function hasSinglePeerRowSelection() {
        return selectedSinglePeerRowId().length > 0
    }

    function applyPeerSortForCurrentView() {
        if (!peersTable) return
        const viewKey = root.detailsMode ? root.peerDetailedSortKey : root.peerSimpleSortKey
        const viewAscending = root.detailsMode ? root.peerDetailedSortAscending : root.peerSimpleSortAscending
        if (viewKey.length > 0 && peersTable.applyExternalSort(viewKey, viewAscending)) return
        if (root.peerSortKey.length > 0 && peersTable.applyExternalSort(root.peerSortKey, root.peerSortAscending)) return
        peersTable.sortColumn = -1
    }

    function displayedStatusRows() {
        const source = NuService.nodeMetrics || []
        if (root.detailsMode) return source
        let rows = []
        for (let i = 0; i < source.length; ++i) {
            const row = source[i]
            const meta = row && row.meta !== undefined ? row.meta : ({})
            if (meta.detail !== true) rows.push(row)
        }
        return rows
    }

    function refreshDisplayedStatusRows() {
        root.statusRows = root.displayedStatusRows()
    }

    function durationText(seconds) {
        seconds = Math.max(0, Math.round(seconds))
        if (seconds < 60) return seconds + " sec"
        const minutes = Math.floor(seconds / 60)
        const remainder = seconds % 60
        if (minutes < 60) return remainder === 0 ? minutes + " min" : minutes + " min " + remainder + " sec"
        const hours = Math.floor(minutes / 60)
        const minuteRemainder = minutes % 60
        if (hours >= 24) {
            const days = Math.floor(hours / 24)
            const hourRemainder = hours % 24
            const dayText = days === 1 ? "1 day" : days + " days"
            return hourRemainder === 0 ? dayText : dayText + " " + hourRemainder + " hr"
        }
        return minuteRemainder === 0 ? hours + " hr" : hours + " hr " + minuteRemainder + " min"
    }

    function sampleRangeText() {
        var samples = root.trafficPaused ? root.frozenTrafficSamples : NuService.trafficSamples
        if (!samples || samples.length < 2) return "Waiting for samples"
        var firstTime = samples[0].timestampMs ? samples[0].timestampMs : Date.now()
        var lastTime = samples[samples.length - 1].timestampMs ? samples[samples.length - 1].timestampMs : firstTime
        var spanMs = Math.max(1000, lastTime - firstTime)
        var startDate = new Date(firstTime + spanMs * root.trafficWindowStart)
        var endDate = new Date(firstTime + spanMs * root.trafficWindowEnd)
        var visibleSeconds = Math.max(0, (endDate.getTime() - startDate.getTime()) / 1000)
        var text = startDate.toLocaleString() + " - " + endDate.toLocaleString()
        text += " | " + root.durationText(visibleSeconds) + " visible"
        text += " | Max. chart length: " + root.durationText(root.trafficMaxChartSeconds)
        return text
    }

    function tabToStack(tabIndex) {
        if (tabIndex === 1) return 0 // Status
        if (tabIndex === 2) return 1 // Peers
        return 2 // Traffic
    }

    function logVerbosityName(level) {
        const names = ["All details", "Standard", "Important", "Warnings"]
        const index = Math.max(0, Math.min(3, Math.round(level)))
        return names[index]
    }

    function safeLogRegex(pattern) {
        const clean = String(pattern || "")
        if (clean.length === 0) return null
        if (clean.length > 160) {
            root.logFilterError = "Regex filters are limited to 160 characters."
            return false
        }
        try {
            return new RegExp(clean, "i")
        } catch (error) {
            root.logFilterError = "Malformed regex: " + error.message
            return false
        }
    }

    function logLineBucket(line) {
        const text = String(line || "").toLowerCase()

        // Bucket numbers intentionally match the verbosity slider threshold:
        // 0 = raw details, 1 = standard operational lines, 2 = important milestones,
        // 3 = warnings/problems only.
        if (text.indexOf("fatal") >= 0 || text.indexOf("crash") >= 0 || text.indexOf("error") >= 0
                || text.indexOf("failed") >= 0 || text.indexOf("warning") >= 0
                || text.indexOf("not defcoin-prefixed") >= 0 || text.indexOf("disconnecting before address relay") >= 0
                || text.indexOf("disconnecting outbound peer") >= 0 || text.indexOf("old chain") >= 0
                || text.indexOf("reject") >= 0 || text.indexOf("banned") >= 0 || text.indexOf("timeout") >= 0
                || text.indexOf("orphan") >= 0 || text.indexOf("reorg") >= 0 || text.indexOf("stale") >= 0) {
            return 3
        }

        if (text.indexOf("----- nu startup diagnostics") >= 0
                || text.indexOf("nu startup: frontend application launched") >= 0
                || text.indexOf("nu startup: network preferences") >= 0
                || text.indexOf("nu startup: wallet selected") >= 0
                || text.indexOf("nu startup: rpc credentials are available") >= 0
                || text.indexOf("starting backend") >= 0
                || text.indexOf("backend rpc is connected") >= 0
                || text.indexOf("init message: done loading") >= 0
                || text.indexOf("loaded best chain") >= 0
                || text.indexOf("nbestheight") >= 0
                || text.indexOf("leaving initialblockdownload") >= 0
                || text.indexOf("new outbound peer connected") >= 0
                || text.indexOf("addresses found from dns seeds") >= 0) {
            return 2
        }

        if (text.indexOf("init message:") >= 0 || text.indexOf("wallet completed loading") >= 0
                || text.indexOf("wallet file version") >= 0 || text.indexOf("keys:") >= 0
                || text.indexOf("loading addresses from dns seed") >= 0
                || text.indexOf("adding fixed seed nodes") >= 0
                || text.indexOf("bound to ") >= 0 || text.indexOf("loaded ") >= 0
                || text.indexOf("thread start") >= 0 || text.indexOf("thread exit") >= 0
                || text.indexOf("updatetip:") >= 0 || text.indexOf("addtowallet") >= 0
                || text.indexOf("submitting wtx") >= 0 || text.indexOf("setting") >= 0
                || text.indexOf("traffic") >= 0 || text.indexOf("mempool") >= 0
                || text.indexOf("p2p") >= 0 || text.indexOf("peer") >= 0
                || text.indexOf("rpc") >= 0 || text.indexOf("connect") >= 0) {
            return 1
        }

        return 0
    }

    function leftPadNumber(value, width) {
        var out = String(value)
        while (out.length < width) out = " " + out
        return out
    }

    function numberedLogLine(viewLineNumber, viewWidth, debugLineNumber, debugWidth, line) {
        const viewLabel = root.leftPadNumber(viewLineNumber, viewWidth)
        const debugLabel = debugLineNumber > 0 ? root.leftPadNumber(debugLineNumber, debugWidth) : root.leftPadNumber("-", debugWidth)
        return viewLabel + " \u2502 " + debugLabel + " \u2502 " + String(line || "")
    }

    function numberedLogText(lines) {
        const out = []
        const viewWidth = String(Math.max(1, lines.length)).length
        var maxLineNumber = 1
        for (let maxIndex = 0; maxIndex < lines.length; ++maxIndex) {
            if (lines[maxIndex].lineNumber > maxLineNumber) maxLineNumber = lines[maxIndex].lineNumber
        }
        const debugWidth = String(maxLineNumber).length
        for (let i = 0; i < lines.length; ++i) {
            out.push(root.numberedLogLine(i + 1, viewWidth, lines[i].lineNumber, debugWidth, lines[i].line))
        }
        return out.join("\n")
    }

    function logFilterPresets() {
        const presets = [
            "[type search term here]",
            "Error",
            "Warning",
            "failed|timeout|disconnect",
            "valid fork|stale|reorg|orphan",
            "scriptPubKey Manager|sqlwallet|descriptor",
            "wallet|loadwallet|createwallet|AddToWallet",
            "block index|Reindex|FlushStateToDisk",
            "witness|NODE_WITNESS|SegWit",
            "RPC|ThreadRPCServer|HTTP",
            "connect|disconnect|timeout|socket",
            "fast sync|UDP|TCP",
            "UpdateTip",
            "seednode|dns seed|fixed seed",
            "receive version message",
            "version "
        ]
        const last = String(NuService.logLastSearchPattern || "").trim()
        if (last.length > 0 && presets.indexOf(last) < 0) presets.push("Last: " + last)
        return presets
    }

    function refreshLogFilterPresets() {
        root.logFilterPresetModel = root.logFilterPresets()
    }

    function logPresetValue(label) {
        const text = String(label || "")
        if (text === "[type search term here]") return ""
        if (text.indexOf("Last: ") === 0) return text.substring(6)
        return text
    }

    function setLogSearchPattern(pattern) {
        NuService.logSearchPattern = String(pattern || "").substring(0, 160)
        root.refreshLogFilterPresets()
    }

    function findInLog(backward) {
        const needle = String(logFindField.text || "")
        if (needle.length === 0) return
        const hay = launchLogText.text
        const lowerHay = hay.toLowerCase()
        const lowerNeedle = needle.toLowerCase()
        var index = -1
        if (backward) {
            const startBack = Math.max(0, launchLogText.selectionStart - 1)
            index = lowerHay.lastIndexOf(lowerNeedle, startBack)
            if (index < 0) index = lowerHay.lastIndexOf(lowerNeedle)
        } else {
            const startForward = Math.max(0, launchLogText.selectionEnd)
            index = lowerHay.indexOf(lowerNeedle, startForward)
            if (index < 0) index = lowerHay.indexOf(lowerNeedle)
        }
        if (index >= 0) {
            launchLogText.forceActiveFocus()
            launchLogText.select(index, index + needle.length)
            launchLogText.cursorPosition = index + needle.length
        }
    }

    function filteredLogText() {
        root.logFilterError = ""
        const search = safeLogRegex(NuService.logSearchPattern)
        const remove = safeLogRegex(NuService.logRemovePattern)
        if (search === false || remove === false) {
            root.shownLogLineCount = NuService.logLines.length
            const allLines = []
            for (let allIndex = 0; allIndex < NuService.logLines.length; ++allIndex) {
                const allLineNumber = NuService.logLineNumbers && NuService.logLineNumbers.length > allIndex ? Number(NuService.logLineNumbers[allIndex]) : 0
                allLines.push({ "lineNumber": allLineNumber, "line": NuService.logLines[allIndex] })
            }
            return root.numberedLogText(allLines)
        }
        const level = Math.max(0, Math.min(3, NuService.logVerbosity))
        const out = []
        for (let i = 0; i < NuService.logLines.length; ++i) {
            const line = String(NuService.logLines[i])
            if (level > 0 && root.logLineBucket(line) < level) continue
            if (search && !search.test(line)) continue
            if (remove && remove.test(line)) continue
            const lineNumber = NuService.logLineNumbers && NuService.logLineNumbers.length > i ? Number(NuService.logLineNumbers[i]) : 0
            out.push({ "lineNumber": lineNumber, "line": line })
        }
        root.shownLogLineCount = out.length
        if (out.length === 0) {
            if (NuService.logLines.length > 0) {
                return "No launch log lines match the current Filter, Remove, and Verbosity settings. Clear the filters or set Verbosity to All details."
            }
            return "No launch log lines have been recorded yet. Nu startup diagnostics should appear here shortly."
        }
        return root.numberedLogText(out)
    }

    spacing: NuTokens.spaceLg

    onDetailsModeChanged: {
        root.refreshDisplayedStatusRows()
        Qt.callLater(function() {
            root.applyPeerSortForCurrentView()
            if (peersTable) peersTable.forceResetColumnWidths()
        })
    }

    Component.onCompleted: {
        root.refreshLogFilterPresets()
        root.refreshDisplayedStatusRows()
    }

    Connections {
        target: NuService
        function onNodeMetricsChanged() { root.refreshDisplayedStatusRows() }
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Metrics"
        detail: "Traffic, sync status, peer details, and network health."
        dense: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: NuTokens.spaceMd

        NuDetailsSwitch {
            id: globalDetailsSwitch
            checked: root.detailsMode
            helpText: "Show detailed traffic components, full sync diagnostics, and the full peer protocol table."
            onCheckedChanged: root.detailsMode = checked
        }

        Label {
            Layout.fillWidth: true
            text: root.detailsMode
                  ? "Detailed transport, sync, and peer diagnostics."
                  : "Primary sync health, traffic, and peer status."
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            elide: Text.ElideRight
        }
    }

    NuTabBar {
        id: tabs
        Layout.fillWidth: true
        currentIndex: root.initialTab
        NuTabButton { text: "Traffic" }
        NuTabButton { text: "Status" }
        NuTabButton { text: "Peers" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.tabToStack(tabs.currentIndex)

        ColumnLayout {
            spacing: NuTokens.spaceMd

            NuDataTable {
                tableId: root.detailsMode ? "nodeStatusMetricsDetailed" : "nodeStatusMetricsSimple"
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: ["Metric", "Value"]
                columnTooltips: [
                    "Status metric reported by the local backend or Nu frontend.",
                    "Current value. The default view shows the highest-value sync and node health rows; Details adds lower-frequency diagnostics."
                ]
                columnTypes: ["text", "text"]
                columnWeights: [0.78, 4.0]
                columnMinimums: [230, 380]
                columnMaximums: [300, 1600]
                fitColumnsToViewport: true
                wrapBodyText: true
                maxWrappedBodyLines: root.detailsMode ? 3 : 2
                compact: true
                autoFitOnRowsChanged: true
                alwaysShowHorizontalScrollBar: false
                restoreSavedColumnWidths: false
                rows: root.statusRows
                emptyText: "Node status hydrates here."
            }
        }

        ColumnLayout {
            spacing: NuTokens.spaceMd

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: root.detailsMode
                          ? "Full protocol fields for network inspection."
                          : "Core peer health and traffic."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    elide: Text.ElideRight
                }

                NuActionButton {
                    text: "Retest FastSync"
                    Layout.preferredWidth: 136
                    enabled: root.hasSinglePeerRowSelection()
                    helpText: "Clear this peer's cached UDP Fast Sync state, reconnect, and test Fast Sync negotiation again."
                    onClicked: NuService.refreshPeer(root.selectedSinglePeerRowId())
                }

                NuActionButton {
                    text: "Ban peer"
                    Layout.preferredWidth: 104
                    enabled: root.hasSinglePeerRowSelection()
                    helpText: "Add the selected peer address to Core's ban list and disconnect it."
                    onClicked: NuService.banPeer(root.selectedSinglePeerRowId())
                }
            }

            NuDataTable {
                id: peersTable
                Layout.fillWidth: true
                Layout.fillHeight: true
                compact: true
                fontPixelSize: NuTokens.fontTiny
                rowSelectionEnabled: true
                plainClickSelectsRows: true
                rowKeyMetaField: "nodeId"
                selectedRowKeys: root.selectedPeerNodeIds
                alwaysShowHorizontalScrollBar: root.detailsMode
                tableId: root.detailsMode ? "nodePeersDetailed" : "nodePeersSimple"
                restoreSavedColumnWidths: false
                columns: root.detailsMode ? root.detailedPeerColumns : root.simplePeerColumns
                columnTooltips: root.detailsMode ? root.detailedPeerTooltips : root.simplePeerTooltips
                columnTypes: root.detailsMode ? root.detailedPeerTypes : root.simplePeerTypes
                sortColumnKeys: root.detailsMode ? root.detailedPeerSortKeys : root.simplePeerSortKeys
                columnSortMetaFields: root.detailsMode ? root.detailedPeerSortMetaFields : []
                columnWeights: root.detailsMode ? root.detailedPeerWeights : root.simplePeerWeights
                columnMinimums: root.detailsMode ? root.detailedPeerMinimums : root.simplePeerMinimums
                columnMaximums: root.detailsMode ? root.detailedPeerMaximums : root.simplePeerMaximums
                rows: root.detailsMode ? root.displayedDetailedPeerRows() : NuService.peerRowsSimple
                emptyText: "Peers hydrate here after the tab renders."
                onRowSelectionChanged: (keys) => root.selectedPeerNodeIds = keys
                onSortChanged: (column, ascending, key) => {
                    root.peerSortKey = key
                    root.peerSortAscending = ascending
                    if (root.detailsMode) {
                        root.peerDetailedSortKey = key
                        root.peerDetailedSortAscending = ascending
                    } else {
                        root.peerSimpleSortKey = key
                        root.peerSimpleSortAscending = ascending
                    }
                }

                Connections {
                    target: NuService
                    function onSettingsChanged() {
                        Qt.callLater(function() {
                            root.applyPeerSortForCurrentView()
                            peersTable.forceResetColumnWidths()
                        })
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: NuService.peerCount + " peers"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }

                NuActionButton {
                    text: "Unban selected"
                    Layout.preferredWidth: 132
                    enabled: root.selectedBannedPeerKeys.length > 0
                    helpText: "Remove selected addresses from Core's ban list."
                    onClicked: {
                        for (let i = 0; i < root.selectedBannedPeerKeys.length; ++i) {
                            NuService.unbanPeer(root.selectedBannedPeerKeys[i])
                        }
                        root.selectedBannedPeerKeys = []
                    }
                }

                NuActionButton {
                    text: "Refresh bans"
                    Layout.preferredWidth: 120
                    helpText: "Reload Core's current banned peer list."
                    onClicked: NuService.refreshBannedPeers()
                }
            }

            NuDataTable {
                id: bannedPeersTable
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(156, Math.max(78, 34 + NuService.bannedPeerRows.length * 24))
                compact: true
                fontPixelSize: NuTokens.fontTiny
                rowSelectionEnabled: true
                plainClickSelectsRows: true
                rowKeyMetaField: "address"
                selectedRowKeys: root.selectedBannedPeerKeys
                columns: ["Banned Address", "Reason", "Created", "Expires"]
                columnTypes: ["ipport", "text", "date", "date"]
                sortColumnKeys: ["address", "reason", "created", "expires"]
                columnWeights: [1.25, 0.8, 1.0, 1.0]
                columnMinimums: [160, 90, 150, 150]
                columnMaximums: [420, 220, 210, 210]
                restoreSavedColumnWidths: false
                rows: NuService.bannedPeerRows
                emptyText: "No banned peers."
                onRowSelectionChanged: (keys) => root.selectedBannedPeerKeys = keys
            }
        }

        ColumnLayout {
            spacing: NuTokens.spaceMd

            NuTimelineGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                detailsMode: root.detailsMode
                samples: root.trafficPaused ? root.frozenTrafficSamples : NuService.trafficSamples
                windowStart: root.trafficWindowStart
                windowEnd: root.trafficWindowEnd
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd
                Label {
                    text: "Visible time range"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }
                Label {
                    Layout.fillWidth: true
                    text: root.sampleRangeText()
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    elide: Text.ElideRight
                }
            }

            NuTimelineWindow {
                Layout.fillWidth: true
                start: root.trafficWindowStart
                end: root.trafficWindowEnd
                onViewportChanged: (start, end) => {
                    root.trafficWindowStart = start
                    root.trafficWindowEnd = end
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                GridLayout {
                    columns: 5
                    rowSpacing: 2
                    columnSpacing: NuTokens.spaceMd

                    Label {
                        text: ""
                        font.pixelSize: NuTokens.fontTiny
                    }
                    Label {
                        text: "TCP"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontTiny
                        font.bold: true
                    }
                    Label {
                        text: "FS UDP"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontTiny
                        font.bold: true
                        ToolTip.visible: fsUdpHeaderHover.hovered
                        ToolTip.text: "Fast Sync UDP"
                        ToolTip.delay: NuTokens.tooltipDelay
                        HoverHandler { id: fsUdpHeaderHover }
                    }
                    Label {
                        text: "QC UDP"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontTiny
                        font.bold: true
                        ToolTip.visible: qcUdpHeaderHover.hovered
                        ToolTip.text: "Quick Clone UDP"
                        ToolTip.delay: NuTokens.tooltipDelay
                        HoverHandler { id: qcUdpHeaderHover }
                    }
                    Label {
                        text: "Total traffic"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontTiny
                        font.bold: true
                    }

                    Label {
                        text: "Total rec'd:"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontTiny
                    }
                    Label {
                        text: NuService.trafficTcpReceivedTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                    }
                    Label {
                        text: NuService.trafficFastSyncUdpReceivedTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                    }
                    Label {
                        text: NuService.trafficQuickCloneReceivedTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                    }
                    Label {
                        text: NuService.trafficReceivedTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                        font.bold: true
                    }

                    Label {
                        text: "Total sent:"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontTiny
                    }
                    Label {
                        text: NuService.trafficTcpSentTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                    }
                    Label {
                        text: NuService.trafficFastSyncUdpSentTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                    }
                    Label {
                        text: NuService.trafficQuickCloneSentTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                    }
                    Label {
                        text: NuService.trafficSentTotal
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTiny
                        font.family: NuTokens.monoFont
                        font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                NuActionButton {
                    text: root.trafficPaused ? "Resume" : "Pause"
                    Layout.preferredWidth: 112
                    helpText: "Pause graph animation while continuing capture."
                    onClicked: {
                        if (!root.trafficPaused) root.frozenTrafficSamples = NuService.trafficSamples.slice()
                        root.trafficPaused = !root.trafficPaused
                    }
                }
                NuActionButton {
                    text: "Export CSV"
                    Layout.preferredWidth: 132
                    helpText: "Export retained traffic samples."
                    onClicked: NuService.exportTrafficCsv()
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
                    Label {
                        Layout.preferredWidth: 142
                        text: "Log since launch"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBodyLarge
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: "Verbosity"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    Basic.Slider {
                        id: logVerbositySlider
                        Layout.preferredWidth: 116
                        from: 0
                        to: 3
                        stepSize: 1
                        snapMode: Basic.Slider.SnapAlways
                        value: NuService.logVerbosity
                        ToolTip.visible: hovered || pressed
                        ToolTip.text: root.logVerbosityName(value)
                        ToolTip.delay: NuTokens.tooltipDelay
                        onMoved: NuService.logVerbosity = Math.round(value)
                        Connections {
                            target: NuService
                            function onSettingsChanged() { logVerbositySlider.value = NuService.logVerbosity }
                        }
                    }
                    Label {
                        text: root.logVerbosityName(NuService.logVerbosity)
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    Label {
                        text: "Lines: " + root.shownLogLineCount
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.logFilterError
                        color: NuTokens.stateWarning
                        font.pixelSize: NuTokens.fontSmall
                        elide: Text.ElideRight
                    }
                    NuActionButton {
                        text: "Pop out"
                        Layout.preferredWidth: 104
                        helpText: "Open the launch log in a separate resizable window."
                        onClicked: {
                            logPopoutWindow.show()
                            logPopoutWindow.raise()
                        }
                    }
                    NuActionButton {
                        text: "Copy shown"
                        Layout.preferredWidth: 118
                        helpText: "Copy the currently visible filtered launch log lines."
                        onClicked: NuService.copyText(launchLogText.text)
                    }
                    NuActionButton {
                        text: "Save launch log"
                        Layout.preferredWidth: 144
                        helpText: "Save the currently visible filtered launch log as a text file with view and debug.log line numbers."
                        onClicked: NuService.saveLaunchLog(launchLogText.text)
                    }
                    NuActionButton {
                        text: "Open debug.log"
                        Layout.preferredWidth: 148
                        helpText: "Open the backend debug.log file in the operating system's default log viewer. Nu startup diagnostics are written there with delimiter lines and mirrored here."
                        onClicked: NuService.openDebugLog()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm

                        Label {
                            text: "Filter:"
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                        }
                        NuComboBox {
                            id: logSearchFilter
                            Layout.preferredWidth: 260
                            editable: true
                            model: root.logFilterPresetModel
                            currentIndex: 0
                            helpText: "Show only matching log lines. Choose a useful regex preset or type your own. Examples: Error, seednode|dns seed, version ."
                            Component.onCompleted: editText = NuService.logSearchPattern
                            onAccepted: root.setLogSearchPattern(editText)
                            onActivated: function(index) {
                                const value = root.logPresetValue(root.logFilterPresetModel[index])
                                editText = value
                                root.setLogSearchPattern(value)
                            }
                            onActiveFocusChanged: if (!activeFocus) root.setLogSearchPattern(editText)
                            Connections {
                                target: NuService
                                function onSettingsChanged() {
                                    logSearchFilter.editText = NuService.logSearchPattern
                                    root.refreshLogFilterPresets()
                                }
                            }
                        }
                        Label {
                            text: "Remove:"
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                        }
                        NuTextField {
                            id: logRemoveFilter
                            Layout.preferredWidth: 180
                            text: NuService.logRemovePattern
                            maximumLength: 160
                            placeholderText: "hide regex"
                            helpText: "Hide matching lines after Filter is applied. Examples: ping|pong, RPC credentials, ThreadRPCServer."
                            onEditingFinished: NuService.logRemovePattern = text
                        }
                        Label {
                            text: "Find:"
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                        }
                        NuTextField {
                            id: logFindField
                            Layout.fillWidth: true
                            Layout.minimumWidth: 170
                            maximumLength: 120
                            placeholderText: "Find in shown log"
                            helpText: "Find text within the currently shown log lines without changing the filter."
                            onAccepted: root.findInLog(false)
                        }
                        NuActionButton {
                            text: "Prev"
                            Layout.preferredWidth: 72
                            helpText: "Jump to the previous match in the shown log."
                            onClicked: root.findInLog(true)
                        }
                        NuActionButton {
                            text: "Next"
                            Layout.preferredWidth: 72
                            helpText: "Jump to the next match in the shown log."
                            onClicked: root.findInLog(false)
                        }
                    }
                }

                Basic.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: launchLogText
                        readOnly: true
                        selectByMouse: true
                        wrapMode: Text.NoWrap
                        color: NuTokens.textPrimary
                        selectionColor: NuTokens.lineStrong
                        selectedTextColor: NuTokens.textInverse
                        font.family: NuTokens.monoFont
                        font.pixelSize: NuTokens.fontLog
                        background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle }

                        function updateLogText() {
                            const oldCursor = cursorPosition
                            const oldSelectionStart = selectionStart
                            const oldSelectionEnd = selectionEnd
                            const hadSelection = oldSelectionStart !== oldSelectionEnd
                            text = root.filteredLogText()
                            cursorPosition = Math.min(oldCursor, length)
                            if (hadSelection) {
                                select(Math.min(oldSelectionStart, length), Math.min(oldSelectionEnd, length))
                            }
                        }

                        Component.onCompleted: updateLogText()
                        Connections {
                            target: NuService
                            function onLogChanged() { launchLogText.updateLogText() }
                            function onSettingsChanged() { launchLogText.updateLogText() }
                        }

                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: launchLogText.activeFocus && launchLogText.selectedText.length > 0
                            onActivated: NuService.copyText(launchLogText.selectedText)
                        }
                        Keys.onPressed: (event) => {
                            if ((event.matches(StandardKey.Copy) || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C)
                                    || ((event.modifiers & Qt.MetaModifier) && event.key === Qt.Key_C)) && selectedText.length > 0) {
                                NuService.copyText(selectedText)
                                event.accepted = true
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
                    text: "RPC Console"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "Advanced wallet and node commands run through the local Defcoin backend. Parameters must be a JSON array."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: warningText.implicitHeight + NuTokens.spaceMd
                    color: "#fff7d6"
                    border.color: NuTokens.stateWarning
                    radius: NuTokens.radiusMedium

                    Text {
                        id: warningText
                        anchors.fill: parent
                        anchors.margins: NuTokens.spaceSm
                        text: "Do not paste commands from strangers into Console."
                        color: "#4a3500"
                        font.pixelSize: NuTokens.fontBody
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: NuTokens.spaceMd
                    columnSpacing: NuTokens.spaceMd

                    Label { text: "Method"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    NuTextField {
                        id: rpcMethod
                        Layout.preferredWidth: 260
                        placeholderText: "getwalletinfo"
                        onAccepted: NuService.runRpcCommand(rpcMethod.text, rpcParams.text, walletScoped.checked)
                    }
                    NuCheckBox {
                        id: walletScoped
                        text: "Wallet RPC"
                        checked: true
                    }
                    NuActionButton {
                        text: "Run"
                        primary: true
                        Layout.preferredWidth: 112
                        helpText: "Execute the RPC command against the local Defcoin backend."
                        onClicked: NuService.runRpcCommand(rpcMethod.text, rpcParams.text, walletScoped.checked)
                    }

                    Label { text: "Params"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    NuTextField {
                        id: rpcParams
                        Layout.columnSpan: 3
                        Layout.fillWidth: true
                        placeholderText: "[]"
                        onAccepted: NuService.runRpcCommand(rpcMethod.text, rpcParams.text, walletScoped.checked)
                    }
                }

                Basic.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: consoleOutput
                        readOnly: true
                        selectByMouse: true
                        wrapMode: Text.WrapAnywhere
                        text: NuService.consoleOutput
                        color: NuTokens.textPrimary
                        selectionColor: NuTokens.lineStrong
                        selectedTextColor: NuTokens.textInverse
                        font.family: NuTokens.monoFont
                        font.pixelSize: NuTokens.fontLog
                        background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle }
                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: consoleOutput.activeFocus && consoleOutput.selectedText.length > 0
                            onActivated: NuService.copyText(consoleOutput.selectedText)
                        }
                        Keys.onPressed: (event) => {
                            if ((event.matches(StandardKey.Copy) || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C)
                                    || ((event.modifiers & Qt.MetaModifier) && event.key === Qt.Key_C)) && selectedText.length > 0) {
                                NuService.copyText(selectedText)
                                event.accepted = true
                            }
                        }
                    }
                }

                Connections {
                    target: NuService
                    function onConsoleChanged() {
                        consoleOutput.cursorPosition = consoleOutput.text.length
                    }
                }
            }
        }
    }

    Window {
        id: logPopoutWindow
        title: "Defcoin Core Nu - Log since launch"
        property int initialWidth: 1180
        property int initialHeight: 720
        minimumWidth: 760
        minimumHeight: 420
        visible: false
        color: NuTokens.backgroundBase
        Component.onCompleted: {
            width = initialWidth
            height = initialHeight
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: NuTokens.spaceLg
            spacing: NuTokens.spaceSm

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Log since launch"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }
                Label { text: "Font"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                Basic.Slider {
                    Layout.preferredWidth: 150
                    from: 9
                    to: 18
                    stepSize: 1
                    value: root.logPopoutFontSize
                    onMoved: root.logPopoutFontSize = Math.round(value)
                }
                Label {
                    text: root.logPopoutFontSize + " px"
                    color: NuTokens.textSecondary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                }
                Label {
                    text: "Lines: " + root.shownLogLineCount
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }
                NuActionButton {
                    text: "Copy shown"
                    Layout.preferredWidth: 118
                    onClicked: NuService.copyText(popoutLogText.text)
                }
                NuActionButton {
                    text: "Save launch log"
                    Layout.preferredWidth: 144
                    onClicked: NuService.saveLaunchLog(popoutLogText.text)
                }
                NuActionButton {
                    text: "Open debug.log"
                    Layout.preferredWidth: 148
                    onClicked: NuService.openDebugLog()
                }
            }

            TextArea {
                id: popoutLogText
                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                wrapMode: Text.NoWrap
                text: root.filteredLogText()
                color: NuTokens.textPrimary
                selectionColor: NuTokens.lineStrong
                selectedTextColor: NuTokens.textInverse
                font.family: NuTokens.monoFont
                font.pixelSize: root.logPopoutFontSize
                background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle }

                Shortcut {
                    sequences: [StandardKey.Copy]
                    enabled: popoutLogText.activeFocus && popoutLogText.selectedText.length > 0
                    onActivated: NuService.copyText(popoutLogText.selectedText)
                }
            }

            Connections {
                target: NuService
                function onLogChanged() { popoutLogText.text = root.filteredLogText() }
                function onSettingsChanged() { popoutLogText.text = root.filteredLogText() }
            }
        }
    }
}
