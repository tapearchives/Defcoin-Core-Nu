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
    property int selectedContactIndex: -1
    property var selectedAddressBookKeys: []

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
        if (contactNameField) contactNameField.text = String(meta.username || "")
        if (contactAddressArea) contactAddressArea.text = String(meta.addressText || "")
    }

    function clearContactEditor() {
        root.selectedContactIndex = -1
        if (contactNameField) contactNameField.text = ""
        if (contactAddressArea) contactAddressArea.text = ""
    }

    function selectedAddressBookRows() {
        const keys = root.selectedAddressBookKeys || []
        const out = []
        for (let r = 0; r < NuService.addressBook.length; ++r) {
            const row = NuService.addressBook[r]
            const cells = row && row.cells !== undefined ? row.cells : row
            const address = cells && cells.length > 1 ? String(cells[1] || "") : ""
            if (keys.indexOf(address) >= 0) out.push(row)
        }
        return out
    }

    function addSelectedAddressBookContacts() {
        const rows = root.selectedAddressBookRows()
        for (let i = 0; i < rows.length; ++i) {
            const cells = rows[i] && rows[i].cells !== undefined ? rows[i].cells : rows[i]
            const label = cells && cells.length > 0 ? String(cells[0] || "").trim() : ""
            const address = cells && cells.length > 1 ? String(cells[1] || "").trim() : ""
            if (address.length > 0) NuService.saveExplorerContact(label.length > 0 ? label : address, address, -1)
        }
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
            const balanceSats = Number(balances[name] || 0)
            const nodeRadius = 18 + 28 * Math.sqrt(balanceSats / maxBalance)
            const wholeDfc = Math.round(balanceSats / 100000000)
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
            ctx.fillText(name, pos.x, pos.y - 5)
            ctx.font = "10px " + NuTokens.bodyFont
            ctx.fillText(wholeDfc.toLocaleString() + " DFC", pos.x, pos.y + 9)
        }
        if (contacts.length === 0) {
            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px " + NuTokens.bodyFont
            ctx.textAlign = "center"
            ctx.fillText("Add contacts to chart address relationships.", cx, cy)
        }
    }

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
        NuTabButton { text: "Fix Witness Data" }
        NuTabButton { text: "Contacts" }
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
                    id: forensicsScanStatusArea
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
                    Shortcut {
                        sequences: [StandardKey.Copy]
                        enabled: forensicsScanStatusArea.activeFocus && forensicsScanStatusArea.selectedText.length > 0
                        onActivated: NuService.copyText(forensicsScanStatusArea.selectedText)
                    }
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
                    id: forensicsScanSummaryArea
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
                    Shortcut {
                        sequences: [StandardKey.Copy]
                        enabled: forensicsScanSummaryArea.activeFocus && forensicsScanSummaryArea.selectedText.length > 0
                        onActivated: NuService.copyText(forensicsScanSummaryArea.selectedText)
                    }
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
                            text: "Fix Witness Data"
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
                        enabled: !NuService.forensicsWitnessRepairRunning && NuService.forensicsWitnessInspectionAvailable
                        text: "Fix missing witness data"
                        helpText: "When enabled, Nu rewinds from the first block whose local stored body lacks witness data, then resumes normal syncing so that block data is redownloaded."
                    }

                    NuActionButton {
                        Layout.preferredWidth: 132
                        text: NuService.forensicsWitnessRepairRunning ? "Inspecting" : "Inspect now"
                        primary: !NuService.forensicsWitnessRepairRunning
                        enabled: !NuService.forensicsWitnessRepairRunning && NuService.forensicsWitnessInspectionAvailable
                        helpText: NuService.forensicsWitnessInspectionAvailable
                                  ? "Run the witness-storage inspection without scanning irregular OP_RETURN messages."
                                  : "This active backend does not expose Nu's scanwitnessblockdata RPC. Stop older defcoind instances and launch the bundled Nu backend."
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
                    id: forensicsWitnessRepairStatusArea
                    Layout.fillWidth: true
                    text: NuService.forensicsWitnessRepairStatus
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    background: Item {}
                    padding: 0
                    Shortcut {
                        sequences: [StandardKey.Copy]
                        enabled: forensicsWitnessRepairStatusArea.activeFocus && forensicsWitnessRepairStatusArea.selectedText.length > 0
                        onActivated: NuService.copyText(forensicsWitnessRepairStatusArea.selectedText)
                    }
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
                            text: "Forensics Contacts"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontTitle
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Local username-to-address groups for forensic relationship charts. Contacts stay on this machine and can be seeded from the active wallet address book."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                    NuActionButton {
                        Layout.preferredWidth: 160
                        text: "Chart relationships"
                        primary: true
                        helpText: "Build an indexed relationship table from the saved Forensics Contacts."
                        onClicked: {
                            NuService.refreshExplorerContactRelationships()
                            contactGraphCanvas.requestPaint()
                            contactGraphWindow.show()
                            contactGraphWindow.raise()
                            contactGraphWindow.requestActivate()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 142
                    spacing: NuTokens.spaceMd

                    ColumnLayout {
                        Layout.preferredWidth: Math.max(250, root.width * 0.25)
                        Layout.fillHeight: true
                        spacing: NuTokens.spaceXs
                        Label { text: "Username"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                        NuTextField {
                            id: contactNameField
                            Layout.fillWidth: true
                            placeholderText: "username, handle, pool, or project"
                            helpText: "Local display name for a person, pool, project, or address cluster."
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: NuTokens.spaceXs
                        Label {
                            Layout.fillWidth: true
                            text: "Saved contacts"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            tableId: "forensicsContacts"
                            columns: ["User", "Addresses", "Count"]
                            columnTypes: ["text", "address", "number"]
                            columnWeights: [1.0, 3.0, 0.45]
                            rows: root.contactRows()
                            emptyText: "No saved Forensics Contacts yet."
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
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: NuTokens.spaceXs
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: "Add from wallet address book"
                                color: NuTokens.textPrimary
                                font.pixelSize: NuTokens.fontBodyLarge
                                font.weight: Font.DemiBold
                            }
                            NuActionButton {
                                Layout.preferredWidth: 132
                                text: "Add selected"
                                enabled: root.selectedAddressBookKeys.length > 0
                                helpText: "Copy selected active-wallet address-book entries into Forensics Contacts."
                                onClicked: root.addSelectedAddressBookContacts()
                            }
                        }
                        NuDataTable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            tableId: "forensicsContactsAddressBook"
                            columns: ["Label", "Address", "Type", "Received"]
                            columnTypes: ["text", "address", "text", "amount"]
                            columnWeights: [1.2, 3.0, 0.8, 1.1]
                            rows: NuService.addressBook
                            emptyText: "Open a wallet with address-book entries to seed Forensics Contacts."
                            rowSelectionEnabled: true
                            plainClickSelectsRows: true
                            rowKeyMetaField: "address"
                            onRowSelectionChanged: (keys) => root.selectedAddressBookKeys = keys
                        }
                    }
                }

                NuDataTable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    tableId: "forensicsContactRelationships"
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

    Window {
        id: forensicsTableWindow
        title: "Irregular Messages"
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

    Window {
        id: contactGraphWindow
        width: 1040
        height: 760
        minimumWidth: 760
        minimumHeight: 560
        visible: false
        title: "Forensics Contact Relationship Graph"
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
                    text: "Forensics Contact Relationship Graph"
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
                text: "Node size is based on saved addresses that also appear in the current Top 100. Each node shows rounded DFC. Line thickness is based on indexed direct spend flow between saved contact groups."
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
                tableId: "forensicsContactGraphFlows"
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
