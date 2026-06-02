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

    property bool active: false
    property int preferredTab: 0
    property string sectionTitle: "Message Scan"
    property string sectionDetail: "Scan accepted Defcoin blocks for unusual OP_RETURN text, burned outputs, and message patterns."
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
    property string pendingAddressBookWallet: ""
    property string draggedAddressBookLabel: ""
    property string draggedAddressBookAddress: ""

    function applyPreferredTab() {
        if (forensicsTabs)
            forensicsTabs.currentIndex = Math.max(0, Math.min(2, root.preferredTab))
    }

    Component.onCompleted: Qt.callLater(root.applyPreferredTab)
    onPreferredTabChanged: if (root.active) root.applyPreferredTab()
    onActiveChanged: if (active) root.applyPreferredTab()

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

    function addressBookCells(row) {
        return row && row.cells !== undefined ? row.cells : row
    }

    function addressBookLabel(row) {
        const cells = root.addressBookCells(row)
        return cells && cells.length > 0 ? String(cells[0] || "").trim() : ""
    }

    function addressBookAddress(row) {
        const cells = root.addressBookCells(row)
        return cells && cells.length > 1 ? String(cells[1] || "").trim() : ""
    }

    function addressBookType(row) {
        const cells = root.addressBookCells(row)
        return cells && cells.length > 2 ? String(cells[2] || "").trim() : ""
    }

    function addressBookReceived(row) {
        const cells = root.addressBookCells(row)
        return cells && cells.length > 3 ? String(cells[3] || "").trim() : ""
    }

    function addAddressBookContact(label, address) {
        const cleanAddress = String(address || "").trim()
        if (cleanAddress.length === 0) return
        const cleanLabel = String(label || "").trim()
        NuService.saveExplorerContact(cleanLabel.length > 0 ? cleanLabel : cleanAddress, cleanAddress, -1)
    }

    function addAddressBookRow(row) {
        root.addAddressBookContact(root.addressBookLabel(row), root.addressBookAddress(row))
    }

    function addSelectedAddressBookContacts() {
        const rows = root.selectedAddressBookRows()
        for (let i = 0; i < rows.length; ++i) {
            root.addAddressBookRow(rows[i])
        }
    }

    function beginAddressBookDrag(label, address) {
        root.draggedAddressBookLabel = String(label || "").trim()
        root.draggedAddressBookAddress = String(address || "").trim()
    }

    function clearAddressBookDragSoon() {
        Qt.callLater(function() {
            root.draggedAddressBookLabel = ""
            root.draggedAddressBookAddress = ""
        })
    }

    function addDraggedAddressBookContact() {
        root.addAddressBookContact(root.draggedAddressBookLabel, root.draggedAddressBookAddress)
    }

    function dropDraggedAddressIntoEditor() {
        const address = root.draggedAddressBookAddress
        if (address.length === 0) return
        const label = root.draggedAddressBookLabel
        if (contactNameField && contactNameField.text.trim().length === 0)
            contactNameField.text = label.length > 0 ? label : address
        if (contactAddressArea) {
            const current = contactAddressArea.text.trim()
            const parts = current.length > 0 ? current.split(/[\s,]+/) : []
            if (parts.indexOf(address) < 0)
                contactAddressArea.text = current.length > 0 ? current + "\n" + address : address
        }
    }

    function availableWalletModel() {
        const out = []
        for (let i = 0; i < NuService.availableWallets.length; ++i) {
            const name = String(NuService.availableWallets[i] || "")
            if (out.indexOf(name) < 0) out.push(name)
        }
        if (NuService.walletSelected && out.indexOf(NuService.currentWalletName) < 0)
            out.push(NuService.currentWalletName)
        return out
    }

    function isWalletLoaded(name) {
        const wanted = String(name || "")
        for (let i = 0; i < NuService.loadedWallets.length; ++i) {
            if (String(NuService.loadedWallets[i] || "") === wanted) return true
        }
        return false
    }

    function formatWalletMenuLabel(name) {
        const walletName = String(name || "")
        const tags = []
        if (NuService.walletSelected && walletName === NuService.currentWalletName) tags.push("current")
        else if (root.isWalletLoaded(walletName)) tags.push("loaded")
        const display = NuService.walletDisplayName(walletName)
        return tags.length > 0 ? display + " (" + tags.join(", ") + ")" : display
    }

    function walletAddressBookStatusText() {
        if (!NuService.walletSelected)
            return "No wallet selected. Choose a Nu wallet to read labels and addresses."
        const lockText = NuService.walletEncrypted && NuService.walletLocked
                       ? " Locked wallet; address-book reads do not unlock it."
                       : ""
        return NuService.walletDisplayName(NuService.currentWalletName)
               + ": " + NuService.addressBook.length + " address-book entries visible."
               + lockText
    }

    function selectedAddressBookWalletName() {
        if (!addressBookWalletCombo || addressBookWalletCombo.count <= 0) return ""
        return String(addressBookWalletCombo.currentText || "")
    }

    function syncAddressBookWalletCombo() {
        if (!addressBookWalletCombo || addressBookWalletCombo.count <= 0) return
        const wanted = NuService.walletSelected ? String(NuService.currentWalletName || "") : ""
        if (wanted.length === 0) {
            if (addressBookWalletCombo.currentIndex < 0) addressBookWalletCombo.currentIndex = 0
            return
        }
        const rows = root.availableWalletModel()
        for (let i = 0; i < rows.length; ++i) {
            if (String(rows[i] || "") === wanted) {
                addressBookWalletCombo.currentIndex = i
                return
            }
        }
    }

    function requestAddressBookWallet(walletName) {
        const cleanName = String(walletName || "")
        root.pendingAddressBookWallet = cleanName
        addressBookWalletApprovalDialog.open()
    }

    function useSelectedAddressBookWallet() {
        if (!addressBookWalletCombo || addressBookWalletCombo.count <= 0) return
        const walletName = root.selectedAddressBookWalletName()
        root.requestAddressBookWallet(walletName)
    }

    function approveAddressBookWallet() {
        const walletName = root.pendingAddressBookWallet
        root.pendingAddressBookWallet = ""
        if (root.isWalletLoaded(walletName)) NuService.setCurrentWallet(walletName)
        else NuService.loadWallet(walletName)
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

    Connections {
        target: NuService
        function onWalletChanged() { Qt.callLater(root.syncAddressBookWalletCombo) }
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: root.sectionTitle
        detail: root.sectionDetail
    }

    NuTabBar {
        id: forensicsTabs
        Layout.fillWidth: true
        NuTabButton { text: "Message Scan" }
        NuTabButton { text: "Witness Repair" }
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
                            text: "Message Scan"
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
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Basic.TextArea {
                                id: contactAddressArea
                                anchors.fill: parent
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

                            DropArea {
                                id: contactEditorDropArea
                                anchors.fill: parent
                                keys: ["defcoin-address-book"]
                                onDropped: root.dropDraggedAddressIntoEditor()
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: contactEditorDropArea.containsDrag && root.draggedAddressBookAddress.length > 0
                                radius: NuTokens.radiusSmall
                                color: NuTokens.accentSky
                                opacity: 0.12
                                border.color: NuTokens.accentSky
                                border.width: 1
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: contactEditorDropArea.containsDrag && root.draggedAddressBookAddress.length > 0
                                text: "Drop address here"
                                color: NuTokens.textPrimary
                                font.pixelSize: NuTokens.fontBody
                                font.weight: Font.DemiBold
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
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            NuDataTable {
                                id: savedContactsTable
                                anchors.fill: parent
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

                            DropArea {
                                id: savedContactsDropArea
                                anchors.fill: parent
                                keys: ["defcoin-address-book"]
                                onDropped: root.addDraggedAddressBookContact()
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: savedContactsDropArea.containsDrag && root.draggedAddressBookAddress.length > 0
                                radius: NuTokens.radiusMedium
                                color: NuTokens.accentSky
                                opacity: 0.12
                                border.color: NuTokens.accentSky
                                border.width: 1
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: savedContactsDropArea.containsDrag && root.draggedAddressBookAddress.length > 0
                                text: "Drop to save contact"
                                color: NuTokens.textPrimary
                                font.pixelSize: NuTokens.fontBody
                                font.weight: Font.DemiBold
                            }
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
                                text: "Nu wallet address book"
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

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: NuTokens.spaceSm

                            NuComboBox {
                                id: addressBookWalletCombo
                                Layout.fillWidth: true
                                model: root.availableWalletModel()
                                textFormatter: root.formatWalletMenuLabel
                                enabled: count > 0
                                helpText: "Choose the Nu wallet whose visible address-book labels and addresses ExpFor can read for Contacts."
                                Component.onCompleted: root.syncAddressBookWalletCombo()
                                onModelChanged: Qt.callLater(root.syncAddressBookWalletCombo)
                            }

                            NuActionButton {
                                Layout.preferredWidth: 112
                                text: "Use wallet"
                                enabled: addressBookWalletCombo.count > 0
                                helpText: "Ask for approval before opening or selecting this Nu wallet for address-book contact import."
                                onClicked: root.useSelectedAddressBookWallet()
                            }

                            NuActionButton {
                                Layout.preferredWidth: 92
                                text: "Refresh"
                                enabled: NuService.rpcConnected
                                helpText: "Refresh the active wallet address book from the local Defcoin backend."
                                onClicked: NuService.refresh()
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.walletAddressBookStatusText()
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }

                        NuDataTable {
                            id: addressBookTable
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            tableId: "forensicsContactsAddressBook"
                            columns: ["Label", "Address", "Type", "Received"]
                            columnTypes: ["text", "address", "text", "amount"]
                            columnWeights: [1.2, 3.0, 0.8, 1.1]
                            rows: NuService.addressBook
                            emptyText: ""
                            rowSelectionEnabled: true
                            plainClickSelectsRows: true
                            rowKeyMetaField: "address"
                            onRowSelectionChanged: (keys) => root.selectedAddressBookKeys = keys
                            onRowActivated: (row) => root.addAddressBookRow(row)
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 156
                            radius: NuTokens.radiusMedium
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            border.width: 1

                            ListView {
                                id: addressBookDragList
                                anchors.fill: parent
                                anchors.margins: NuTokens.spaceXs
                                clip: true
                                spacing: NuTokens.spaceXs
                                model: NuService.addressBook
                                boundsBehavior: Flickable.StopAtBounds
                                Basic.ScrollBar.vertical: Basic.ScrollBar { policy: Basic.ScrollBar.AsNeeded }

                                delegate: Item {
                                    id: addressBookDragItem
                                    required property var modelData
                                    width: addressBookDragList.width
                                    height: 44
                                    property string labelText: root.addressBookLabel(modelData)
                                    property string addressText: root.addressBookAddress(modelData)
                                    property string typeText: root.addressBookType(modelData)
                                    property string receivedText: root.addressBookReceived(modelData)
                                    property bool selected: root.selectedAddressBookKeys.indexOf(addressText) >= 0

                                    Rectangle {
                                        id: addressBookDragCard
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: NuTokens.radiusSmall
                                        color: addressBookDragItem.selected ? "#eef7ff" : NuTokens.panelBase
                                        border.color: addressBookDragMouse.drag.active ? NuTokens.accentSky
                                                                                      : (addressBookDragItem.selected ? NuTokens.lineStrong : NuTokens.lineSubtle)
                                        border.width: addressBookDragMouse.drag.active || addressBookDragItem.selected ? 2 : 1
                                        z: addressBookDragMouse.drag.active ? 20 : 0
                                        Drag.active: addressBookDragMouse.drag.active
                                        Drag.keys: ["defcoin-address-book"]
                                        Drag.mimeData: { "text/plain": addressBookDragItem.addressText }
                                        Drag.supportedActions: Qt.CopyAction
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2

                                        MouseArea {
                                            id: addressBookDragMouse
                                            anchors.fill: parent
                                            anchors.rightMargin: 66
                                            hoverEnabled: true
                                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                            drag.target: addressBookDragCard
                                            onPressed: root.beginAddressBookDrag(addressBookDragItem.labelText, addressBookDragItem.addressText)
                                            onClicked: {
                                                root.selectedAddressBookKeys = [addressBookDragItem.addressText]
                                                addressBookTable.setSelectedKeys(root.selectedAddressBookKeys)
                                            }
                                            onDoubleClicked: root.addAddressBookRow(addressBookDragItem.modelData)
                                            onReleased: {
                                                addressBookDragCard.x = 0
                                                addressBookDragCard.y = 0
                                                root.clearAddressBookDragSoon()
                                            }
                                        }

                                        Label {
                                            anchors.left: parent.left
                                            anchors.leftMargin: NuTokens.spaceSm
                                            anchors.right: addDragContactButton.left
                                            anchors.rightMargin: NuTokens.spaceSm
                                            anchors.top: parent.top
                                            anchors.topMargin: 5
                                            text: addressBookDragItem.labelText.length > 0 ? addressBookDragItem.labelText : "(no label)"
                                            color: NuTokens.textPrimary
                                            font.pixelSize: NuTokens.fontSmall
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            anchors.left: parent.left
                                            anchors.leftMargin: NuTokens.spaceSm
                                            anchors.right: addDragContactButton.left
                                            anchors.rightMargin: NuTokens.spaceSm
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 5
                                            text: addressBookDragItem.addressText
                                                  + (addressBookDragItem.typeText.length > 0 ? " | " + addressBookDragItem.typeText : "")
                                                  + (addressBookDragItem.receivedText.length > 0 ? " | " + addressBookDragItem.receivedText : "")
                                            color: NuTokens.textSecondary
                                            font.pixelSize: 12
                                            font.family: NuTokens.monoFont
                                            elide: Text.ElideMiddle
                                        }

                                        NuActionButton {
                                            id: addDragContactButton
                                            anchors.right: parent.right
                                            anchors.rightMargin: NuTokens.spaceSm
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 54
                                            height: 28
                                            text: "Add"
                                            helpText: "Copy this wallet address-book entry into Forensics Contacts."
                                            onClicked: root.addAddressBookRow(addressBookDragItem.modelData)
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    visible: NuService.addressBook.length === 0
                                    text: "No address-book entries visible.\nOpen a wallet with labels to seed Contacts."
                                    color: NuTokens.textMuted
                                    font.pixelSize: NuTokens.fontSmall
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
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

    NuDialog {
        id: addressBookWalletApprovalDialog
        title: "Use wallet address book?"
        acceptText: "Use wallet"
        cancelText: "Cancel"
        showCancel: true
        onAccepted: root.approveAddressBookWallet()
        onRejected: root.pendingAddressBookWallet = ""

        Label {
            Layout.fillWidth: true
            text: "ExpFor will ask the local Defcoin backend to open or select this Nu wallet and read visible address-book labels and addresses for the Forensics Contacts list."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: "Wallet: " + NuService.walletDisplayName(root.pendingAddressBookWallet)
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: "This does not unlock the wallet, request a passphrase, sign transactions, spend funds, or read private keys."
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }
    }

    Window {
        id: forensicsTableWindow
        title: "Message Scan"
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
                    text: "Message Scan"
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
                text: "Node size is based on saved addresses that also appear in the current largest-holder table. Each node shows rounded DFC. Line thickness is based on indexed direct spend flow between saved contact groups."
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
