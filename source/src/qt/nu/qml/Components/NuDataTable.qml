pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"

Rectangle {
    id: root
    radius: NuTokens.radiusMedium
    color: NuTokens.panelBase
    border.color: NuTokens.lineSubtle
    activeFocusOnTab: true

    property string tableId: ""
    property string emptyText: "No rows."
    property var columns: []
    property var rows: []
    property var columnWeights: []
    property var columnTypes: []
    property var columnTooltips: []
    property var columnMinimums: []
    property var columnMaximums: []
    property var columnLinkMetaFields: []
    property var columnSortMetaFields: []
    property var sortColumnKeys: []
    property bool compact: false
    property bool forceMonospace: false
    property bool greenBarRows: false
    property int fontPixelSize: 0
    property bool sortable: true
    property bool restoreSavedColumnWidths: false
    property bool autoFitOnRowsChanged: false
    property bool autoFitOnFontChanged: false
    property bool alwaysShowHorizontalScrollBar: false
    property int rowRenderLimit: 0
    property int widthMeasurementRowLimit: 1500
    property int defaultSortColumn: -1
    property bool defaultSortAscending: true
    property int sortColumn: -1
    property bool sortAscending: true
    property var columnWidths: []
    property bool userResizingColumns: false
    property bool tableReady: false
    property bool hasEverBeenReady: false
    property bool hasDisplayedRows: false
    property bool manualColumnWidths: false
    property string lastLayoutSignature: ""
    property int lastRowCount: -1
    property bool selectingRange: false
    property bool selectionDragged: false
    property int selectionStartRow: 0
    property int selectionStartColumn: 0
    property int selectionEndRow: -1
    property int selectionEndColumn: -1
    property var selectedCellKeys: []
    property int cellSelectionAnchorRow: -2
    property int cellSelectionAnchorColumn: -1
    readonly property bool hasRangeSelection: selectionEndRow >= -1 && selectionEndColumn >= 0
    readonly property bool hasSelection: hasRangeSelection || selectedCellKeys.length > 0
    property bool rowSelectionEnabled: false
    property bool plainClickSelectsRows: false
    property string rowKeyMetaField: "address"
    property var selectedRowKeys: []
    property int rowSelectionAnchor: -1

    signal rowActivated(var row)
    signal rowDeleteRequested(var row)
    signal rowSelectionChanged(var keys)
    signal resetRequested()
    signal sortChanged(int column, bool ascending, string key)

    function columnWeight(index) {
        if (index >= 0 && index < columnWeights.length) return columnWeights[index]
        return 1
    }

    function columnType(index) {
        if (index >= 0 && index < columnTypes.length && columnTypes[index] !== "") return columnTypes[index]
        const name = (index >= 0 && index < columns.length ? String(columns[index]) : "").toLowerCase()
        if (name.indexOf("date") >= 0 || name.indexOf("time") >= 0) return "date"
        if (name.indexOf("amount") >= 0 || name.indexOf("balance") >= 0 || name.indexOf("sent") >= 0 || name.indexOf("rec") >= 0) return "bytes"
        if (name.indexOf("ping") >= 0) return "duration"
        if (name.indexOf("id") >= 0 || name.indexOf("peers") >= 0 || name.indexOf("block") >= 0) return "number"
        if (name.indexOf("address") >= 0 || name.indexOf("ip") >= 0 || name.indexOf("port") >= 0) return "ipport"
        return "text"
    }

    function columnToolTip(index) {
        if (index >= 0 && index < columnTooltips.length) return String(columnTooltips[index])
        return ""
    }

    function normalizedColumnKey(index) {
        if (index < 0 || index >= columns.length) return ""
        return String(columns[index]).toLowerCase().replace(/\n/g, " ").replace(/[^a-z0-9]+/g, "")
    }

    function sortKeyForColumn(index) {
        if (index >= 0 && index < sortColumnKeys.length && String(sortColumnKeys[index]).length > 0) {
            return String(sortColumnKeys[index])
        }
        return normalizedColumnKey(index)
    }

    function indexForSortKey(key) {
        const wanted = String(key || "")
        if (wanted.length === 0) return -1
        for (let i = 0; i < columns.length; ++i) {
            if (sortKeyForColumn(i) === wanted) return i
        }
        return -1
    }

    function applyExternalSort(key, ascending) {
        const index = indexForSortKey(key)
        if (index < 0) return false
        sortColumn = index
        sortAscending = ascending
        return true
    }

    function isActionColumn(index) {
        const type = columnType(index)
        return type === "action" || type === "delete"
    }

    function columnMin(index) {
        if (index >= 0 && index < columnMinimums.length) return Math.max(36, Number(columnMinimums[index]))
        const type = columnType(index)
        if (type === "action" || type === "delete") return 44
        if (type === "swatch") return 38
        if (type === "lan") return 34
        if (type === "ipport" || type === "address" || type === "hash") return 210
        if (type === "date") return 132
        if (type === "bytes" || type === "amount") return 96
        if (type === "duration") return 78
        if (type === "number") return 64
        return 90
    }

    function columnMax(index) {
        if (index >= 0 && index < columnMaximums.length && Number(columnMaximums[index]) > 0) return Number(columnMaximums[index])
        const type = columnType(index)
        if (type === "action" || type === "delete") return 44
        if (type === "swatch") return 52
        if (type === "lan") return 40
        if (type === "ipport") return 840
        if (type === "address" || type === "hash") return 960
        if (type === "text") return 1200
        return 720
    }

    function isMonoColumn(index) {
        if (forceMonospace) return true
        const type = columnType(index)
        const name = (index >= 0 && index < columns.length ? String(columns[index]) : "").toLowerCase()
        return type === "ipport" || type === "address" || type === "hash"
               || type === "number" || type === "bytes" || type === "duration" || type === "date"
               || name === "port" || name.indexOf("magic") >= 0 || name.indexOf("version") >= 0
               || name === "svcs" || name === "services" || name.indexOf("height") >= 0 || name.indexOf("headers") >= 0
               || name.indexOf("blocks") >= 0
    }

    function linkMetaField(index) {
        if (index >= 0 && index < columnLinkMetaFields.length) return String(columnLinkMetaFields[index])
        return ""
    }

    function cellLinkUrl(row, index) {
        if (columnType(index) !== "link") return ""
        const field = linkMetaField(index)
        if (field.length === 0) return ""
        const meta = rowMeta(row)
        const value = meta[field]
        return value === undefined || value === null ? "" : String(value)
    }

    function sortMetaField(index) {
        if (index >= 0 && index < columnSortMetaFields.length) return String(columnSortMetaFields[index])
        return ""
    }

    function sortValueAt(row, index) {
        const field = sortMetaField(index)
        if (field.length > 0) {
            const meta = rowMeta(row)
            const value = meta[field]
            if (value !== undefined && value !== null) return value
        }
        return valueAt(row, index)
    }

    function cellFontSize() {
        return fontPixelSize > 0 ? fontPixelSize : (compact ? NuTokens.fontSmall : NuTokens.fontBody)
    }

    function rightAlignColumn(index) {
        const type = columnType(index)
        const name = (index >= 0 && index < columns.length ? String(columns[index]) : "").toLowerCase()
        if (type === "center" || type === "swatch" || type === "lan") return false
        if (type === "rightText" || type === "reverseDns") return true
        if (type === "bytes" || type === "amount" || type === "duration" || type === "number") return true
        return name === "dir." || name === "dir" || name.indexOf("direction") >= 0
               || name === "port"
               || name.indexOf("magic") >= 0 || name.indexOf("protocol") >= 0
               || name === "version" || name === "svcs" || name === "services"
    }

    function centerAlignColumn(index) {
        const type = columnType(index)
        const name = (index >= 0 && index < columns.length ? String(columns[index]) : "").toLowerCase()
        return type === "center" || type === "swatch" || type === "lan" || name === "active"
    }

    function headerHorizontalAlignment(index) {
        const type = columnType(index)
        if (type === "knownDns" || type === "seedLanSource") return Text.AlignHCenter
        if (centerAlignColumn(index)) return Text.AlignHCenter
        if (rightAlignColumn(index)) return Text.AlignRight
        return Text.AlignLeft
    }

    function cellHorizontalAlignment(row, index) {
        const type = columnType(index)
        if (type === "seedLanSource") {
            const cells = rowCells(row)
            let lanIndex = -1
            for (let i = 0; i < columns.length; ++i) {
                if (columnType(i) === "lan" || String(columns[i] || "").trim() === "LAN") {
                    lanIndex = i
                    break
                }
            }
            const isLan = cells && lanIndex >= 0 && String(cells[lanIndex] || "").trim() === "LAN"
            return isLan ? Text.AlignLeft : Text.AlignRight
        }
        if (type === "knownDns") {
            return Text.AlignRight
        }
        if (centerAlignColumn(index)) return Text.AlignHCenter
        if (rightAlignColumn(index)) return Text.AlignRight
        return Text.AlignLeft
    }

    function rowCells(row) {
        if (row && row.cells !== undefined) return row.cells
        return row
    }

    function rowMeta(row) {
        if (row && row.meta !== undefined) return row.meta
        return ({})
    }

    function cellToolTip(row, index) {
        const meta = rowMeta(row)
        const tips = meta.cellTooltips
        if (tips !== undefined && tips !== null && index >= 0 && index < tips.length) return String(tips[index] || "")
        if (meta.rowTooltip !== undefined && meta.rowTooltip !== null) return String(meta.rowTooltip || "")
        return ""
    }

    function rowKey(row) {
        const meta = rowMeta(row)
        let value = meta[root.rowKeyMetaField]
        if ((value === undefined || value === null) && root.rowKeyMetaField.length > 0) {
            const wanted = root.rowKeyMetaField.toLowerCase().replace(/[^a-z0-9]/g, "")
            const cells = rowCells(row)
            for (let i = 0; cells && i < root.columns.length && i < cells.length; ++i) {
                const columnName = String(root.columns[i]).toLowerCase().replace(/[^a-z0-9]/g, "")
                if (columnName === wanted) {
                    value = cells[i]
                    break
                }
            }
        }
        return value === undefined || value === null ? "" : String(value)
    }

    function containsSelectedRowKey(key) {
        for (let i = 0; i < selectedRowKeys.length; ++i) {
            if (String(selectedRowKeys[i]) === key) return true
        }
        return false
    }

    function isRowSelected(row) {
        if (!rowSelectionEnabled) return false
        const key = rowKey(row)
        return key.length > 0 && containsSelectedRowKey(key)
    }

    function setSelectedKeys(keys) {
        selectedRowKeys = keys
        rowSelectionChanged(selectedRowKeys)
    }

    function clearRowSelection() {
        rowSelectionAnchor = -1
        setSelectedKeys([])
    }

    function pruneSelectedRowKeys() {
        if (!rowSelectionEnabled || selectedRowKeys.length === 0) return
        let valid = []
        const sorted = sortedRows()
        for (let i = 0; i < sorted.length; ++i) {
            const key = rowKey(sorted[i])
            if (key.length > 0 && valid.indexOf(key) < 0) valid.push(key)
        }
        let next = []
        for (let k = 0; k < selectedRowKeys.length; ++k) {
            const key = String(selectedRowKeys[k])
            if (valid.indexOf(key) >= 0) next.push(key)
        }
        if (next.length !== selectedRowKeys.length) setSelectedKeys(next)
    }

    function toggleRowSelected(rowIndex) {
        const sorted = sortedRows()
        if (rowIndex < 0 || rowIndex >= sorted.length) return
        const key = rowKey(sorted[rowIndex])
        if (key.length === 0) return
        let next = selectedRowKeys.slice()
        const existing = next.indexOf(key)
        if (existing >= 0) next.splice(existing, 1)
        else next.push(key)
        rowSelectionAnchor = rowIndex
        setSelectedKeys(next)
    }

    function selectRowRange(anchorIndex, rowIndex) {
        const sorted = sortedRows()
        if (sorted.length === 0) return
        const start = Math.max(0, Math.min(anchorIndex, rowIndex))
        const end = Math.min(sorted.length - 1, Math.max(anchorIndex, rowIndex))
        let next = selectedRowKeys.slice()
        for (let i = start; i <= end; ++i) {
            const key = rowKey(sorted[i])
            if (key.length > 0 && next.indexOf(key) < 0) next.push(key)
        }
        setSelectedKeys(next)
    }

    function handleRowSelectionClick(rowIndex, modifiers) {
        if (!rowSelectionEnabled) return false
        root.forceActiveFocus()
        if ((modifiers & Qt.ShiftModifier) !== 0) {
            clearCellSelection()
            if (rowSelectionAnchor < 0) rowSelectionAnchor = rowIndex
            selectRowRange(rowSelectionAnchor, rowIndex)
            return true
        }
        if ((modifiers & Qt.ControlModifier) !== 0 || (modifiers & Qt.MetaModifier) !== 0) {
            clearCellSelection()
            toggleRowSelected(rowIndex)
            return true
        }
        if (plainClickSelectsRows) {
            const sorted = sortedRows()
            if (rowIndex < 0 || rowIndex >= sorted.length) return false
            const key = rowKey(sorted[rowIndex])
            if (key.length === 0) return false
            clearCellSelection()
            rowSelectionAnchor = rowIndex
            setSelectedKeys([key])
            return true
        }
        return false
    }

    function cellKey(row, column) {
        return row + ":" + column
    }

    function containsSelectedCell(row, column) {
        return selectedCellKeys.indexOf(cellKey(row, column)) >= 0
    }

    function setSingleCellSelection(row, column) {
        if (isActionColumn(column)) return
        selectingRange = false
        selectionEndRow = -1
        selectionEndColumn = -1
        selectedCellKeys = [cellKey(row, column)]
        cellSelectionAnchorRow = row
        cellSelectionAnchorColumn = column
    }

    function toggleCellSelection(row, column) {
        if (isActionColumn(column)) return
        selectingRange = false
        selectionEndRow = -1
        selectionEndColumn = -1
        let next = selectedCellKeys.slice()
        const key = cellKey(row, column)
        const existing = next.indexOf(key)
        if (existing >= 0) next.splice(existing, 1)
        else next.push(key)
        selectedCellKeys = next
        cellSelectionAnchorRow = row
        cellSelectionAnchorColumn = column
    }

    function selectCellRange(anchorRow, anchorColumn, row, column) {
        if (isActionColumn(column)) return
        selectedCellKeys = []
        selectingRange = false
        selectionStartRow = anchorRow
        selectionStartColumn = anchorColumn
        selectionEndRow = row
        selectionEndColumn = column
    }

    function handleCellSelectionClick(row, column, modifiers) {
        root.forceActiveFocus()
        if ((modifiers & Qt.ShiftModifier) !== 0) {
            if (cellSelectionAnchorRow < -1 || cellSelectionAnchorColumn < 0) {
                cellSelectionAnchorRow = row
                cellSelectionAnchorColumn = column
            }
            selectCellRange(cellSelectionAnchorRow, cellSelectionAnchorColumn, row, column)
            return true
        }
        if ((modifiers & Qt.ControlModifier) !== 0 || (modifiers & Qt.MetaModifier) !== 0) {
            toggleCellSelection(row, column)
            return true
        }
        return false
    }

    function textPadding() {
        return compact ? 8 : 14
    }

    function rowHeight() {
        return Math.max(compact ? 24 : 30, Math.ceil(cellFontSize() * 1.75) + (compact ? 4 : 8))
    }

    function headerNeedsExtraLine(index) {
        if (index < 0 || index >= columns.length || index >= columnWidths.length) return false
        const title = String(columns[index])
        if (title.indexOf(" ") < 0 && title.indexOf("\n") < 0) return false
        return roughTextWidth(title.replace(/\n/g, " "), index) > Number(columnWidths[index]) - 6
    }

    function headerHeight() {
        const base = Math.max(compact ? 32 : 38, Math.ceil(cellFontSize() * 1.8) + (compact ? 6 : 8))
        for (let i = 0; i < columns.length; ++i) {
            if (headerNeedsExtraLine(i)) return base + Math.ceil(cellFontSize() * 1.35)
        }
        return base
    }

    function roughTextWidth(text, index) {
        const size = cellFontSize()
        const s = String(text === undefined || text === null ? "" : text)
        let width = textPadding() + 14
        for (let i = 0; i < s.length; ++i) {
            const ch = s.charAt(i)
            if (ch === " " || ch === "." || ch === ":" || ch === "/" || ch === "-" || ch === "["
                || ch === "]" || ch === "(" || ch === ")") width += size * 0.34
            else if ("ilI1|".indexOf(ch) >= 0) width += size * 0.32
            else if ("MW@#%".indexOf(ch) >= 0) width += size * 0.82
            else width += isMonoColumn(index) ? size * 0.62 : size * 0.54
        }
        return width
    }

    function defaultWidths() {
        const totalWeight = Math.max(1, columnWeights.reduce(function(a, b) { return a + Number(b) }, 0))
        const available = Math.max(480, root.width - (compact ? NuTokens.spaceSm * 2 : NuTokens.spaceLg * 2))
        let out = []
        for (let i = 0; i < columns.length; ++i) {
            let width = Math.max(columnMin(i), available * columnWeight(i) / totalWeight)
            width = Math.min(columnMax(i), width)
            out.push(width)
        }
        return out
    }

    function autoWidths() {
        const availableForMetrics = Math.max(360, root.width - (compact ? NuTokens.spaceSm * 2 : NuTokens.spaceLg * 2))
        const measuredRows = root.measurementRows()
        const suggested = NuService.suggestedTableColumnWidths(root.columns,
                                                              measuredRows,
                                                              root.columnTypes,
                                                              root.columnWeights,
                                                              root.columnMinimums,
                                                              root.columnMaximums,
                                                              availableForMetrics,
                                                              root.cellFontSize(),
                                                              root.compact)
        if (suggested && suggested.length === columns.length) return suggested

        let out = defaultWidths()
        for (let c = 0; c < columns.length; ++c) {
            let wanted = roughTextWidth(columns[c], c) + 14
            for (let r = 0; r < measuredRows.length; ++r) {
                const row = rowCells(measuredRows[r])
                if (row && row.length > c) wanted = Math.max(wanted, roughTextWidth(row[c], c))
            }
            const hardMax = isActionColumn(c) ? columnMax(c) : Math.max(columnMax(c), wanted)
            out[c] = Math.max(columnMin(c), Math.min(hardMax, Math.ceil(wanted)))
        }
        return out
    }

    function layoutSignature() {
        let parts = [columns.join("|"), columnTypes.join("|"), Math.floor(root.width / 12), root.compact ? "compact" : "regular"]
        parts.push(rows ? rows.length : 0)
        const measuredRows = root.measurementRows()
        for (let c = 0; c < columns.length; ++c) {
            let longest = String(columns[c]).length
            if (measuredRows) {
                for (let r = 0; r < measuredRows.length; ++r) {
                    const row = rowCells(measuredRows[r])
                    if (row && row.length > c) longest = Math.max(longest, String(row[c]).length)
                }
            }
            parts.push(longest)
        }
        return parts.join(":")
    }

    function columnsWidth() {
        let sum = 0
        for (let i = 0; i < columnWidths.length; ++i) sum += Number(columnWidths[i])
        return sum
    }

    function columnAtX(x) {
        let offset = 0
        for (let i = 0; i < columnWidths.length; ++i) {
            const width = Number(columnWidths[i])
            if (x >= offset && x <= offset + width) return i
            offset += width
        }
        return Math.max(0, columnWidths.length - 1)
    }

    function rowAtY(y) {
        const headerHeight = root.headerHeight()
        const rowHeight = root.rowHeight()
        if (y < headerHeight) return -1
        const row = Math.floor((y - headerHeight) / rowHeight)
        return Math.max(0, Math.min(root.renderedRowCount() - 1, row))
    }

    function totalWidth() {
        const margins = compact ? NuTokens.spaceSm * 2 : NuTokens.spaceLg * 2
        return Math.max(columnsWidth(), Math.max(320, root.width - margins))
    }

    function valueAt(row, index) {
        const cells = rowCells(row)
        if (!cells || cells.length <= index) return ""
        return cells[index]
    }

    function numericValue(value) {
        const text = String(value === undefined || value === null ? "" : value).replace(/,/g, "")
        const match = text.match(/-?\d+(\.\d+)?/)
        return match ? Number(match[0]) : 0
    }

    function bytesValue(value) {
        const text = String(value === undefined || value === null ? "" : value).replace(/,/g, "").toUpperCase()
        const match = text.match(/-?\d+(\.\d+)?/)
        if (!match) return 0
        let amount = Number(match[0])
        if (text.indexOf("GB") >= 0) amount *= 1024 * 1024 * 1024
        else if (text.indexOf("MB") >= 0) amount *= 1024 * 1024
        else if (text.indexOf("KB") >= 0) amount *= 1024
        return amount
    }

    function isMissingSortValue(value) {
        const text = String(value === undefined || value === null ? "" : value).trim().toLowerCase()
        return text.length === 0 || text === "-" || text === "unknown" || text === "n/a"
    }

    function dateValue(value) {
        const text = String(value === undefined || value === null ? "" : value).trim().replace(/\s+/g, " ")
        if (isMissingSortValue(text)) return null

        const isoLocal = text.match(/^(\d{4})-(\d{1,2})-(\d{1,2})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s+[A-Za-z]{1,5})?$/)
        if (isoLocal) {
            return new Date(Number(isoLocal[1]), Number(isoLocal[2]) - 1, Number(isoLocal[3]),
                            Number(isoLocal[4]), Number(isoLocal[5]),
                            isoLocal[6] ? Number(isoLocal[6]) : 0).getTime()
        }

        const usLocal = text.match(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s+[A-Za-z]{1,5})?$/)
        if (usLocal) {
            let year = Number(usLocal[3])
            if (year < 100) year += 2000
            return new Date(year, Number(usLocal[1]) - 1, Number(usLocal[2]),
                            Number(usLocal[4]), Number(usLocal[5]),
                            usLocal[6] ? Number(usLocal[6]) : 0).getTime()
        }

        const parsed = Date.parse(text)
        return isNaN(parsed) ? null : parsed
    }

    function ipSortKey(value) {
        const raw = String(value === undefined || value === null ? "" : value).trim()
        let ip = raw
        let port = 0
        const bracket = raw.match(/^\[([^\]]+)\]:(\d+)$/)
        if (bracket) {
            ip = bracket[1]
            port = Number(bracket[2])
        } else {
            const ipv4 = raw.match(/^(\d{1,3}(?:\.\d{1,3}){3})(?::(\d+))?$/)
            if (ipv4) {
                ip = ipv4[1]
                port = ipv4[2] ? Number(ipv4[2]) : 0
            }
        }
        if (ip.indexOf(":") >= 0) {
            const groups = ip.split(":")
            const maybePort = groups[groups.length - 1]
            if (groups.length > 2 && maybePort.match(/^\d+$/)) {
                const beforePort = groups.slice(0, groups.length - 1).join(":")
                const hasCompressed = beforePort.indexOf("::") >= 0
                const explicitGroups = beforePort.split(":").filter(function(part) { return part.length > 0 }).length
                if (hasCompressed || explicitGroups <= 7) {
                    ip = beforePort
                    port = Number(maybePort)
                }
            }
        }
        const v4parts = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
        if (v4parts) {
            let key = "4"
            for (let i = 1; i <= 4; ++i) key += "." + ("000" + Number(v4parts[i])).slice(-3)
            return key + ":" + ("00000" + port).slice(-5)
        }
        let leftRight = ip.toLowerCase().split("::")
        let groups = []
        if (leftRight.length === 2) {
            let left = leftRight[0].length ? leftRight[0].split(":") : []
            let right = leftRight[1].length ? leftRight[1].split(":") : []
            let missing = Math.max(0, 8 - left.length - right.length)
            groups = left.concat(Array(missing).fill("0")).concat(right)
        } else {
            groups = ip.toLowerCase().split(":")
        }
        while (groups.length < 8) groups.push("0")
        return "6." + groups.slice(0, 8).map(function(group) {
            const n = parseInt(group.length ? group : "0", 16)
            return ("00000" + (isNaN(n) ? 0 : n)).slice(-5)
        }).join(".") + ":" + ("00000" + port).slice(-5)
    }

    function compareRows(a, b) {
        const type = columnType(sortColumn)
        const av = sortValueAt(a, sortColumn)
        const bv = sortValueAt(b, sortColumn)
        let diff = 0
        const aMissing = isMissingSortValue(av)
        const bMissing = isMissingSortValue(bv)
        if (aMissing || bMissing) {
            if (aMissing && bMissing) return 0
            return aMissing ? 1 : -1
        }
        if (type === "number" || type === "duration") diff = numericValue(av) - numericValue(bv)
        else if (type === "bytes" || type === "amount") diff = bytesValue(av) - bytesValue(bv)
        else if (type === "date") {
            const ad = dateValue(av)
            const bd = dateValue(bv)
            if (ad === null || bd === null) {
                if (ad === null && bd === null) return 0
                return ad === null ? 1 : -1
            }
            diff = ad - bd
        }
        else if (type === "ipport" || type === "address") diff = ipSortKey(av).localeCompare(ipSortKey(bv))
        else diff = String(av).localeCompare(String(bv), undefined, { numeric: true, sensitivity: "base" })
        if (isNaN(diff)) diff = String(av).localeCompare(String(bv), undefined, { numeric: true, sensitivity: "base" })
        return sortAscending ? diff : -diff
    }

    function sortedRows() {
        let out = rows ? rows.slice() : []
        if (sortable && sortColumn >= 0 && sortColumn < columns.length) {
            let indexed = []
            for (let i = 0; i < out.length; ++i) indexed.push({ row: out[i], index: i })
            indexed.sort(function(a, b) {
                const diff = compareRows(a.row, b.row)
                return diff !== 0 ? diff : a.index - b.index
            })
            out = indexed.map(function(item) { return item.row })
        }
        if (rowRenderLimit > 0 && out.length > rowRenderLimit) out = out.slice(0, rowRenderLimit)
        return out
    }

    function renderedRowCount() {
        const count = rows ? rows.length : 0
        return rowRenderLimit > 0 ? Math.min(count, rowRenderLimit) : count
    }

    function measurementRows() {
        if (!rows) return []
        const limit = Math.max(1, widthMeasurementRowLimit)
        if (rows.length <= limit) return rows
        let out = rows.slice(0, limit)
        const tailCount = Math.min(200, rows.length - limit)
        if (tailCount > 0) out = out.concat(rows.slice(rows.length - tailCount))
        return out
    }

    function beginRangeSelection(row, column, localPoint) {
        if (isActionColumn(column)) return
        root.forceActiveFocus()
        if (rowSelectionEnabled && selectedRowKeys.length > 0) clearRowSelection()
        selectedCellKeys = []
        cellSelectionAnchorRow = row
        cellSelectionAnchorColumn = column
        selectingRange = true
        selectionDragged = false
        selectionStartRow = row
        selectionStartColumn = column
        updateRangeSelection(localPoint)
    }

    function updateRangeSelection(localPoint) {
        if (!selectingRange) return
        const row = rowAtY(localPoint.y)
        const column = columnAtX(localPoint.x)
        if (isActionColumn(column)) return
        selectionEndRow = row
        selectionEndColumn = column
        if (row !== selectionStartRow || column !== selectionStartColumn) selectionDragged = true
    }

    function finishRangeSelection() {
        selectingRange = false
    }

    function clearCellSelection() {
        selectingRange = false
        selectionEndRow = -1
        selectionEndColumn = -1
        selectedCellKeys = []
    }

    function isCellSelected(row, column) {
        if (!hasSelection || isActionColumn(column)) return false
        if (containsSelectedCell(row, column)) return true
        if (!hasRangeSelection) return false
        const minRow = Math.min(selectionStartRow, selectionEndRow)
        const maxRow = Math.max(selectionStartRow, selectionEndRow)
        const minColumn = Math.min(selectionStartColumn, selectionEndColumn)
        const maxColumn = Math.max(selectionStartColumn, selectionEndColumn)
        return row >= minRow && row <= maxRow && column >= minColumn && column <= maxColumn
    }

    function copyDelimiter() {
        const style = String(NuService.tableCopyDelimiterStyle || "tsv").toLowerCase()
        if (style === "csv") return ","
        if (style === "pipe") return "|"
        if (style === "semicolon") return ";"
        if (style === "custom") return String(NuService.tableCopyCustomDelimiter || "|")
        return "\t"
    }

    function copyValueText(value) {
        const text = String(value === undefined || value === null ? "" : value).replace(/\s+/g, " ").trim()
        const style = String(NuService.tableCopyDelimiterStyle || "tsv").toLowerCase()
        if (style === "csv") {
            if (text.indexOf(",") >= 0 || text.indexOf("\"") >= 0 || text.indexOf("\n") >= 0) {
                return "\"" + text.replace(/"/g, "\"\"") + "\""
            }
        }
        return text
    }

    function joinCopyValues(values) {
        return values.map(function(value) { return copyValueText(value) }).join(copyDelimiter())
    }

    function selectedCellsText() {
        if (selectedCellKeys.length === 0) return ""
        const sorted = sortedRows()
        let rowSet = []
        let columnSet = []
        for (let i = 0; i < selectedCellKeys.length; ++i) {
            const parts = String(selectedCellKeys[i]).split(":")
            if (parts.length !== 2) continue
            const row = Number(parts[0])
            const column = Number(parts[1])
            if (isActionColumn(column)) continue
            if (rowSet.indexOf(row) < 0) rowSet.push(row)
            if (columnSet.indexOf(column) < 0) columnSet.push(column)
        }
        rowSet.sort(function(a, b) { return a - b })
        columnSet.sort(function(a, b) { return a - b })
        let lines = []
        for (let rIndex = 0; rIndex < rowSet.length; ++rIndex) {
            const r = rowSet[rIndex]
            let values = []
            for (let cIndex = 0; cIndex < columnSet.length; ++cIndex) {
                const c = columnSet[cIndex]
                if (!containsSelectedCell(r, c)) {
                    values.push("")
                } else if (r < 0) {
                    values.push(columns[c] === undefined ? "" : columns[c])
                } else if (r < sorted.length) {
                    values.push(valueAt(sorted[r], c))
                } else {
                    values.push("")
                }
            }
            lines.push(joinCopyValues(values))
        }
        return lines.join("\n")
    }

    function selectionText() {
        if (!hasSelection) return ""
        if (!hasRangeSelection) return selectedCellsText()
        const minRow = Math.min(selectionStartRow, selectionEndRow)
        const maxRow = Math.max(selectionStartRow, selectionEndRow)
        const minColumn = Math.min(selectionStartColumn, selectionEndColumn)
        const maxColumn = Math.max(selectionStartColumn, selectionEndColumn)
        const sorted = sortedRows()
        let lines = []
        let selectedColumns = []
        for (let c = minColumn; c <= maxColumn; ++c) {
            if (!isActionColumn(c)) selectedColumns.push(c)
        }
        if (selectedColumns.length === 0) return ""
        if (minRow <= -1) {
            lines.push(joinCopyValues(selectedColumns.map(function(c) { return columns[c] === undefined ? "" : columns[c] })))
        }
        for (let r = Math.max(0, minRow); r <= Math.min(maxRow, sorted.length - 1); ++r) {
            lines.push(joinCopyValues(selectedColumns.map(function(c) { return valueAt(sorted[r], c) })))
        }
        return lines.join("\n")
    }

    function selectedRowsText() {
        if (!rowSelectionEnabled || selectedRowKeys.length === 0) return ""
        const sorted = sortedRows()
        let selectedColumns = []
        for (let c = 0; c < columns.length; ++c) {
            if (!isActionColumn(c)) selectedColumns.push(c)
        }
        if (selectedColumns.length === 0) return ""
        let lines = []
        for (let r = 0; r < sorted.length; ++r) {
            const key = rowKey(sorted[r])
            if (key.length === 0 || !containsSelectedRowKey(key)) continue
            lines.push(joinCopyValues(selectedColumns.map(function(c) { return valueAt(sorted[r], c) })))
        }
        return lines.join("\n")
    }

    function copySelection() {
        const text = hasSelection ? selectionText() : selectedRowsText()
        if (text.length > 0) NuService.copyText(text)
    }

    function openCopyMenu(item, x, y, row, column) {
        if (!hasSelection && column >= 0 && !isActionColumn(column)) {
            setSingleCellSelection(row, column)
        }
        const point = item.mapToItem(root, x, y)
        tableContextMenu.x = Math.max(0, Math.min(point.x, root.width - tableContextMenu.implicitWidth))
        tableContextMenu.y = Math.max(0, Math.min(point.y, root.height - tableContextMenu.implicitHeight))
        tableContextMenu.open()
    }

    function toggleSort(index) {
        if (!sortable) return
        if (isActionColumn(index)) return
        if (sortColumn === index) sortAscending = !sortAscending
        else {
            sortColumn = index
            sortAscending = true
        }
        sortChanged(sortColumn, sortAscending, sortKeyForColumn(sortColumn))
    }

    function setAutoWidths(save) {
        if (columns.length === 0) return
        manualColumnWidths = false
        columnWidths = autoWidths()
        if (save && tableId.length > 0) NuService.saveTableColumnWidths(tableId, columnWidths)
    }

    function loadWidths(forceAuto) {
        if (columns.length === 0) return
        if (manualColumnWidths && !forceAuto) return
        if (columnWidths.length !== columns.length) forceAuto = true
        const signature = layoutSignature()
        const rowCount = rows ? rows.length : 0
        const rowCountChanged = lastRowCount >= 0 && rowCount !== lastRowCount
        if (!forceAuto && hasEverBeenReady && signature === lastLayoutSignature && !rowCountChanged) return
        const defaults = autoWidths()
        const useSavedWidths = root.restoreSavedColumnWidths && !forceAuto && !rowCountChanged && !hasEverBeenReady && tableId.length > 0
        columnWidths = useSavedWidths ? NuService.tableColumnWidths(tableId, defaults) : defaults
        lastLayoutSignature = signature
        lastRowCount = rowCount
        tableReady = true
        hasEverBeenReady = true
        if (rows && rows.length > 0) hasDisplayedRows = true
    }

    function resetColumnWidths() {
        manualColumnWidths = false
        if (tableId.length > 0) NuService.resetTableColumnWidths(tableId)
        setAutoWidths(true)
    }

    function forceResetColumnWidths() {
        manualColumnWidths = false
        setAutoWidths(false)
        lastLayoutSignature = layoutSignature()
        lastRowCount = rows ? rows.length : 0
        tableReady = true
        hasEverBeenReady = true
        if (rows && rows.length > 0) hasDisplayedRows = true
    }

    function scheduleResize(forceAuto) {
        if (!hasEverBeenReady) tableReady = false
        loadWidths(forceAuto === true)
    }

    Component.onCompleted: {
        if (sortColumn < 0 && defaultSortColumn >= 0 && defaultSortColumn < columns.length) {
            sortColumn = defaultSortColumn
            sortAscending = defaultSortAscending
        }
        scheduleResize(false)
    }
    onColumnsChanged: {
        if (!userResizingColumns) scheduleResize(true)
    }
    onRowsChanged: {
        pruneSelectedRowKeys()
        if (!userResizingColumns) scheduleResize(root.autoFitOnRowsChanged)
    }
    onWidthChanged: {
        if (!userResizingColumns) scheduleResize(false)
    }
    onFontPixelSizeChanged: {
        if (!userResizingColumns && autoFitOnFontChanged) scheduleResize(true)
    }
    onTableIdChanged: {
        if (!userResizingColumns) scheduleResize(true)
    }

    Connections {
        target: NuService
        function onTableSettingsChanged() {
            if (!root.userResizingColumns) root.forceResetColumnWidths()
        }
    }

    Shortcut {
        sequences: [StandardKey.Copy]
        enabled: root.hasSelection || root.selectedRowKeys.length > 0
        onActivated: root.copySelection()
    }

    Menu {
        id: tableContextMenu
        NuMenuItem {
            text: "Copy"
            enabled: root.hasSelection || root.selectedRowKeys.length > 0
            onTriggered: root.copySelection()
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.compact ? NuTokens.spaceSm : NuTokens.spaceLg

        Basic.ScrollView {
            id: scroll
            anchors.fill: parent
            clip: true
            opacity: (root.tableReady || root.hasEverBeenReady) ? 1 : 0
            contentWidth: root.totalWidth()
            contentHeight: tableViewport.implicitHeight
            Basic.ScrollBar.horizontal.policy: root.alwaysShowHorizontalScrollBar ? Basic.ScrollBar.AlwaysOn : Basic.ScrollBar.AsNeeded
            Basic.ScrollBar.vertical.policy: Basic.ScrollBar.AsNeeded

            Column {
                id: tableViewport
                width: scroll.contentWidth

                Row {
                    id: headerRow
                    width: scroll.contentWidth
                    height: root.headerHeight()
                    visible: root.columns.length > 0

                    Repeater {
                        model: root.columns

                        Rectangle {
                            id: headerCell
                            required property int index
                            required property string modelData
                            width: root.columnWidths.length > index ? root.columnWidths[index] : root.columnWeight(index) * 100
                            height: headerRow.height
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            activeFocusOnTab: root.sortable && !root.isActionColumn(headerCell.index)
                            Accessible.name: headerCell.modelData
                            Accessible.description: root.columnToolTip(headerCell.index)
                            ToolTip.visible: headerHover.containsMouse && root.columnToolTip(headerCell.index).length > 0
                            ToolTip.text: root.columnToolTip(headerCell.index)
                            ToolTip.delay: NuTokens.tooltipDelay
                            ToolTip.timeout: NuTokens.tooltipTimeout

                            Keys.onReturnPressed: root.toggleSort(headerCell.index)
                            Keys.onEnterPressed: root.toggleSort(headerCell.index)
                            Keys.onSpacePressed: root.toggleSort(headerCell.index)

                            Text {
                                anchors.fill: parent
                                anchors.margins: root.compact ? NuTokens.spaceXs : NuTokens.spaceSm
                                text: headerCell.modelData
                                color: NuTokens.textPrimary
                                font.family: root.forceMonospace ? NuTokens.monoFont : NuTokens.bodyFont
                                font.pixelSize: root.cellFontSize()
                                font.weight: Font.DemiBold
                                horizontalAlignment: root.headerHorizontalAlignment(headerCell.index)
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                clip: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: root.isCellSelected(-1, headerCell.index)
                                color: NuTokens.accentSky
                                opacity: 0.16
                            }

                            Canvas {
                                id: sortIndicator
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 2
                                anchors.rightMargin: 2
                                height: 4
                                visible: root.sortColumn === headerCell.index
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    const gradient = ctx.createLinearGradient(0, 0, width, 0)
                                    if (root.sortAscending) {
                                        gradient.addColorStop(0.0, NuTokens.lineStrong)
                                        gradient.addColorStop(0.5, NuTokens.lineSubtle)
                                        gradient.addColorStop(1.0, NuTokens.lineStrong)
                                    } else {
                                        gradient.addColorStop(0.0, NuTokens.lineSubtle)
                                        gradient.addColorStop(0.5, NuTokens.lineStrong)
                                        gradient.addColorStop(1.0, NuTokens.lineSubtle)
                                    }
                                    ctx.fillStyle = gradient
                                    ctx.fillRect(0, 0, width, height)
                                }
                                Connections {
                                    target: root
                                    function onSortColumnChanged() { sortIndicator.requestPaint() }
                                    function onSortAscendingChanged() { sortIndicator.requestPaint() }
                                }
                            }

                            MouseArea {
                                id: headerHover
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                hoverEnabled: true
                                enabled: !root.isActionColumn(headerCell.index)
                                property point startPoint: Qt.point(0, 0)
                                onPressed: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        root.openCopyMenu(headerCell, mouse.x, mouse.y, -1, headerCell.index)
                                        mouse.accepted = true
                                        return
                                    }
                                    if (root.handleCellSelectionClick(-1, headerCell.index, mouse.modifiers)) {
                                        mouse.accepted = true
                                        return
                                    }
                                    startPoint = headerCell.mapToItem(tableViewport, mouse.x, mouse.y)
                                    root.beginRangeSelection(-1, headerCell.index, startPoint)
                                }
                                onPositionChanged: (mouse) => {
                                    const point = headerCell.mapToItem(tableViewport, mouse.x, mouse.y)
                                    if (Math.abs(point.x - startPoint.x) > 3 || Math.abs(point.y - startPoint.y) > 3) root.selectionDragged = true
                                    root.updateRangeSelection(point)
                                }
                                onReleased: (mouse) => {
                                    if (mouse.button === Qt.RightButton) return
                                    root.finishRangeSelection()
                                    if (!root.selectionDragged) root.toggleSort(headerCell.index)
                                }
                            }

                            MouseArea {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                cursorShape: Qt.SizeHorCursor
                                acceptedButtons: Qt.LeftButton
                                property real startWidth: 0
                                property real pressX: 0
                                onDoubleClicked: {
                                    root.setAutoWidths(root.restoreSavedColumnWidths)
                                }
                                onPressed: (mouse) => {
                                    root.userResizingColumns = true
                                    root.manualColumnWidths = true
                                    startWidth = headerCell.width
                                    pressX = mouse.x
                                }
                                onPositionChanged: (mouse) => {
                                    if (!pressed) return
                                    let widths = root.columnWidths.slice()
                                    const measuredMax = root.autoWidths()
                                    const hardMax = root.isActionColumn(headerCell.index)
                                                    ? root.columnMax(headerCell.index)
                                                    : Math.max(root.columnMax(headerCell.index), measuredMax.length > headerCell.index ? measuredMax[headerCell.index] : 0)
                                    widths[headerCell.index] = Math.max(root.columnMin(headerCell.index), Math.min(hardMax, startWidth + mouse.x - pressX))
                                    root.columnWidths = widths
                                }
                                onReleased: {
                                    root.userResizingColumns = false
                                    if (root.tableId.length > 0) NuService.saveTableColumnWidths(root.tableId, root.columnWidths)
                                }
                                onCanceled: root.userResizingColumns = false
                            }

                            MouseArea {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: headerCell.index === 0 ? 10 : 0
                                cursorShape: Qt.SizeHorCursor
                                acceptedButtons: Qt.LeftButton
                                onDoubleClicked: root.setAutoWidths(true)
                            }
                        }
                    }
                }

                Repeater {
                    model: root.sortedRows()

                    Row {
                        id: bodyRow
                        required property int index
                        required property var modelData
                        width: scroll.contentWidth
                        height: root.rowHeight()

                        Repeater {
                            model: root.columns.length

                            Rectangle {
                                id: bodyCell
                                required property int index
                                width: root.columnWidths.length > index ? root.columnWidths[index] : root.columnWeight(index) * 100
                                height: bodyRow.height
                                color: root.greenBarRows
                                       ? (bodyRow.index % 2 === 0 ? Qt.rgba(0.88, 0.96, 0.88, 0.22) : Qt.rgba(0.96, 1.0, 0.96, 0.10))
                                       : "transparent"
                                border.color: NuTokens.lineSubtle

                                Rectangle {
                                    anchors.fill: parent
                                    visible: root.isRowSelected(bodyRow.modelData)
                                    color: NuTokens.accentSky
                                    opacity: 0.10
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: root.isCellSelected(bodyRow.index, bodyCell.index)
                                    color: NuTokens.accentSky
                                    opacity: 0.16
                                }

                                Item {
                                    id: actionCell
                                    anchors.fill: parent
                                    visible: root.isActionColumn(bodyCell.index)
                                    activeFocusOnTab: visible
                                    focus: false
                                    property bool deleteAction: root.columnType(bodyCell.index) === "delete"

                                    function activateAction() {
                                        if (deleteAction) root.rowDeleteRequested(bodyRow.modelData)
                                        else root.rowActivated(bodyRow.modelData)
                                    }

                                    Accessible.role: Accessible.Button
                                    Accessible.name: deleteAction ? "Delete request" : "Open details"
                                    Accessible.description: deleteAction ? "Delete this generated request." : "Open details for this row."

                                    Keys.onReturnPressed: activateAction()
                                    Keys.onEnterPressed: activateAction()
                                    Keys.onSpacePressed: activateAction()
                                    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
                                    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: parent.activeFocus ? NuTokens.inverseBase : "transparent"
                                        border.color: NuTokens.lineStrong
                                        border.width: parent.activeFocus ? 2 : 1

                                        Canvas {
                                            id: actionGlyph
                                            anchors.fill: parent
                                            onPaint: {
                                                const ctx = getContext("2d")
                                                ctx.reset()
                                                ctx.lineWidth = 1.6
                                                ctx.strokeStyle = actionCell.activeFocus ? NuTokens.textInverse : NuTokens.textPrimary
                                                ctx.fillStyle = actionCell.activeFocus ? NuTokens.textInverse : NuTokens.textPrimary
                                                if (actionCell.deleteAction) {
                                                    ctx.beginPath()
                                                    ctx.moveTo(width * 0.32, height * 0.35)
                                                    ctx.lineTo(width * 0.68, height * 0.35)
                                                    ctx.moveTo(width * 0.40, height * 0.29)
                                                    ctx.lineTo(width * 0.60, height * 0.29)
                                                    ctx.moveTo(width * 0.43, height * 0.28)
                                                    ctx.lineTo(width * 0.46, height * 0.24)
                                                    ctx.lineTo(width * 0.54, height * 0.24)
                                                    ctx.lineTo(width * 0.57, height * 0.28)
                                                    ctx.stroke()
                                                    ctx.strokeRect(width * 0.36, height * 0.39, width * 0.28, height * 0.35)
                                                    ctx.beginPath()
                                                    ctx.moveTo(width * 0.45, height * 0.45)
                                                    ctx.lineTo(width * 0.45, height * 0.68)
                                                    ctx.moveTo(width * 0.55, height * 0.45)
                                                    ctx.lineTo(width * 0.55, height * 0.68)
                                                    ctx.stroke()
                                                } else {
                                                    ctx.beginPath()
                                                    ctx.arc(width / 2, height * 0.29, 1.8, 0, Math.PI * 2)
                                                    ctx.fill()
                                                    ctx.fillRect(width / 2 - 1.0, height * 0.42, 2.0, height * 0.28)
                                                    ctx.fillRect(width / 2 - 2.6, height * 0.68, 5.2, 2.0)
                                                }
                                            }
                                            Connections {
                                                target: actionCell
                                                function onActiveFocusChanged() { actionGlyph.requestPaint() }
                                            }
                                        }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: actionCell.activateAction()
                                        onDoubleClicked: actionCell.activateAction()
                                    }
                                }
                                }

                                TextEdit {
                                    anchors.fill: parent
                                    anchors.margins: root.compact ? NuTokens.spaceXs : NuTokens.spaceSm
                                    visible: !root.isActionColumn(bodyCell.index)
                                             && root.columnType(bodyCell.index) !== "swatch"
                                             && root.columnType(bodyCell.index) !== "lan"
                                    readOnly: true
                                    selectByMouse: true
                                    persistentSelection: true
                                    text: root.valueAt(bodyRow.modelData, bodyCell.index)
                                    color: root.cellLinkUrl(bodyRow.modelData, bodyCell.index).length > 0 ? NuTokens.accentSky : NuTokens.textPrimary
                                    selectedTextColor: NuTokens.textInverse
                                    selectionColor: NuTokens.lineStrong
                                    font.family: root.isMonoColumn(bodyCell.index) ? NuTokens.monoFont : NuTokens.bodyFont
                                    font.pixelSize: root.cellFontSize()
                                    font.underline: root.cellLinkUrl(bodyRow.modelData, bodyCell.index).length > 0
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: root.cellHorizontalAlignment(bodyRow.modelData, bodyCell.index)
                                    wrapMode: TextEdit.NoWrap
                                    clip: true
                                }

                                Rectangle {
                                    visible: root.columnType(bodyCell.index) === "swatch"
                                    anchors.centerIn: parent
                                    width: Math.min(18, Math.max(12, parent.width - 16))
                                    height: width
                                    radius: 2
                                    color: String(root.valueAt(bodyRow.modelData, bodyCell.index) || NuTokens.lineSubtle)
                                    border.color: NuTokens.lineStrong
                                    border.width: 1
                                }

                                Canvas {
                                    id: lanGlyph
                                    visible: root.columnType(bodyCell.index) === "lan"
                                             && String(root.valueAt(bodyRow.modelData, bodyCell.index) || "").length > 0
                                    anchors.centerIn: parent
                                    width: Math.min(22, Math.max(16, parent.width - 8))
                                    height: width
                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.lineWidth = 1.5
                                        ctx.strokeStyle = NuTokens.textPrimary
                                        ctx.fillStyle = NuTokens.accentSky

                                        const cx = width / 2
                                        const topY = height * 0.27
                                        const midY = height * 0.52
                                        const lowY = height * 0.73
                                        const box = Math.max(3.5, width * 0.18)

                                        ctx.beginPath()
                                        ctx.moveTo(cx, topY + box)
                                        ctx.lineTo(cx, midY)
                                        ctx.moveTo(cx, midY)
                                        ctx.lineTo(width * 0.28, lowY - box / 2)
                                        ctx.moveTo(cx, midY)
                                        ctx.lineTo(width * 0.72, lowY - box / 2)
                                        ctx.stroke()

                                        ctx.fillRect(cx - box / 2, topY - box / 2, box, box)
                                        ctx.strokeRect(cx - box / 2, topY - box / 2, box, box)
                                        ctx.fillRect(width * 0.28 - box / 2, lowY - box / 2, box, box)
                                        ctx.strokeRect(width * 0.28 - box / 2, lowY - box / 2, box, box)
                                        ctx.fillRect(width * 0.72 - box / 2, lowY - box / 2, box, box)
                                        ctx.strokeRect(width * 0.72 - box / 2, lowY - box / 2, box, box)
                                    }
                                }

                                MouseArea {
                                    id: bodyMouse
                                    anchors.fill: parent
                                    visible: !root.isActionColumn(bodyCell.index)
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: root.cellLinkUrl(bodyRow.modelData, bodyCell.index).length > 0 ? Qt.PointingHandCursor : Qt.IBeamCursor
                                    property point startPoint: Qt.point(0, 0)
                                    ToolTip.visible: bodyMouse.containsMouse && root.cellToolTip(bodyRow.modelData, bodyCell.index).length > 0
                                    ToolTip.text: root.cellToolTip(bodyRow.modelData, bodyCell.index)
                                    ToolTip.delay: NuTokens.tooltipDelay
                                    ToolTip.timeout: NuTokens.tooltipTimeout
                                    onPressed: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            root.openCopyMenu(bodyCell, mouse.x, mouse.y, bodyRow.index, bodyCell.index)
                                            mouse.accepted = true
                                            return
                                        }
                                        if (root.handleRowSelectionClick(bodyRow.index, mouse.modifiers)) {
                                            mouse.accepted = true
                                            return
                                        }
                                        if (root.handleCellSelectionClick(bodyRow.index, bodyCell.index, mouse.modifiers)) {
                                            mouse.accepted = true
                                            return
                                        }
                                        startPoint = bodyCell.mapToItem(tableViewport, mouse.x, mouse.y)
                                        root.beginRangeSelection(bodyRow.index, bodyCell.index, startPoint)
                                    }
                                    onPositionChanged: (mouse) => {
                                        const point = bodyCell.mapToItem(tableViewport, mouse.x, mouse.y)
                                        if (Math.abs(point.x - startPoint.x) > 3 || Math.abs(point.y - startPoint.y) > 3) root.selectionDragged = true
                                        root.updateRangeSelection(point)
                                    }
                                    onReleased: (mouse) => {
                                        if (mouse.button !== Qt.RightButton) {
                                            const link = root.cellLinkUrl(bodyRow.modelData, bodyCell.index)
                                            const modified = (mouse.modifiers & Qt.ShiftModifier) !== 0
                                                    || (mouse.modifiers & Qt.ControlModifier) !== 0
                                                    || (mouse.modifiers & Qt.MetaModifier) !== 0
                                            root.finishRangeSelection()
                                            if (link.length > 0 && !root.selectionDragged && !modified) {
                                                Qt.openUrlExternally(link)
                                                mouse.accepted = true
                                            }
                                        }
                                    }
                                    onDoubleClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) return
                                        if (root.rowSelectionEnabled) {
                                            const key = root.rowKey(bodyRow.modelData)
                                            if (key.length > 0) {
                                                root.clearCellSelection()
                                                root.rowSelectionAnchor = bodyRow.index
                                                root.setSelectedKeys([key])
                                            }
                                        }
                                        root.rowActivated(bodyRow.modelData)
                                        mouse.accepted = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            text: root.emptyText
            color: NuTokens.textSecondary
            font.family: NuTokens.bodyFont
            font.pixelSize: NuTokens.fontBody
            anchors.centerIn: parent
            width: Math.max(0, parent.width - NuTokens.spaceXl * 2)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: root.rows.length === 0
        }
    }
}
