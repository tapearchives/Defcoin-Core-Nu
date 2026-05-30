import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg

    signal createWalletRequested()
    signal createRecoveryWalletRequested()
    signal restoreRecoveryWalletRequested()

    property var compatibilityResult: ({})
    property string pendingRenameWalletName: ""
    property var selectedWalletKeys: []
    property var pendingDeleteWalletNames: []
    property bool hideZeroBalanceAddresses: false
    property bool hideZeroBip39RecoveryAddresses: false
    property int addressBookFilterRevision: 0
    property int walletListViewMode: 0
    property string walletSortKey: ""
    property bool walletSortAscending: true
    property string walletSimpleSortKey: ""
    property bool walletSimpleSortAscending: true
    property string walletDetailedSortKey: ""
    property bool walletDetailedSortAscending: true

    Component.onCompleted: NuService.refreshWalletStats()
    onVisibleChanged: if (visible) NuService.refreshWalletStats()

    function walletIndex(name) {
        const target = String(name)
        for (let i = 0; i < NuService.availableWallets.length; ++i) {
            if (String(NuService.availableWallets[i]) === target) return i
        }
        return -1
    }

    function walletIndexOrFirst(name) {
        const index = root.walletIndex(name)
        if (index >= 0) return index
        return NuService.availableWallets.length > 0 ? 0 : -1
    }

    function walletKey(name) {
        const value = String(name)
        return value.length === 0 ? "__default_wallet__" : value
    }

    function walletNameFromKey(key) {
        const value = String(key)
        return value === "__default_wallet__" ? "" : value
    }

    function walletLeafName(name) {
        const normalized = String(name).replace(/\\/g, "/")
        return normalized.indexOf("wallets/") === 0 ? normalized.substring(8) : normalized
    }

    function isRenameableWallet(name) {
        const value = String(name)
        return value.length > 0 && value !== "wallet.dat"
    }

    function isWalletLoaded(name) {
        const target = String(name)
        for (let i = 0; i < NuService.loadedWallets.length; ++i) {
            if (String(NuService.loadedWallets[i]) === target) return true
        }
        return false
    }

    function selectedWalletNames() {
        const names = []
        for (let i = 0; i < root.selectedWalletKeys.length; ++i) {
            names.push(root.walletNameFromKey(root.selectedWalletKeys[i]))
        }
        return names
    }

    function primarySelectedWalletName() {
        const names = root.selectedWalletNames()
        return names.length > 0 ? names[0] : ""
    }

    function selectedWalletSummary() {
        const names = root.selectedWalletNames()
        if (names.length === 0) return "No wallets selected."
        const labels = names.map(function(name) { return NuService.walletDisplayName(name) })
        return labels.join(", ")
    }

    function pendingDeleteWalletSummary() {
        if (root.pendingDeleteWalletNames.length === 0) return "No wallets selected."
        const labels = root.pendingDeleteWalletNames.map(function(name) { return NuService.walletDisplayName(name) })
        return labels.join(", ")
    }

    function deleteConfirmationPhrase() {
        return root.pendingDeleteWalletNames.length > 1 ? "MOVE WALLETS" : "MOVE WALLET"
    }

    function selectedLoadedWallets() {
        const out = []
        const names = root.selectedWalletNames()
        for (let i = 0; i < names.length; ++i) {
            if (root.isWalletLoaded(names[i])) out.push(names[i])
        }
        return out
    }

    function selectedNonDefaultWallets() {
        const out = []
        const names = root.selectedWalletNames()
        for (let i = 0; i < names.length; ++i) {
            if (root.isRenameableWallet(names[i])) out.push(names[i])
        }
        return out
    }

    function walletStatItems() {
        const stats = NuService.walletFileStats || []
        if (stats.length > 0) return stats
        const fallback = []
        for (let i = 0; i < NuService.availableWallets.length; ++i) {
            const name = String(NuService.availableWallets[i])
            const loaded = root.isWalletLoaded(name)
            const current = loaded && name === NuService.currentWalletName
            fallback.push({
                name: name,
                display: NuService.walletDisplayName(name),
                active: current,
                loaded: loaded,
                state: current ? "Current" : (loaded ? "Loaded" : "Available"),
                type: root.isRenameableWallet(name) ? "Unknown" : "BDB",
                total: current ? NuService.totalBalance : (loaded ? "Loading" : "Load to scan"),
                available: current ? NuService.availableBalance : (loaded ? "Loading" : "-"),
                pending: current ? NuService.pendingBalance : (loaded ? "Loading" : "-"),
                immature: current ? NuService.immatureBalance : (loaded ? "Loading" : "-"),
                transactions: current ? String(NuService.walletTransactionCount) : (loaded ? "Loading" : "-"),
                addressCount: current ? NuService.walletAddressCount : -1,
                nonZeroAddressCount: current ? NuService.walletNonZeroAddressCount : -1
            })
        }
        return fallback
    }

    function statValueText(value) {
        if (value === undefined || value === null) return "-"
        const numberValue = Number(value)
        if (!isNaN(numberValue) && numberValue < 0) return "Load to scan"
        return String(value)
    }

    function walletFileRows() {
        const out = []
        const stats = root.walletStatItems()
        for (let i = 0; i < stats.length; ++i) {
            const item = stats[i]
            const name = String(item.name === undefined ? "" : item.name)
            const active = NuService.walletSelected && name === NuService.currentWalletName
            const loaded = item.loaded === true || root.isWalletLoaded(name)
            const display = item.display === undefined ? NuService.walletDisplayName(name) : String(item.display)
            out.push({
                cells: root.walletListViewMode === 0
                       ? [
                           active ? "✓" : "",
                           display,
                           active ? "Current" : (loaded ? "Loaded" : String(item.state || "Available")),
                           String(item.type || (root.isRenameableWallet(name) ? "Unknown" : "BDB"))
                         ]
                       : [
                           active ? "✓" : "",
                           display,
                           active ? "Current" : (loaded ? "Loaded" : String(item.state || "Available")),
                           String(item.type || (root.isRenameableWallet(name) ? "Unknown" : "BDB")),
                           root.statValueText(item.total),
                           root.statValueText(item.available),
                           root.statValueText(item.pending),
                           root.statValueText(item.immature),
                           root.statValueText(item.transactions),
                           root.statValueText(item.addressCount),
                           root.statValueText(item.nonZeroAddressCount)
                         ],
                meta: { key: root.walletKey(name), name: name }
            })
        }
        return out
    }

    function walletTableColumns() {
        return root.walletListViewMode === 0
               ? ["Active", "Wallet", "State", "Type"]
               : ["Active", "Wallet", "State", "Type", "Total", "Available", "Pending", "Immature", "Txns", "Addrs", "Non-zero"]
    }

    function walletTableTypes() {
        return root.walletListViewMode === 0
               ? ["center", "text", "text", "center"]
               : ["center", "text", "text", "center", "amount", "amount", "amount", "amount", "number", "number", "number"]
    }

    function walletTableSortKeys() {
        return root.walletListViewMode === 0
               ? ["active", "wallet", "state", "type"]
               : ["active", "wallet", "state", "type", "total", "available", "pending", "immature", "transactions", "addresses", "nonZero"]
    }

    function walletTableTooltips() {
        return root.walletListViewMode === 0
               ? [
                   "Check mark means this wallet is the active wallet used by Home, Send, Receive, Transactions, and Wallet actions.",
                   "Wallet file or wallet directory. Default wallet (wallet.dat) is Core's legacy unnamed wallet.",
                   "Current is active. Loaded is open in the backend and ready for quick switching. Available is found on disk but not opened yet.",
                   "Storage format. BDB means Berkeley DB Legacy. SQL means SQLite (Modern). Unknown means Nu could not inspect the file while it is unloaded."
                 ]
               : [
                   "Check mark means this wallet is the active wallet.",
                   "Wallet file or wallet directory.",
                   "Loaded wallets are open in Core RPC. Available wallets are discovered on disk but not opened.",
                   "Storage format. BDB means Berkeley DB Legacy. SQL means SQLite (Modern). Unknown means Nu could not inspect the file while it is unloaded.",
                   "Total balance reported by the wallet when loaded.",
                   "Confirmed spendable balance reported by the wallet when loaded.",
                   "Unconfirmed balance reported by the wallet when loaded.",
                   "Immature generated balance reported by the wallet when loaded.",
                   "Wallet transaction count from getwalletinfo.",
                   "Known receive addresses returned by the wallet address scan.",
                   "Known receive addresses with a non-zero received amount."
                 ]
    }

    function walletTableMinimums() {
        return root.walletListViewMode === 0
               ? [58, 220, 102, 74]
               : [58, 220, 102, 74, 136, 112, 112, 112, 70, 84, 96]
    }

    function walletTableMaximums() {
        return root.walletListViewMode === 0
               ? [72, 900, 180, 120]
               : [72, 900, 180, 120, 210, 180, 180, 180, 110, 140, 150]
    }

    function walletTableWeights() {
        return root.walletListViewMode === 0
               ? [0.42, 3.2, 1.0, 0.6]
               : [0.42, 3.0, 1.0, 0.6, 1.4, 1.1, 1.1, 1.1, 0.72, 0.82, 0.9]
    }

    function applyWalletSortForCurrentView() {
        if (!walletFilesTable) return
        const viewKey = root.walletListViewMode === 0 ? root.walletSimpleSortKey : root.walletDetailedSortKey
        const viewAscending = root.walletListViewMode === 0 ? root.walletSimpleSortAscending : root.walletDetailedSortAscending
        if (viewKey.length > 0 && walletFilesTable.applyExternalSort(viewKey, viewAscending)) return
        if (root.walletSortKey.length > 0 && walletFilesTable.applyExternalSort(root.walletSortKey, root.walletSortAscending)) return
        walletFilesTable.sortColumn = -1
    }

    function openOrSelectPrimaryWallet() {
        const name = root.primarySelectedWalletName()
        if (root.isWalletLoaded(name)) NuService.setCurrentWallet(name)
        else NuService.loadWallet(name)
    }

    function openSelectedWallets() {
        const names = root.selectedWalletNames()
        if (names.length === 1) {
            root.openOrSelectPrimaryWallet()
            return
        }
        NuService.openWallets(names)
    }

    function closeSelectedWallets() {
        const names = root.selectedLoadedWallets()
        for (let i = 0; i < names.length; ++i) {
            if (names[i].length === 0 && NuService.currentWalletName !== "")
                NuService.setCurrentWallet("")
            NuService.closeWallet(names[i])
        }
    }

    function requestRenameSelectedWallet() {
        const names = root.selectedNonDefaultWallets()
        if (names.length !== 1) return
        root.pendingRenameWalletName = names[0]
        walletRenameName.text = root.walletLeafName(root.pendingRenameWalletName)
        walletRenameDialog.open()
    }

    function requestDeleteSelectedWallets() {
        const names = root.selectedNonDefaultWallets()
        if (names.length === 0) return
        root.pendingDeleteWalletNames = names
        walletDeleteDialog.open()
    }

    function walletNameExists(name) {
        const target = String(name).trim()
        for (let i = 0; i < NuService.availableWallets.length; ++i) {
            if (String(NuService.availableWallets[i]) === target) return true
        }
        return false
    }

    function proposedWalletNameIsValid(name) {
        const value = String(name).trim()
        const lower = value.toLowerCase()
        return value.length > 0
               && value.length <= 128
               && value !== "."
               && value !== ".."
               && value.indexOf("/") < 0
               && value.indexOf("\\") < 0
               && value.indexOf(":") < 0
               && value !== "wallet.dat"
               && !lower.endsWith(".bak")
               && !lower.endsWith(".bkp")
               && !lower.endsWith(".dat")
               && lower.indexOf("backup") < 0
               && lower.indexOf(" bkp") < 0
               && lower.indexOf(" copy ") < 0
               && !root.walletNameExists(value)
               && value !== root.walletLeafName(root.pendingRenameWalletName)
    }

    function loadedWalletText() {
        if (NuService.loadedWallets.length === 0) return "No wallets are loaded."
        const names = []
        for (let i = 0; i < NuService.loadedWallets.length; ++i) {
            const name = String(NuService.loadedWallets[i])
            names.push(NuService.walletDisplayName(name) + (name === NuService.currentWalletName ? " (current)" : ""))
        }
        return names.join(", ")
    }

    function compatibilityText() {
        const result = root.compatibilityResult || {}
        if (result.ok) {
            const lines = [result.kind || "Compatibility result"]
            if (result.current) lines.push("xpub/xprv: " + result.current)
            if (result.defcoin) lines.push("dfcp/dfcv: " + result.defcoin)
            if (result.canonical) lines.push("Canonical M... P2SH: " + result.canonical)
            if (result.legacy3) lines.push("Legacy 3... P2SH: " + result.legacy3)
            if (result.tool) lines.push("Tool 9/A... P2SH: " + result.tool)
            if (result.note) lines.push(result.note)
            return lines.join("\n")
        }
        return result.error || "Paste an xpub/xprv, dfcp/dfcv, or P2SH address, then convert."
    }

    function addressBookTableRows() {
        const out = []
        for (let i = 0; i < NuService.addressBook.length; ++i) {
            const row = NuService.addressBook[i]
            const label = row.length > 0 ? row[0] : ""
            const address = row.length > 1 ? row[1] : ""
            const type = row.length > 2 ? row[2] : ""
            const received = row.length > 3 ? row[3] : ""
            const receivedValue = parseFloat(String(received).replace(/[^0-9.\-]/g, ""))
            const labelText = String(label).toLowerCase()
            const isRecoveryAddress = labelText.indexOf("bip39 recovery") >= 0
                                      || labelText.indexOf("recovery phrase") >= 0
                                      || labelText.indexOf("mnemonic") >= 0
            const zeroReceived = isNaN(receivedValue) || receivedValue <= 0
            if (root.hideZeroBalanceAddresses && zeroReceived)
                continue
            if (root.hideZeroBip39RecoveryAddresses
                    && isRecoveryAddress
                    && zeroReceived)
                continue
            out.push({
                cells: ["", label, address, type, received],
                meta: { address: address }
            })
        }
        return out
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Wallet"
        detail: "Manage wallet files, recovery phrases, passphrases, addresses, and signatures."
    }

    NuTabBar {
        id: walletTabs
        Layout.fillWidth: true
        NuTabButton { text: "Files" }
        NuTabButton { text: "Recovery" }
        NuTabButton { text: "Security" }
        NuTabButton { text: "Addresses" }
        NuTabButton { text: "Messages" }
        NuTabButton { text: "Compatibility" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: walletTabs.currentIndex

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm

                        Label {
                            Layout.fillWidth: true
                            text: NuService.walletSelected
                                  ? "Active wallet: " + NuService.walletDisplayName(NuService.currentWalletName)
                                  : "Active wallet: none selected"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.loadedWalletText()
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: NuTokens.spaceXl
                    rowSpacing: NuTokens.spaceSm
                    NuMetricRow { label: "Total"; value: NuService.totalBalance }
                    NuMetricRow { label: "Available"; value: NuService.availableBalance }
                    NuMetricRow { label: "Pending"; value: NuService.pendingBalance }
                    NuMetricRow { label: "Immature"; value: NuService.immatureBalance }
                    NuMetricRow { label: "Transactions"; value: NuService.walletTransactionCount }
                    NuMetricRow {
                        label: "Addrs"
                        value: String(NuService.walletAddressCount)
                        helpText: "Known receive addresses found by the wallet stats scan. Press Rescan stats after imports or recovery."
                    }
                    NuMetricRow {
                        label: "Non-zero"
                        value: String(NuService.walletNonZeroAddressCount)
                        helpText: "Known receive addresses with a non-zero received amount."
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Select wallets in the list, then run actions from the toolbar. Click to select one wallet, Cmd-click to select separate wallets, or Shift-click to select a range."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuActionButton {
                        text: "Create..."
                        width: 120
                        primary: true
                        helpText: "Create a wallet with Litecoin Core-style wallet options."
                        onClicked: root.createWalletRequested()
                    }
                    NuActionButton {
                        text: "Open selected"
                        width: 140
                        enabled: root.selectedWalletKeys.length > 0
                        helpText: "Open selected wallets one after another. If one wallet is selected, Nu opens or selects it. If several are selected, Nu queues the opens and makes the last selected wallet active."
                        onClicked: root.openSelectedWallets()
                    }
                    NuActionButton {
                        text: "Rename..."
                        width: 115
                        enabled: root.selectedNonDefaultWallets().length === 1
                        helpText: "Rename one selected non-default wallet."
                        onClicked: root.requestRenameSelectedWallet()
                    }
                    NuActionButton {
                        text: "Backup active"
                        width: 132
                        enabled: NuService.walletSelected
                        helpText: "Back up the active wallet."
                        onClicked: NuService.backupWallet()
                    }
                    NuActionButton {
                        text: "Close selected"
                        width: 138
                        enabled: root.selectedLoadedWallets().length > 0
                        helpText: "Unload the selected loaded wallet or wallets without deleting wallet data."
                        onClicked: root.closeSelectedWallets()
                    }
                    NuActionButton {
                        text: "Close all"
                        width: 105
                        enabled: NuService.loadedWallets.length > 0
                        helpText: "Unload every loaded wallet without deleting wallet data."
                        onClicked: NuService.closeAllWallets()
                    }
                    NuActionButton {
                        text: "Delete selected..."
                        width: 148
                        enabled: root.selectedNonDefaultWallets().length > 0
                        helpText: "Move selected non-default wallets out of the active wallet list after typed confirmation."
                        onClicked: root.requestDeleteSelectedWallets()
                    }
                    NuActionButton {
                        text: "Rescan stats"
                        width: 122
                        helpText: "Refresh wallet balances, transaction counts, and known receive-address counts. This is a lightweight stats refresh, not a blockchain rescan."
                        onClicked: NuService.refreshWalletStats()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    NuTabBar {
                        id: walletViewToggle
                        Layout.preferredWidth: 224
                        currentIndex: root.walletListViewMode
                        NuTabButton { text: "Simple" }
                        NuTabButton { text: "Detailed" }
                        onCurrentIndexChanged: {
                            root.walletListViewMode = currentIndex
                            Qt.callLater(function() {
                                root.applyWalletSortForCurrentView()
                                walletFilesTable.forceResetColumnWidths()
                            })
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: walletViewToggle.currentIndex === 0
                              ? "Loaded wallets are open in the backend; available wallets are discovered on disk."
                              : "Detailed stats are shown for loaded wallets. Load a wallet before scanning its exact stats."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        elide: Text.ElideRight
                    }
                }

                NuDataTable {
                    id: walletFilesTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: root.walletListViewMode === 0 ? "walletFileListSimple" : "walletFileListDetailed"
                    columns: root.walletTableColumns()
                    columnTypes: root.walletTableTypes()
                    sortColumnKeys: root.walletTableSortKeys()
                    columnTooltips: root.walletTableTooltips()
                    rows: root.walletFileRows()
                    columnWeights: root.walletTableWeights()
                    columnMinimums: root.walletTableMinimums()
                    columnMaximums: root.walletTableMaximums()
                    alwaysShowHorizontalScrollBar: root.walletListViewMode === 1
                    rowSelectionEnabled: true
                    plainClickSelectsRows: true
                    rowKeyMetaField: "key"
                    selectedRowKeys: root.selectedWalletKeys
                    emptyText: "Wallet files appear after RPC connects."
                    onSortChanged: (column, ascending, key) => {
                        root.walletSortKey = key
                        root.walletSortAscending = ascending
                        if (root.walletListViewMode === 0) {
                            root.walletSimpleSortKey = key
                            root.walletSimpleSortAscending = ascending
                        } else {
                            root.walletDetailedSortKey = key
                            root.walletDetailedSortAscending = ascending
                        }
                    }
                    onRowSelectionChanged: (keys) => root.selectedWalletKeys = keys
                    onRowActivated: (row) => {
                        if (row && row.meta) {
                            root.selectedWalletKeys = [row.meta.key]
                            root.openOrSelectPrimaryWallet()
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Default wallet (wallet.dat) is Core's legacy top-level wallet. Nu lists it as Default wallet (wallet.dat), lets you open/select and back it up, and protects it from rename/delete here because its RPC wallet name is empty and older Core code treats it specially."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                Label {
                    Layout.fillWidth: true
                    text: "BIP39 recovery phrase, mnemonic phrase, and seed phrase all refer to the ordered words used to recreate keys. Nu validates BIP39 English checksums and never stores the phrase after the dialog closes."
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                Label {
                    Layout.fillWidth: true
                    text: "If a recovery phrase leaks during import, and it came from a multi-coin wallet such as Coinomi, every coin wallet derived from that phrase could be exposed. Keep the phrase private. For the strongest practice with high-value phrases, use an offline or freshly trusted machine: disconnect before typing or pasting, recover or sweep the Defcoin wallet, and move any other coins tied to that phrase to new wallet addresses before reusing the phrase on a connected machine. If you are confident the machine, clipboard, and sync tools are not compromised, that level of isolation may not be necessary."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuActionButton {
                        text: "Create Wallet w/ Recovery Phrase..."
                        Layout.preferredWidth: 310
                        helpText: "Generate a new 12-word BIP39 English phrase and create a Nu/Core HD wallet."
                        onClicked: root.createRecoveryWalletRequested()
                    }
                    NuActionButton {
                        text: "Restore Wallet fr. Recovery Phrase..."
                        Layout.preferredWidth: 310
                        primary: true
                        helpText: "Restore from 12, 15, 18, 21, or 24 BIP39 words, including Coinomi/Ian Coleman-style external scans."
                        onClicked: root.restoreRecoveryWalletRequested()
                    }
                    Item { Layout.fillWidth: true }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: NuTokens.lineSubtle }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: NuTokens.spaceLg
                    rowSpacing: NuTokens.spaceMd

                    Label { text: "Nu/Core HD"; color: NuTokens.textPrimary; font.pixelSize: NuTokens.fontBody; font.weight: Font.DemiBold }
                    Label {
                        Layout.fillWidth: true
                        text: "Use for phrases created by Nu. The phrase sets the wallet HD seed."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                        wrapMode: Text.WordWrap
                    }

                    Label { text: "Advanced external scan"; color: NuTokens.textPrimary; font.pixelSize: NuTokens.fontBody; font.weight: Font.DemiBold }
                    Label {
                        Layout.fillWidth: true
                        text: "Use for Coinomi, Ian Coleman, or other external phrase recovery. Preview derived addresses first, choose the derivation path and WIF mode, then import a bounded range with one rescan."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                        wrapMode: Text.WordWrap
                    }

                    Label { text: "WIF modes"; color: NuTokens.textPrimary; font.pixelSize: NuTokens.fontBody; font.weight: Font.DemiBold }
                    Label {
                        Layout.fillWidth: true
                        text: "Current Defcoin v1.0.0+ private keys render as T...; old v0.22/Ian Coleman references can render as Q... for comparison."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                Label {
                    text: "Passphrase protection"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: NuService.walletEncrypted
                          ? "This wallet is encrypted. You can change its passphrase, but Core wallets cannot be unencrypted in place."
                          : "This wallet is not encrypted. Encrypt it before relying on passphrase protection."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                NuActionButton {
                    text: NuService.walletEncrypted ? "Change passphrase..." : "Encrypt wallet..."
                    Layout.preferredWidth: 210
                    primary: !NuService.walletEncrypted
                    enabled: NuService.walletSelected
                    helpText: "Encrypt this wallet or change the current wallet passphrase."
                    onClicked: walletSecurityDialog.open()
                }

                Label {
                    Layout.fillWidth: true
                    text: "Removing wallet encryption is not supported in place. To end up with an unencrypted wallet, make verified backups, create or restore into a new unencrypted wallet, then move funds or perform an expert key migration and verify the result before retiring the encrypted wallet."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Address book"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "Default currency unit is DFC. Address labels are shared with Send and Receive."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    NuCheckBox {
                        text: "Hide zero-received addresses"
                        checked: root.hideZeroBalanceAddresses
                        helpText: "Hide every address entry whose received amount is zero, including BIP39 recovery addresses. This only filters the table view; it does not remove addresses from the wallet."
                        onToggled: {
                            root.hideZeroBalanceAddresses = checked
                            root.addressBookFilterRevision += 1
                            addressBookTable.clearRowSelection()
                        }
                    }
                    NuCheckBox {
                        text: "Hide zero-received recovery addresses"
                        checked: root.hideZeroBalanceAddresses || root.hideZeroBip39RecoveryAddresses
                        enabled: !root.hideZeroBalanceAddresses
                        helpText: root.hideZeroBalanceAddresses
                                  ? "Already covered by Hide zero-received addresses."
                                  : "Hide only zero-received imported recovery phrase / BIP39 address entries. This filters the table view and does not remove private keys or addresses from the wallet."
                        onToggled: {
                            if (!root.hideZeroBalanceAddresses) {
                                root.hideZeroBip39RecoveryAddresses = checked
                                root.addressBookFilterRevision += 1
                                addressBookTable.clearRowSelection()
                            }
                        }
                    }
                    NuActionButton {
                        text: "Hide imported zero-rec'd"
                        Layout.preferredWidth: 190
                        helpText: "Quickly hide zero-received BIP39 recovery/import rows. Nu keeps the wallet records intact so funds cannot be lost by pruning the wrong address."
                        onClicked: {
                            root.hideZeroBip39RecoveryAddresses = true
                            root.addressBookFilterRevision += 1
                            addressBookTable.clearRowSelection()
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                NuDataTable {
                    id: addressBookTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tableId: "walletAddressBook"
                    columns: ["", "Label", "Address", "Type", "Received"]
                    columnTypes: ["action", "text", "address", "text", "amount"]
                    columnTooltips: [
                        "Inspect this address in the configured blockchain explorer.",
                        "Wallet label used to recognize this contact or receive address.",
                        "Wallet address. Select and copy the full value exactly when sharing it.",
                        "Address-book purpose, such as contact or receive.",
                        "Total amount received by this wallet address."
                    ]
                    rows: {
                        root.addressBookFilterRevision
                        root.addressBookTableRows()
                    }
                    columnWeights: [0.1, 1.4, 3.5, 0.85, 1.1]
                    columnMinimums: [44, 140, 320, 90, 150]
                    columnMaximums: [44, 840, 960, 260, 240]
                    rowSelectionEnabled: true
                    rowKeyMetaField: "address"
                    emptyText: "Wallet address book entries appear after RPC connects."
                    onRowActivated: (row) => NuService.openAddressInExplorer(row && row.meta ? row.meta.address : "")
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                Label {
                    Layout.fillWidth: true
                    text: "Sign and verify messages with wallet addresses."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuActionButton {
                        text: "Sign message..."
                        Layout.preferredWidth: 170
                        enabled: NuService.walletSelected
                        helpText: "Sign a message with a wallet address."
                        onClicked: signDialog.open()
                    }
                    NuActionButton {
                        text: "Verify message..."
                        Layout.preferredWidth: 180
                        helpText: "Verify an address, message, and signature."
                        onClicked: verifyDialog.open()
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                Label {
                    Layout.fillWidth: true
                    text: "Convert Defcoin extended-key display forms and P2SH address encodings. Nu accepts xpub/xprv and dfcp/dfcv, keeps generated P2SH addresses as canonical M..., and can show M... equivalents for older 3... or tool 9/A... P2SH addresses."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuTextField {
                        id: compatibilityInput
                        Layout.fillWidth: true
                        placeholderText: "xpub, xprv, dfcp, dfcv, 3..., 9..., A..., or M..."
                        helpText: "Private extended keys are sensitive. Convert only on a computer you control."
                        onAccepted: root.compatibilityResult = NuService.convertCompatibilityEncoding(text)
                        Keys.onReturnPressed: root.compatibilityResult = NuService.convertCompatibilityEncoding(text)
                        Keys.onEnterPressed: root.compatibilityResult = NuService.convertCompatibilityEncoding(text)
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: "Convert"
                        helpText: "Show accepted equivalent formats for the pasted key or address."
                        onClicked: root.compatibilityResult = NuService.convertCompatibilityEncoding(compatibilityInput.text)
                    }
                }

                TextArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextArea.WrapAnywhere
                    text: root.compatibilityText()
                    color: root.compatibilityResult && root.compatibilityResult.ok ? NuTokens.textPrimary : NuTokens.textSecondary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                    background: Rectangle {
                        color: NuTokens.backgroundBase
                        border.color: NuTokens.lineSubtle
                        radius: NuTokens.radiusSmall
                    }
                }
            }
        }
    }

    NuDialog {
        id: walletSecurityDialog
        title: "Wallet security"
        acceptText: NuService.walletEncrypted ? "Change passphrase" : "Encrypt wallet"
        dialogWidth: 640

        Label {
            Layout.fillWidth: true
            text: NuService.walletEncrypted
                  ? "This wallet is encrypted. Enter the current passphrase and a new passphrase to change it."
                  : "This wallet is not encrypted. Add a passphrase to encrypt the wallet file."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: oldPassphrase
            Layout.fillWidth: true
            visible: NuService.walletEncrypted
            Layout.preferredHeight: visible ? implicitHeight : 0
            echoMode: TextInput.Password
            placeholderText: "Current passphrase"
        }
        NuTextField {
            id: newPassphrase
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: NuService.walletEncrypted ? "New passphrase" : "Passphrase"
            helpText: "Use a long passphrase. Losing it can make wallet funds permanently inaccessible."
        }

        Label {
            Layout.fillWidth: true
            text: "Removing wallet encryption is not supported in place. Create or restore into a new unencrypted wallet only after verified backups and expert review."
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        onAccepted: NuService.walletEncrypted
                    ? NuService.changeWalletPassphrase(oldPassphrase.text, newPassphrase.text)
                    : NuService.encryptWallet(newPassphrase.text)
        onClosed: {
            oldPassphrase.text = ""
            newPassphrase.text = ""
        }
    }

    NuDialog {
        id: walletRenameDialog
        title: "Rename wallet"
        acceptText: "Rename"
        cancelText: "Cancel"
        dialogWidth: 640
        acceptEnabled: root.proposedWalletNameIsValid(walletRenameName.text)

        beforeAccept: function() {
            return root.pendingRenameWalletName.length > 0
                   && root.proposedWalletNameIsValid(walletRenameName.text)
        }

        Label {
            Layout.fillWidth: true
            text: "Rename a non-default wallet directory. Nu closes and reloads the wallet if needed. This does not change wallet keys, addresses, labels, transactions, or funds."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: "Selected wallet: " + NuService.walletDisplayName(root.pendingRenameWalletName)
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: walletRenameName
            Layout.fillWidth: true
            placeholderText: "New wallet name"
            helpText: "Use a unique folder-style wallet name up to 128 characters. Slashes, colons, backup suffixes, copy labels, and .dat filenames are blocked."
            onAccepted: walletRenameDialog.requestAccept()
            Keys.onReturnPressed: walletRenameDialog.requestAccept()
            Keys.onEnterPressed: walletRenameDialog.requestAccept()
        }

        Label {
            Layout.fillWidth: true
            text: root.walletNameExists(walletRenameName.text.trim())
                  ? "A wallet with that name already exists."
                  : (walletRenameName.text.trim().length > 128
                     ? "Wallet names can be up to 128 characters."
                     : (walletRenameName.text.trim() === root.walletLeafName(root.pendingRenameWalletName)
                        ? "Enter a different wallet name."
                        : "Back up important wallets before renaming them."))
            color: root.proposedWalletNameIsValid(walletRenameName.text) ? NuTokens.textSecondary : NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        onAccepted: NuService.renameWallet(root.pendingRenameWalletName, walletRenameName.text)
        onClosed: {
            walletRenameName.text = ""
            root.pendingRenameWalletName = ""
        }
    }

    NuDialog {
        id: walletDeleteDialog
        title: root.pendingDeleteWalletNames.length > 1 ? "Delete wallets" : "Delete wallet"
        acceptText: root.pendingDeleteWalletNames.length > 1 ? "Move Wallets" : "Move Wallet"
        cancelText: "Cancel"
        dialogWidth: 700
        acceptEnabled: walletDeleteConfirm.text === root.deleteConfirmationPhrase()

        beforeAccept: function() {
            return root.pendingDeleteWalletNames.length > 0
                   && walletDeleteConfirm.text === root.deleteConfirmationPhrase()
        }

        Label {
            Layout.fillWidth: true
            text: root.pendingDeleteWalletNames.length > 1
                  ? "This is a destructive wallet-file cleanup action. Nu will close the selected wallets if needed, then move each wallet directory into a timestamped Deleted Wallets folder inside the Defcoin data directory. This is not a secure wipe, but those wallets will no longer appear as active Nu wallets."
                  : "This is the destructive wallet-file cleanup action. Nu will close the selected wallet if needed, then move its wallet directory into a timestamped Deleted Wallets folder inside the Defcoin data directory. This is not a secure wipe, but the wallet will no longer appear as an active Nu wallet."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: (root.pendingDeleteWalletNames.length > 1 ? "Selected wallets: " : "Selected wallet: ") + root.pendingDeleteWalletSummary()
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 5
            columnSpacing: NuTokens.spaceMd
            rowSpacing: NuTokens.spaceXs

            NuMetricRow { label: "Total"; value: NuService.totalBalance }
            NuMetricRow { label: "Available"; value: NuService.availableBalance }
            NuMetricRow { label: "Pending"; value: NuService.pendingBalance }
            NuMetricRow { label: "Immature"; value: NuService.immatureBalance }
            NuMetricRow { label: "Transactions"; value: NuService.walletTransactionCount }
        }

        Label {
            Layout.fillWidth: true
            text: root.pendingDeleteWalletNames.length > 1
                  ? "The summary above is for the active wallet only. Select/open any wallet first if you want its exact balance and transaction summary before moving it."
                  : (root.pendingDeleteWalletNames.length === 1 && root.pendingDeleteWalletNames[0] === NuService.currentWalletName
                  ? "The summary above is for the wallet selected for deletion."
                  : "Open/select this wallet first if you want Nu to refresh its exact balance and transaction summary before moving it.")
            color: root.pendingDeleteWalletNames.length === 1 && root.pendingDeleteWalletNames[0] === NuService.currentWalletName ? NuTokens.textSecondary : NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: "Before continuing, make sure selected wallets are backed up and that you are not moving the only copy of private keys for funds you still need. To confirm, type " + root.deleteConfirmationPhrase() + "."
            color: NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: walletDeleteConfirm
            Layout.fillWidth: true
            placeholderText: root.deleteConfirmationPhrase()
            helpText: "Typed confirmation is required before Nu moves this wallet out of the active wallet list."
            onAccepted: walletDeleteDialog.requestAccept()
            Keys.onReturnPressed: walletDeleteDialog.requestAccept()
            Keys.onEnterPressed: walletDeleteDialog.requestAccept()
        }

        onAccepted: {
            for (let i = 0; i < root.pendingDeleteWalletNames.length; ++i) {
                NuService.deleteWallet(root.pendingDeleteWalletNames[i])
            }
        }
        onClosed: {
            walletDeleteConfirm.text = ""
            root.pendingDeleteWalletNames = []
        }
    }

    NuDialog {
        id: signDialog
        title: "Sign message"
        acceptText: "Sign"
        dialogWidth: 620

        NuTextField {
            id: signAddress
            Layout.fillWidth: true
            placeholderText: "Wallet address"
        }
        TextArea {
            id: signMessage
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            placeholderText: "Message"
            color: NuTokens.textPrimary
            selectByMouse: true
            wrapMode: TextArea.Wrap
            background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
        }

        onAccepted: NuService.signMessage(signAddress.text, signMessage.text)
        onClosed: signMessage.text = ""
    }

    NuDialog {
        id: verifyDialog
        title: "Verify message"
        acceptText: "Verify"
        dialogWidth: 640

        NuTextField {
            id: verifyAddress
            Layout.fillWidth: true
            placeholderText: "Address"
        }
        NuTextField {
            id: verifySignature
            Layout.fillWidth: true
            placeholderText: "Signature"
        }
        TextArea {
            id: verifyMessage
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            placeholderText: "Message"
            color: NuTokens.textPrimary
            selectByMouse: true
            wrapMode: TextArea.Wrap
            background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
        }

        onAccepted: NuService.verifyMessage(verifyAddress.text, verifySignature.text, verifyMessage.text)
        onClosed: verifyMessage.text = ""
    }
}
