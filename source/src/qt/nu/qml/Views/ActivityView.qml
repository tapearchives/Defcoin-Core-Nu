import QtQuick 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    spacing: NuTokens.spaceLg

    function rowCells(row) {
        if (row && row.cells !== undefined) return row.cells
        return row
    }

    function matchesDate(row, index) {
        row = rowCells(row)
        if (index === 0) return true
        if (!row || row.length === 0) return false
        var rowDate = new Date(row[1])
        if (isNaN(rowDate.getTime())) return true
        var now = new Date()
        var start = new Date(now)
        start.setHours(0, 0, 0, 0)
        if (index === 1) return rowDate >= start
        if (index === 2) {
            var weekStart = new Date(start)
            weekStart.setDate(start.getDate() - 6)
            return rowDate >= weekStart
        }
        if (index === 3) {
            var monthStart = new Date(start.getFullYear(), start.getMonth(), 1)
            return rowDate >= monthStart
        }
        return true
    }

    function filteredRows() {
        var query = searchField.text.toLowerCase()
        var rows = NuService.recentTransactions
        var out = []
        for (var i = 0; i < rows.length; ++i) {
            var row = rows[i]
            var cells = rowCells(row)
            if (!matchesDate(row, dateFilter.currentIndex)) continue
            if (typeFilter.currentIndex > 0 && cells.length > 2 && cells[2] !== typeFilter.currentText) continue
            if (query.length > 0) {
                var joined = cells.join(" ").toLowerCase()
                if (joined.indexOf(query) === -1) continue
            }
            out.push(row)
        }
        return out
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Transactions"
        detail: "Transactions, requests, and exported wallet records."
    }

    RowLayout {
        Layout.fillWidth: true
        NuComboBox {
            id: dateFilter
            Layout.preferredWidth: 190
            model: ["All dates", "Today", "This week", "This month"]
        }
        NuComboBox {
            id: typeFilter
            Layout.preferredWidth: 190
            model: ["All types", "Sent", "Received", "Mined"]
        }
        NuTextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search address, label, or transaction ID"
        }
        NuActionButton {
            text: "Export transactions"
            Layout.preferredWidth: 190
            helpText: "Export wallet transactions to CSV."
            onClicked: NuService.exportTransactionsCsv()
        }
    }

    NuDataTable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        tableId: "activityTransactions"
        columns: ["", "Date", "Type", "Label", "Amount"]
        columnTypes: ["action", "date", "text", "text", "amount"]
        columnWeights: [0.1, 1.1, 0.65, 3.0, 1.25]
        columnMinimums: [44, 150, 70, 200, 130]
        columnMaximums: [44, 180, 110, 560, 180]
        rows: filteredRows()
        emptyText: "Transactions will appear here."
        onRowActivated: (row) => NuService.requestTransactionDetails(row && row.meta ? row.meta.txid : "")
    }
}
