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

    readonly property real scanProgress: NuService.forensicsScanTip > 0
                                         ? Math.max(0, Math.min(1, NuService.forensicsScanHeight / NuService.forensicsScanTip))
                                         : 0

    function progressText() {
        if (NuService.forensicsScanTip <= 0) return "0.00%"
        return (root.scanProgress * 100).toFixed(2) + "%"
    }

    function openRow(row) {
        const meta = row && row.meta ? row.meta : {}
        const txid = String(meta.txid || meta.id || "")
        if (txid.length > 0)
            NuService.openTransactionInExplorer(txid)
    }

    Component.onCompleted: {
        if (NuService.forensicsIrregularMessageCount === 0 && NuService.forensicsScanStatus.indexOf("not started") >= 0)
            NuService.refreshForensicsIrregularMessages()
    }

    Connections {
        target: NuService
        function onStateChanged() {
            if (NuService.rpcConnected
                    && !NuService.forensicsScanning
                    && NuService.forensicsIrregularMessageCount === 0
                    && NuService.forensicsScanStatus.indexOf("Connect to the local backend") >= 0)
                NuService.refreshForensicsIrregularMessages()
        }
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Forensics"
        detail: "Blockchain oddities, hidden messages, and anomaly lists built from local block data."
    }

    NuTabBar {
        id: forensicsTabs
        Layout.fillWidth: true
        NuTabButton { text: "Irregular Messages" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: forensicsTabs.currentIndex

        NuPanel {
            ColumnLayout {
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
                            text: "Irregular Messages"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontTitle
                            font.weight: Font.DemiBold
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Unusual OP_RETURN text outputs found in accepted Defcoin blocks. Rows are flagged when the output burns DFC, bypasses standard relay size limits, contains executable script opcodes, or appears more than once in a transaction."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    NuActionButton {
                        Layout.preferredWidth: 140
                        text: NuService.forensicsScanning ? "Scanning" : "Rescan"
                        enabled: !NuService.forensicsScanning
                        primary: !NuService.forensicsScanning
                        helpText: "Scan active-chain block data for nonstandard OP_RETURN outputs and rebuild this list."
                        onClicked: NuService.refreshForensicsIrregularMessages()
                    }

                    NuActionButton {
                        Layout.preferredWidth: 96
                        text: "Pause"
                        enabled: NuService.forensicsScanning
                        helpText: "Pause after the current scan chunk returns."
                        onClicked: NuService.stopForensicsScan()
                    }
                }

                Basic.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    from: 0
                    to: 1
                    value: root.scanProgress
                    indeterminate: NuService.forensicsScanning && NuService.forensicsScanTip <= 0
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow { label: "Progress"; value: root.progressText() }
                    NuMetricRow { label: "Next block"; value: String(NuService.forensicsScanHeight) }
                    NuMetricRow { label: "Tip"; value: String(NuService.forensicsScanTip) }
                    NuMetricRow { label: "Rows"; value: String(NuService.forensicsIrregularMessageCount) }
                }

                Label {
                    Layout.fillWidth: true
                    text: NuService.forensicsScanStatus
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "forensicsIrregularMessages"
                    columns: ["Block Height", "Transaction ID", "Burned Defcoin Amount", "Decoded Text Message", "Flag"]
                    columnTypes: ["number", "hash", "amount", "text", "text"]
                    columnWeights: [0.75, 3.0, 1.3, 3.6, 2.2]
                    columnMinimums: [112, 300, 190, 260, 220]
                    columnTooltips: [
                        "Active-chain block height where the irregular OP_RETURN output was mined.",
                        "Transaction containing the flagged OP_RETURN output. Double-click a row to open it in Explorer.",
                        "DFC permanently burned by the unspendable OP_RETURN output. Standard OP_RETURN outputs normally carry zero value.",
                        "Printable text decoded from pushed OP_RETURN bytes. Non-text payloads are summarized in hex.",
                        "Why Nu flagged this row as irregular compared with standard node relay policy."
                    ]
                    rows: NuService.forensicsIrregularMessages
                    emptyText: NuService.forensicsScanning
                               ? "Scanning active-chain blocks for irregular OP_RETURN messages."
                               : "No irregular OP_RETURN messages found yet. Run Rescan after the backend is connected."
                    defaultSortColumn: 0
                    defaultSortAscending: true
                    autoFitOnRowsChanged: true
                    alwaysShowHorizontalScrollBar: true
                    onRowActivated: (row) => root.openRow(row)
                }
            }
        }
    }
}
