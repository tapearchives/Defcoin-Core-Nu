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

    readonly property real scanProgress: NuService.forensicsScanTip > 0
                                         ? Math.max(0, Math.min(1, NuService.forensicsScanHeight / NuService.forensicsScanTip))
                                         : 0
    property int popoutFontSize: 13
    readonly property int embeddedRowRenderLimit: 800
    readonly property int popoutRowRenderLimit: 1500
    readonly property var irregularColumns: ["Block Height", "Transaction ID", "BIP141 Definition", "Burned Defcoin Amount", "Decoded Text Message", "Flag"]
    readonly property var irregularColumnTypes: ["number", "hash", "link", "amount", "text", "text"]
    readonly property var irregularColumnWeights: [0.75, 3.0, 1.9, 1.3, 3.6, 2.2]
    readonly property var irregularColumnMinimums: [112, 300, 240, 190, 260, 220]
    readonly property var irregularColumnLinkMetaFields: ["", "", "bip141Url", "", "", ""]
    readonly property var irregularColumnTooltips: [
        "Active-chain block height where the irregular OP_RETURN output was mined.",
        "Transaction containing the flagged OP_RETURN output. Double-click a row to open it in Explorer.",
        "BIP141-related meaning for the four-byte payload header when Nu recognizes one. Click the link text to open the authoritative BIP141 definition.",
        "DFC permanently burned by the unspendable OP_RETURN output. Standard OP_RETURN outputs normally carry zero value.",
        "Printable text decoded from pushed OP_RETURN bytes. Non-text payloads are summarized in hex.",
        "Why Nu flagged this row as irregular compared with standard node relay policy."
    ]

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

    function scanActionText() {
        if (NuService.forensicsScanning) return "Pause"
        if (NuService.forensicsScanComplete) return "Rescan"
        if (NuService.forensicsScanHeight > 0 || NuService.forensicsIrregularMessageCount > 0) return "Resume"
        return "Scan"
    }

    function runScanAction() {
        if (NuService.forensicsScanning) NuService.stopForensicsScan()
        else if (NuService.forensicsScanComplete || NuService.forensicsScanHeight <= 0) NuService.startForensicsIrregularMessages(root.startHeightValue())
        else NuService.resumeForensicsScan()
    }

    function startHeightValue() {
        const parsed = parseInt(forensicsStartHeight.editText || forensicsStartHeight.currentText || "0")
        return isNaN(parsed) || parsed < 0 ? 0 : parsed
    }

    function witnessStartHeightValue() {
        const parsed = parseInt(witnessStartHeight.editText || witnessStartHeight.currentText || "903168")
        return isNaN(parsed) || parsed < 0 ? 903168 : parsed
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
        NuTabButton { text: "Witness Repair" }
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

                    Label {
                        text: "Start"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }

                    NuComboBox {
                        id: forensicsStartHeight
                        Layout.preferredWidth: 132
                        editable: true
                        model: ["0", "128143"]
                        currentIndex: 0
                        enabled: !NuService.forensicsScanning
                        helpText: "Starting block for the irregular-message scan. 0 scans the whole active chain; 128143 is an early historical inspection point."
                    }

                    NuActionButton {
                        Layout.preferredWidth: 112
                        text: root.scanActionText()
                        primary: !NuService.forensicsScanning
                        helpText: NuService.forensicsScanning
                                  ? "Pause after the current scan chunk returns. Resume continues from the same block."
                                  : (NuService.forensicsScanComplete
                                     ? "Run the irregular-message scan again from block 0."
                                     : "Scan or resume active-chain block data for nonstandard OP_RETURN outputs.")
                        onClicked: root.runScanAction()
                    }

                    NuActionButton {
                        Layout.preferredWidth: 100
                        text: "Start over"
                        visible: !NuService.forensicsScanning
                                 && !NuService.forensicsScanComplete
                                 && (NuService.forensicsScanHeight > 0 || NuService.forensicsIrregularMessageCount > 0)
                        helpText: "Discard current scan rows and restart from the selected start height."
                        onClicked: NuService.startForensicsIrregularMessages(root.startHeightValue())
                    }

                    NuActionButton {
                        Layout.preferredWidth: 118
                        text: "Pop out"
                        enabled: NuService.forensicsIrregularMessageCount > 0 || NuService.forensicsScanning
                        helpText: "Open the irregular messages table in its own resizable window with fixed-width font controls."
                        onClicked: {
                            forensicsTableWindow.show()
                            forensicsTableWindow.raise()
                            Qt.callLater(function() {
                                popoutForensicsTable.forceResetColumnWidths()
                            })
                        }
                    }

                    NuActionButton {
                        Layout.preferredWidth: 112
                        text: "Export CSV"
                        enabled: NuService.forensicsIrregularMessageCount > 0
                        helpText: "Export the currently loaded irregular rows to CSV."
                        onClicked: NuService.exportForensicsIrregularMessagesCsv()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuCheckBox {
                        checked: NuService.forensicsAcceptBip141AsRegular
                        text: "Accept aa21a9ed BIP141 witness commitments as regular"
                        helpText: "Recommended. Defcoin's historical SegWit-compatible blocks can include the aa21a9ed witness commitment header. Leave this on to avoid filling the irregular list with normal commitment rows."
                        onToggled: NuService.forensicsAcceptBip141AsRegular = checked
                    }
                    Item { Layout.fillWidth: true }
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

                Basic.TextArea {
                    Layout.fillWidth: true
                    text: NuService.forensicsScanStatus
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
                }

                Label {
                    Layout.fillWidth: true
                    visible: NuService.forensicsIrregularMessageCount > root.embeddedRowRenderLimit
                    text: "Showing the first " + root.embeddedRowRenderLimit + " rows in this view to keep the app responsive. Use Pop out for a larger working set or Export CSV for the full loaded list."
                    color: NuTokens.stateWarning
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Basic.TextArea {
                    Layout.fillWidth: true
                    visible: NuService.forensicsScanComplete && NuService.forensicsScanSummary.length > 0
                    text: NuService.forensicsScanSummary
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    background: Item {}
                    padding: 0
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "forensicsIrregularMessages"
                    columns: root.irregularColumns
                    columnTypes: root.irregularColumnTypes
                    columnWeights: root.irregularColumnWeights
                    columnMinimums: root.irregularColumnMinimums
                    columnLinkMetaFields: root.irregularColumnLinkMetaFields
                    columnTooltips: root.irregularColumnTooltips
                    rows: NuService.forensicsIrregularMessages
                    emptyText: NuService.forensicsScanning
                               ? "Scanning active-chain blocks for irregular OP_RETURN messages."
                               : "No irregular OP_RETURN messages found yet. Run Rescan after the backend is connected."
                    defaultSortColumn: 0
                    defaultSortAscending: true
                    autoFitOnRowsChanged: true
                    alwaysShowHorizontalScrollBar: true
                    rowRenderLimit: root.embeddedRowRenderLimit
                    widthMeasurementRowLimit: root.embeddedRowRenderLimit
                    greenBarRows: true
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
                    spacing: NuTokens.spaceLg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceXs

                        Label {
                            Layout.fillWidth: true
                            text: "Witness Repair"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontTitle
                            font.weight: Font.DemiBold
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Inspect post-activation blocks for missing witness-form block storage without loading the irregular-message table. If a short stored block is found, Nu can rewind from the first affected height and redownload clean block bodies from witness-capable peers."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    Label {
                        text: "Start"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }

                    NuComboBox {
                        id: witnessStartHeight
                        Layout.preferredWidth: 132
                        editable: true
                        model: ["903168", "128143", "0"]
                        currentIndex: 0
                        enabled: !NuService.forensicsWitnessRepairRunning
                        helpText: "903168 is Defcoin's historical SegWit boundary. Use an earlier height only when auditing older local block storage."
                    }

                    NuCheckBox {
                        id: witnessFixMissing
                        checked: true
                        enabled: !NuService.forensicsWitnessRepairRunning
                        text: "Fix missing witness data"
                        helpText: "When enabled, Nu rewinds from the first block whose local stored body lacks witness data, then resumes normal syncing so that block data is redownloaded."
                    }

                    NuActionButton {
                        Layout.preferredWidth: 132
                        text: NuService.forensicsWitnessRepairRunning ? "Inspecting" : "Inspect now"
                        primary: !NuService.forensicsWitnessRepairRunning
                        enabled: !NuService.forensicsWitnessRepairRunning
                        helpText: "Run the witness-storage inspection without scanning irregular OP_RETURN messages."
                        onClicked: NuService.repairWitnessBlockDataNow(root.witnessStartHeightValue(), witnessFixMissing.checked)
                    }
                }

                Basic.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    indeterminate: NuService.forensicsWitnessRepairRunning
                    visible: NuService.forensicsWitnessRepairRunning
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow { label: "Start height"; value: String(NuService.forensicsWitnessRepairStartHeight) }
                    NuMetricRow { label: "Blocks inspected"; value: String(NuService.forensicsWitnessRepairInspectedBlocks) }
                    NuMetricRow {
                        label: "First missing"
                        value: NuService.forensicsWitnessRepairFirstMissingHeight > 0 ? String(NuService.forensicsWitnessRepairFirstMissingHeight) : "None"
                    }
                }

                Basic.TextArea {
                    Layout.fillWidth: true
                    text: NuService.forensicsWitnessRepairStatus
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    background: Item {}
                    padding: 0
                }

                Label {
                    Layout.fillWidth: true
                    text: "This is a local block-body storage repair, not a wallet rescan and not a consensus change. Balances and transactions are not deleted. If repair rewinds blocks, normal synchronization will refill them afterward."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Window {
        id: forensicsTableWindow
        title: "Defcoin Core Nu - Irregular Messages"
        width: 1280
        height: 760
        minimumWidth: 860
        minimumHeight: 520
        visible: false
        color: NuTokens.backgroundBase

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: NuTokens.spaceLg
            spacing: NuTokens.spaceMd

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Irregular Messages"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontTitle
                    font.weight: Font.DemiBold
                }

                Label {
                    text: "Font"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }

                Basic.Slider {
                    Layout.preferredWidth: 160
                    from: 10
                    to: 18
                    stepSize: 1
                    value: root.popoutFontSize
                    onMoved: {
                        root.popoutFontSize = Math.round(value)
                        Qt.callLater(function() { popoutForensicsTable.forceResetColumnWidths() })
                    }
                }

                Label {
                    text: root.popoutFontSize + " px"
                    color: NuTokens.textSecondary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                }

                NuActionButton {
                    Layout.preferredWidth: 96
                    text: "Auto-fit"
                    helpText: "Recalculate all column widths from the current rows and headers."
                    onClicked: popoutForensicsTable.forceResetColumnWidths()
                }
            }

            Label {
                Layout.fillWidth: true
                text: NuService.forensicsScanComplete && NuService.forensicsScanSummary.length > 0
                      ? NuService.forensicsScanSummary
                      : NuService.forensicsScanStatus
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                visible: NuService.forensicsIrregularMessageCount > root.popoutRowRenderLimit
                text: "Rendering " + root.popoutRowRenderLimit + " of " + NuService.forensicsIrregularMessageCount + " loaded rows to keep scrolling responsive. Export CSV includes all loaded rows."
                color: NuTokens.stateWarning
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            NuDataTable {
                id: popoutForensicsTable
                Layout.fillWidth: true
                Layout.fillHeight: true
                tableId: "forensicsIrregularMessagesPopout"
                columns: root.irregularColumns
                columnTypes: root.irregularColumnTypes
                columnWeights: root.irregularColumnWeights
                columnMinimums: root.irregularColumnMinimums
                columnLinkMetaFields: root.irregularColumnLinkMetaFields
                columnTooltips: root.irregularColumnTooltips
                rows: NuService.forensicsIrregularMessages
                emptyText: "No irregular OP_RETURN messages are loaded yet."
                defaultSortColumn: 0
                defaultSortAscending: true
                autoFitOnRowsChanged: true
                autoFitOnFontChanged: true
                alwaysShowHorizontalScrollBar: true
                rowRenderLimit: root.popoutRowRenderLimit
                widthMeasurementRowLimit: root.popoutRowRenderLimit
                greenBarRows: true
                forceMonospace: true
                fontPixelSize: root.popoutFontSize
                onRowActivated: (row) => root.openRow(row)
            }
        }
    }

}
