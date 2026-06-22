import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

Item {
    id: root

    property bool active: false
    property bool embedded: false
    property bool hideArt: false
    property bool bip38Encrypt: false
    property bool allowWeakBip38Passphrase: false
    property bool distributeAfterPrint: false
    property bool showAdvanced: false
    property int addressesToGenerate: 1
    property int addressesPerPage: 3
    property int printForm: 0
    property string printedAmount: ""
    property string bip38Passphrase: ""
    property string entropyPool: ""
    property var fundingAmounts: ({})
    property int entropyScore: 0
    property int entropySamples: 0
    property bool entropyCaptureActive: false
    property double lastMouseEntropyMs: 0
    property string lastMouseEntropySample: ""
    property string lastKeyVisual: ""
    property int openStage: NuService.paperWalletReady ? 5 : (entropyReady ? 4 : 1)
    property bool entropyCompletionFocused: false
    readonly property int entropyTarget: 3072
    readonly property int maxWalletsPerRun: 100
    readonly property int minBip38PassphraseChars: 12
    readonly property int entropyPercent: Math.min(100, Math.round(entropyScore * 100 / entropyTarget))
    readonly property bool entropyReady: entropyScore >= entropyTarget
    readonly property bool bip38PassphraseReady: !bip38Encrypt || allowWeakBip38Passphrase || bip38Passphrase.trim().length >= minBip38PassphraseChars
    readonly property bool generationEntropySatisfied: entropyReady || NuService.paperWalletReady
    readonly property bool canGeneratePaperWallet: generationEntropySatisfied && NuService.rpcConnected && bip38PassphraseReady
    readonly property bool compact: width > 0 && width < 1180
    readonly property bool selectedDesignDoubleSided: printForm === 2 || printForm === 4
    readonly property url coinSource: "../../assets/brand/defcoin-v26-coin.png"
    readonly property string keyLabel: NuService.paperWalletWif.indexOf("6P") === 0 ? "Encrypted Private Key (BIP38 secret text phrase is also required)" : "Private key (WIF)"
    property var previewPageSources: []
    property bool previewLoading: false
    property int previewRenderSerial: 0
    property string previewRenderKey: ""
    property string previewRenderedKey: ""
    property real previewZoom: 1.0
    property real popoutPreviewZoom: 1.0
    readonly property string selectedDesignName: allDesignNames[Math.max(0, Math.min(printForm, allDesignNames.length - 1))]
    readonly property var allDesignNames: [
        "Design 1 - Full sheet strips (single-sided)",
        "Design 2 - Full-width tri-fold (single-sided)",
        "Design 3 - Avery 5011 place cards (double-sided)",
        "Design 4 - Public/private QR cards (single-sided)",
        "Design 5 - Defcoin Bulk two-page (double-sided)"
    ]
    readonly property var visibleDesignNames: [
        allDesignNames[0]
    ]
    readonly property string entropyProgressText: entropyReady
                                                  ? "Entropy ready - " + entropySamples + " local input samples mixed with system cryptographic randomness."
                                                  : entropyScore + " / " + entropyTarget + " entropy points collected."

    function addEntropy(kind, sample) {
        if (!entropyCaptureActive)
            return
        if (entropyReady)
            return
        const value = kind + ":" + sample + ":" + Date.now() + ":" + entropySamples
        entropyPool = entropyPool + "|" + value
        if (entropyPool.length > 65536)
            entropyPool = entropyPool.substring(entropyPool.length - 65536)
        entropySamples += 1
        entropyScore = Math.min(entropyTarget, entropyScore + (kind === "key" ? 8 : 3))
        if (entropyReady)
            entropyCaptureActive = false
    }

    function addMouseEntropy(mouse) {
        if (!entropyCaptureActive || !root.active)
            return
        const now = Date.now()
        const sample = Math.round(mouse.x) + "," + Math.round(mouse.y) + "," + mouse.buttons
        if (now - lastMouseEntropyMs < 10 && sample === lastMouseEntropySample)
            return
        lastMouseEntropyMs = now
        lastMouseEntropySample = sample
        addEntropy("mouse", sample + "," + Math.round(root.width) + "x" + Math.round(root.height))
    }

    function addKeyEntropy(event) {
        if (!entropyCaptureActive || !root.active)
            return
        if (event.isAutoRepeat)
            return
        const keyText = event.text && event.text.length > 0 ? event.text : ""
        lastKeyVisual = keyText.length > 0 ? keyText : ""
        addEntropy("key", event.key + ":" + keyText + ":" + event.modifiers)
        event.accepted = true
    }

    function resetEntropy() {
        entropyPool = ""
        entropyScore = 0
        entropySamples = 0
        entropyCaptureActive = false
        lastMouseEntropyMs = 0
        lastMouseEntropySample = ""
        lastKeyVisual = ""
    }

    function previewInputsKey() {
        const entries = NuService.paperWalletEntries || []
        const firstEntry = entries.length > 0 ? entries[0] : ({})
        const firstAddress = firstEntry && firstEntry.address !== undefined ? String(firstEntry.address) : ""
        const firstKey = firstEntry && firstEntry.key !== undefined ? String(firstEntry.key).substring(0, 16) : ""
        return [
            printForm,
            addressesToGenerate,
            addressesPerPage,
            hideArt ? 1 : 0,
            printedAmount,
            NuService.paperWalletReady ? 1 : 0,
            entries.length,
            firstAddress,
            firstKey
        ].join("|")
    }

    function refreshPreviewPages(force) {
        if (force === undefined)
            force = false
        const nextKey = previewInputsKey()
        if (!force && nextKey === previewRenderKey && (previewLoading || previewPageSources.length > 0))
            return
        previewRenderKey = nextKey
        previewRenderSerial += 1
        previewLoading = true
        previewRenderTimer.restart()
    }

    function renderPreviewPagesNow() {
        const token = previewRenderSerial
        previewPageSources = NuService.paperWalletPreviewPageSources(printForm,
                                                                    addressesToGenerate,
                                                                    addressesPerPage,
                                                                    hideArt,
                                                                    printedAmount)
        if (token === previewRenderSerial) {
            previewLoading = false
            previewRenderedKey = previewRenderKey
        }
    }

    function scrollStageIntoView(item) {
        if (!item || !paperScroll.contentItem)
            return
        Qt.callLater(function() {
            if (!paperScroll.contentItem)
                return
            paperScroll.contentItem.contentY = Math.max(0, item.y - NuTokens.spaceMd)
        })
    }

    function applyDesignDefaults(index) {
        if (index !== 0)
            index = 0
        printForm = index
        if (index === 2) {
            addressesPerPage = 6
        } else if (index === 4) {
            addressesPerPage = 2
        } else {
            addressesPerPage = 3
        }
        addressesToGenerate = Math.max(1, Math.min(maxWalletsPerRun, addressesToGenerate))
        root.refreshPreviewPages(true)
    }

    function paperEntry(index) {
        if (!NuService.paperWalletReady)
            return ({})
        const entries = NuService.paperWalletEntries || []
        if (index >= 0 && index < entries.length)
            return entries[index]
        return ({})
    }

    function paperEntryText(entry, key, placeholder) {
        const value = entry && entry[key] !== undefined && entry[key] !== null ? String(entry[key]) : ""
        return value.length > 0 ? value : placeholder
    }

    function paperAmount(index) {
        const stored = root.fundingAmounts[String(index)]
        if (stored !== undefined)
            return String(stored)
        const cosmetic = String(root.printedAmount).replace(/DFC/ig, "").trim()
        return cosmetic
    }

    function setPaperAmount(index, value) {
        const next = {}
        const existing = root.fundingAmounts || {}
        for (const key in existing)
            next[key] = existing[key]
        next[String(index)] = value
        root.fundingAmounts = next
    }

    function fundingRows() {
        const rows = []
        const entries = NuService.paperWalletEntries || []
        for (let i = 0; i < entries.length; ++i) {
            const address = root.paperEntryText(entries[i], "address", "")
            const amount = root.paperAmount(i).trim()
            if (address.length > 0 && amount.length > 0)
                rows.push({ address: address, amount: amount })
        }
        return rows
    }

    function fundingTotalText() {
        const rows = root.fundingRows()
        let total = 0
        for (let i = 0; i < rows.length; ++i) {
            const amount = Number(rows[i].amount)
            if (isNaN(amount) || amount <= 0)
                return "Enter positive DFC amounts before sending."
            total += amount
        }
        return rows.length + " output" + (rows.length === 1 ? "" : "s") + ", " + Number(total).toFixed(8) + " DFC total"
    }

    function canFundPaperWallets() {
        if (!NuService.paperWalletReady || !NuService.walletSelected)
            return false
        const rows = root.fundingRows()
        if (rows.length === 0)
            return false
        for (let i = 0; i < rows.length; ++i) {
            const amount = Number(rows[i].amount)
            if (isNaN(amount) || amount <= 0)
                return false
        }
        return true
    }

    function generatePaperWallet() {
        NuService.generatePaperWallets(addressesToGenerate,
                                       addressesPerPage,
                                       hideArt,
                                       bip38Encrypt,
                                       bip38Passphrase,
                                       allowWeakBip38Passphrase,
                                       entropyPool,
                                       printedAmount,
                                       printForm)
        root.fundingAmounts = ({})
        if (bip38Encrypt)
            bip38Passphrase = ""
        resetEntropy()
    }

    function generateDisabledReason() {
        if (!NuService.rpcConnected)
            return "Connect to the local backend before generating."
        if (!generationEntropySatisfied)
            return "Create entropy before generating printable private keys."
        if (bip38Encrypt && !bip38PassphraseReady)
            return "BIP38 passphrase is not strong enough for wallet generation unless weak phrases are enabled."
        return NuService.paperWalletReady
               ? "Ready to regenerate the printable sheet with the current settings."
               : NuService.paperWalletStatus
    }

    function openPreviewPopoutForUiSelfTest() {
        paperWalletPopout.visible = true
        paperWalletPopout.raise()
        paperWalletPopout.requestActivate()
    }

    function closePreviewPopoutForUiSelfTest() {
        paperWalletPopout.visible = false
    }

    function statusForStage(stage) {
        if (stage < 3)
            return "Ready"
        if (stage === 3)
            return entropyReady ? "Complete" : entropyPercent + "%"
        if (stage === 4)
            return NuService.paperWalletReady ? "Generated" : "Waiting"
        if (stage === 5)
            return NuService.paperWalletReady ? "Ready" : "Preview"
        if (stage === 6)
            return NuService.paperWalletReady ? "Ready" : "Waiting"
        return "Planned"
    }

    function previewStatusText() {
        if (previewLoading)
            return "Generating sheet preview..."
        if (!NuService.paperWalletReady)
            return "Preview is printable for alignment testing, but keys are not ready yet."
        return NuService.paperWalletEntries.length + " generated; " + (root.selectedDesignDoubleSided ? "front/back preview shown." : "single-sided preview shown.")
    }

    Keys.onPressed: (event) => {
        if (root.active && root.entropyCaptureActive && !bip38PassphraseField.activeFocus && !amountField.activeFocus)
            root.addKeyEntropy(event)
    }

    Component.onCompleted: {
        if (printForm !== 0)
            printForm = 0
        forceActiveFocus()
        refreshPreviewPages(true)
    }
    onActiveChanged: if (active) forceActiveFocus()
    onEntropyReadyChanged: {
        if (entropyReady && !entropyCompletionFocused) {
            entropyCompletionFocused = true
            openStage = 4
            scrollStageIntoView(stage4Card)
        } else if (!entropyReady) {
            entropyCompletionFocused = false
        }
    }
    onAddressesToGenerateChanged: refreshPreviewPages()
    onAddressesPerPageChanged: refreshPreviewPages()
    onHideArtChanged: refreshPreviewPages()
    onPrintedAmountChanged: refreshPreviewPages()
    onPrintFormChanged: refreshPreviewPages()

    Connections {
        target: NuService
        function onPaperWalletGenerated() {
            openStage = 5
            printOffer.open()
            root.refreshPreviewPages(true)
        }
        function onWalletChanged() {
            root.refreshPreviewPages()
        }
    }

    Timer {
        id: previewRenderTimer
        interval: 120
        repeat: false
        onTriggered: root.renderPreviewPagesNow()
    }

    MouseArea {
        id: viewEntropyMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        z: 10
        onPositionChanged: (mouse) => {
            if (root.entropyCaptureActive)
                root.addMouseEntropy(mouse)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: NuTokens.spaceLg

        NuPageHeader {
            Layout.fillWidth: true
            visible: !root.embedded
            Layout.preferredHeight: visible ? implicitHeight : 0
            title: "Paper Wallet"
            detail: "Create printable Defcoin paper wallets locally. Private keys stay in memory only for this session."
        }

        RowLayout {
            id: paperWalletBody
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: NuTokens.spaceLg

            ScrollView {
                id: paperScroll
                Layout.fillHeight: true
                Layout.fillWidth: root.compact
                Layout.preferredWidth: root.compact ? paperWalletBody.width : 540
                Layout.maximumWidth: root.compact ? 100000 : 680
                rightPadding: 18
                clip: true
                contentWidth: Math.max(1, availableWidth - 18)
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                ColumnLayout {
                    width: Math.max(1, paperScroll.availableWidth - 18)
                    spacing: NuTokens.spaceMd

                    StageCard {
                        stage: 1
                        title: "Choose Design"
                        status: root.statusForStage(1)
                        expanded: root.openStage === 1
                        onHeaderClicked: root.openStage = root.openStage === 1 ? 0 : 1

                        ColumnLayout {
                            width: parent.width
                            spacing: NuTokens.spaceMd

                            Label {
                                Layout.fillWidth: true
                                text: "Select the printed sheet style first. The preview on the right updates before keys are generated."
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }

                            NuComboBox {
                                Layout.fillWidth: true
                                model: root.visibleDesignNames
                                currentIndex: root.printForm
                                helpText: "Choose the paper wallet design. Additional draft designs remain in the build but are hidden until they are polished."
                                onActivated: (index) => root.applyDesignDefaults(index)
                            }

                            CheckBox {
                                text: "Economy print (hide art)"
                                checked: root.hideArt
                                onToggled: {
                                    root.hideArt = checked
                                    root.refreshPreviewPages()
                                }
                                ToolTip.visible: hovered
                                ToolTip.text: "Print a plainer sheet to save toner or ink. Laser printing is recommended; inkjet paper wallets can be damaged by water."
                                ToolTip.delay: NuTokens.tooltipDelay
                                ToolTip.timeout: NuTokens.tooltipTimeout
                            }
                        }
                    }

                    StageCard {
                        stage: 2
                        title: "Customize"
                        status: root.statusForStage(2)
                        expanded: root.openStage === 2
                        onHeaderClicked: root.openStage = root.openStage === 2 ? 0 : 2

                        ColumnLayout {
                            width: parent.width
                            spacing: NuTokens.spaceMd

                            GridLayout {
                                Layout.fillWidth: true
                                columns: root.compact ? 1 : 2
                                columnSpacing: NuTokens.spaceLg
                                rowSpacing: NuTokens.spaceMd

                                FieldBlock {
                                    title: "Wallets to print"
                                    detail: "Nu limits one run to 100 wallets so private keys remain reviewable before printing."

                                    SpinBox {
                                        from: 1
                                        to: root.maxWalletsPerRun
                                        editable: true
                                        value: root.addressesToGenerate
                                        Layout.fillWidth: true
                                        onValueModified: {
                                            root.addressesToGenerate = value
                                            root.refreshPreviewPages()
                                        }
                                        ToolTip.visible: hovered
                                        ToolTip.text: "Choose 1 to 100 paper wallets for this run. Large batches should use a dedicated reviewed workflow."
                                    }
                                }

                                FieldBlock {
                                    title: "Amount printed on wallet"
                                    detail: "Cosmetic only. The wallet must still be funded with real DFC."

                                    NuTextField {
                                        id: amountField
                                        Layout.fillWidth: true
                                        placeholderText: "Optional amount, e.g. 25 DFC"
                                        text: root.printedAmount
                                        helpText: "This only prints text on the paper wallet. It does not send funds or check balance."
                                        onTextChanged: {
                                            root.printedAmount = text
                                            root.refreshPreviewPages()
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: NuTokens.spaceMd

                                CheckBox {
                                    text: "BIP38 Encrypt"
                                    checked: root.bip38Encrypt
                                    onToggled: {
                                        root.bip38Encrypt = checked
                                        root.refreshPreviewPages()
                                    }
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Encrypt each printed private key with a passphrase. Losing the passphrase makes funds inaccessible."
                                }

                                NuTextField {
                                    id: bip38PassphraseField
                                    Layout.fillWidth: true
                                    enabled: root.bip38Encrypt
                                    echoMode: TextInput.Password
                                    placeholderText: root.bip38Encrypt ? "BIP38 passphrase" : "Enable BIP38 to enter passphrase"
                                    text: root.bip38Passphrase
                                    helpText: "Use a long passphrase you can preserve. By default Nu requires at least 12 characters, avoids blank or trivial phrases, and cannot recover the phrase after printing."
                                    onTextChanged: {
                                        root.bip38Passphrase = text
                                        root.refreshPreviewPages()
                                    }
                                }
                            }

                            CheckBox {
                                visible: root.bip38Encrypt
                                text: "Allow weak phrases?"
                                checked: root.allowWeakBip38Passphrase
                                onToggled: root.allowWeakBip38Passphrase = checked
                                ToolTip.visible: hovered
                                ToolTip.text: "Default off. Non-weak BIP38 phrases must be at least 12 characters and should avoid dictionary words, repeated characters, names, dates, and reused passwords. Turning this on allows any phrase you type, but weak phrases can be guessed by cracking tools."
                                ToolTip.delay: NuTokens.tooltipDelay
                                ToolTip.timeout: NuTokens.tooltipTimeout
                            }

                            Label {
                                Layout.fillWidth: true
                                visible: root.bip38Encrypt
                                text: root.bip38PassphraseReady
                                      ? (root.allowWeakBip38Passphrase
                                         ? "BIP38 warning: weak phrases are allowed for this print. Guessable phrases can be cracked; use this only for deliberate test/alignment workflows."
                                         : "BIP38 warning: if this passphrase is lost, funds controlled by the encrypted private key cannot be spent.")
                                      : "BIP38 warning: passphrase is not strong enough for wallet generation unless weak phrases are enabled. Use at least 12 characters; longer, less predictable phrases resist passphrase cracking better."
                                color: root.bip38PassphraseReady ? NuTokens.stateWarning : NuTokens.stateError
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    StageCard {
                        stage: 3
                        title: "Create Entropy"
                        status: root.statusForStage(3)
                        expanded: root.openStage === 3
                        onHeaderClicked: root.openStage = root.openStage === 3 ? 0 : 3

                        ColumnLayout {
                            width: parent.width
                            spacing: NuTokens.spaceMd

                            Label {
                                Layout.fillWidth: true
                                text: "Move the mouse across this page and type random characters. Your input is mixed with system cryptographic randomness before keys are created."
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                Layout.fillWidth: true
                                text: root.entropyProgressText
                                color: root.entropyReady ? NuTokens.stateConnected : NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }

                            Basic.ProgressBar {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 12
                                from: 0
                                to: 100
                                value: root.entropyPercent
                                background: Rectangle {
                                    radius: 6
                                    color: NuTokens.panelHover
                                    border.color: NuTokens.lineSubtle
                                }
                                contentItem: Item {
                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, root.entropyPercent / 100))
                                        height: parent.height
                                        radius: 6
                                        color: root.entropyReady ? NuTokens.stateConnected : NuTokens.accentSky
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: NuTokens.spaceMd

                                NuActionButton {
                                    text: root.entropyCaptureActive ? "Collecting..." : (root.entropyReady ? "Entropy Complete" : "Start Entropy Input")
                                    Layout.preferredWidth: 190
                                    primary: !root.entropyReady && !root.entropyCaptureActive
                                    enabled: !root.entropyReady && !root.entropyCaptureActive
                                    helpText: "Begin using mouse movement and keyboard input as local entropy. System cryptographic randomness is still mixed in before keys are generated."
                                    onClicked: {
                                        root.entropyCaptureActive = true
                                        root.forceActiveFocus()
                                    }
                                }

                                NuActionButton {
                                    text: "Reset Entropy"
                                    Layout.preferredWidth: 150
                                    helpText: "Clear the captured local entropy and start over."
                                    onClicked: root.resetEntropy()
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.entropyCaptureActive
                                          ? "Input is active."
                                          : (root.entropyReady ? "Ready for generation." : "Entropy input is paused.")
                                    color: root.entropyCaptureActive ? "#5d3d88" :
                                           (root.entropyReady ? NuTokens.stateConnected : NuTokens.textSecondary)
                                    font.pixelSize: NuTokens.fontSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    StageCard {
                        stage: 4
                        id: stage4Card
                        title: "Generate"
                        status: root.statusForStage(4)
                        expanded: root.openStage === 4
                        onHeaderClicked: root.openStage = root.openStage === 4 ? 0 : 4

                        ColumnLayout {
                            width: parent.width
                            spacing: NuTokens.spaceMd

                            Label {
                                Layout.fillWidth: true
                                text: "Generate only when this computer is clean and private. After generation, private keys exist in Nu memory until you print or clear them."
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }

                            NuActionButton {
                                text: NuService.paperWalletReady ? "Regenerate Wallet Sheet" : "Generate Wallet Sheet"
                                primary: true
                                enabled: root.canGeneratePaperWallet
                                Layout.fillWidth: true
                                helpText: "Generate local Defcoin keys using system RNG plus your entropy. Consider disconnecting from the internet before this step."
                                onClicked: root.generatePaperWallet()
                            }

                            Label {
                                Layout.fillWidth: true
                                text: root.generateDisabledReason()
                                color: root.canGeneratePaperWallet ? NuTokens.textSecondary : NuTokens.stateError
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    StageCard {
                        stage: 5
                        title: "Review and Print"
                        status: root.statusForStage(5)
                        expanded: root.openStage === 5
                        onHeaderClicked: root.openStage = root.openStage === 5 ? 0 : 5

                        ColumnLayout {
                            width: parent.width
                            spacing: NuTokens.spaceMd

                            Label {
                                Layout.fillWidth: true
                                text: "Pop Out shows the full page preview. Printing opens the native print dialog; avoid cloud or shared printers for private keys."
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: NuTokens.spaceMd

                                NuActionButton {
                                    text: "Pop Out"
                                    Layout.preferredWidth: 126
                                    helpText: "Open a larger full-page preview. If keys are not generated yet, placeholders are shown."
                                    onClicked: {
                                        paperWalletPopout.visible = true
                                        paperWalletPopout.raise()
                                        paperWalletPopout.requestActivate()
                                    }
                                }

                                NuActionButton {
                                    text: "Print"
                                    primary: true
                                    Layout.preferredWidth: 110
                                    helpText: NuService.paperWalletReady ? "Open the native print dialog for the generated paper-wallet sheet." : "Print an alignment/test sheet. It will be marked unusable because keys are not generated yet."
                                    onClicked: NuService.printPaperWallet(root.printForm,
                                                                          root.addressesToGenerate,
                                                                          root.addressesPerPage,
                                                                          root.hideArt,
                                                                          root.printedAmount)
                                }
                            }
                        }
                    }

                    StageCard {
                        stage: 6
                        title: "Distribute Funds Into Paper Wallet"
                        status: root.statusForStage(6)
                        expanded: root.openStage === 6
                        onHeaderClicked: root.openStage = root.openStage === 6 ? 0 : 6

                        ColumnLayout {
                            width: parent.width
                            spacing: NuTokens.spaceMd

                            Label {
                                Layout.fillWidth: true
                                text: NuService.paperWalletReady
                                      ? "Review generated public addresses and the amount to send to each paper wallet. This uses one reviewed wallet transaction with multiple outputs when possible."
                                      : "Generate paper-wallet keys before funding. The amount field from Step 2 is copied here as a starting value only."
                                color: NuService.paperWalletReady ? NuTokens.textSecondary : NuTokens.stateWarning
                                font.pixelSize: NuTokens.fontSmall
                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(250, Math.max(112, fundingList.contentHeight + NuTokens.spaceMd * 2))
                                radius: NuTokens.radiusMedium
                                color: NuTokens.backgroundBase
                                border.color: NuTokens.lineSubtle
                                clip: true

                                ListView {
                                    id: fundingList
                                    anchors.fill: parent
                                    anchors.margins: NuTokens.spaceSm
                                    model: NuService.paperWalletReady ? NuService.paperWalletEntries : []
                                    spacing: NuTokens.spaceXs
                                    boundsBehavior: Flickable.StopAtBounds
                                    delegate: Rectangle {
                                        width: fundingList.width
                                        height: rowLayout.implicitHeight + NuTokens.spaceSm
                                        radius: NuTokens.radiusSmall
                                        color: index % 2 === 0 ? "transparent" : NuTokens.panelHover

                                        RowLayout {
                                            id: rowLayout
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: NuTokens.spaceSm

                                            Label {
                                                Layout.preferredWidth: 34
                                                text: "#" + (index + 1)
                                                color: NuTokens.textSecondary
                                                font.pixelSize: NuTokens.fontTiny
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: root.paperEntryText(modelData, "address", "Address unavailable")
                                                color: NuTokens.textPrimary
                                                font.family: NuTokens.monoFont
                                                font.pixelSize: NuTokens.fontTiny
                                                elide: Text.ElideMiddle
                                                ToolTip.visible: addressMouse.containsMouse
                                                ToolTip.text: text
                                                ToolTip.delay: NuTokens.tooltipDelay
                                                ToolTip.timeout: NuTokens.tooltipTimeout

                                                MouseArea {
                                                    id: addressMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    acceptedButtons: Qt.NoButton
                                                }
                                            }

                                            NuTextField {
                                                Layout.preferredWidth: 132
                                                text: root.paperAmount(index)
                                                placeholderText: "DFC"
                                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                                helpText: "DFC amount to send to this generated public address. The printed amount is only cosmetic until this funding transaction is sent."
                                                onTextChanged: root.setPaperAmount(index, text)
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: fundingList.count === 0
                                        width: parent.width - NuTokens.spaceLg * 2
                                        text: "Generated public addresses will appear here."
                                        horizontalAlignment: Text.AlignHCenter
                                        color: NuTokens.textSecondary
                                        font.pixelSize: NuTokens.fontSmall
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: NuTokens.spaceMd

                                Label {
                                    Layout.fillWidth: true
                                    text: NuService.paperWalletReady ? root.fundingTotalText() : "No generated addresses yet."
                                    color: root.canFundPaperWallets() ? NuTokens.stateConnected : NuTokens.textSecondary
                                    font.pixelSize: NuTokens.fontSmall
                                    wrapMode: Text.WordWrap
                                }

                                NuActionButton {
                                    text: "Review Send"
                                    primary: true
                                    enabled: root.canFundPaperWallets()
                                    Layout.preferredWidth: 136
                                    helpText: "Review the paper-wallet funding transaction before sending from the active wallet."
                                    onClicked: fundingReviewDialog.open()
                                }
                            }
                        }
                    }

                }
            }

                NuPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.compact ? paperWalletBody.width : 780
                    Layout.minimumHeight: 640
                    padding: NuTokens.spaceLg

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
                                    text: "Sheet Preview"
                                    color: NuTokens.textPrimary
                                    font.pixelSize: NuTokens.fontBodyLarge
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.selectedDesignName + " - " + root.previewStatusText()
                                    color: NuService.paperWalletReady ? NuTokens.stateConnected : (root.previewLoading ? NuTokens.accentSky : NuTokens.stateWarning)
                                    font.pixelSize: NuTokens.fontSmall
                                    wrapMode: Text.WordWrap
                                }
                            }

                            RowLayout {
                                spacing: NuTokens.spaceXs

                                PreviewZoomButton {
                                    text: "−"
                                    helpText: "Zoom preview out."
                                    onClicked: root.previewZoom = Math.max(0.35, root.previewZoom - 0.12)
                                }
                                PreviewZoomButton {
                                    text: "1"
                                    helpText: "Show preview at 1:1."
                                    onClicked: root.previewZoom = 1.0
                                }
                                PreviewZoomButton {
                                    text: "+"
                                    helpText: "Zoom preview in."
                                    onClicked: root.previewZoom = Math.min(2.6, root.previewZoom + 0.12)
                                }
                            }

                            Label {
                                text: root.addressesToGenerate + " wallet" + (root.addressesToGenerate === 1 ? "" : "s")
                                color: NuTokens.textSecondary
                                font.pixelSize: NuTokens.fontSmall
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: NuTokens.radiusLarge
                            color: "#f6f7f4"
                            border.color: NuTokens.lineSubtle
                            clip: true

                            Item {
                                id: sheetPreviewPane
                                anchors.fill: parent
                                anchors.margins: NuTokens.spaceSm

                                Label {
                                    anchors.centerIn: parent
                                    visible: root.previewPageSources.length === 0 && !root.previewLoading
                                    text: "Preview unavailable"
                                    color: NuTokens.textSecondary
                                    font.pixelSize: NuTokens.fontSmall
                                }

                                Flickable {
                                    id: sheetPreviewFlick
                                    anchors.fill: parent
                                    visible: root.previewPageSources.length > 0
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    contentWidth: previewGrid.implicitWidth
                                    contentHeight: previewGrid.implicitHeight
                                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                    GridLayout {
                                        id: previewGrid
                                        columns: root.selectedDesignDoubleSided && sheetPreviewFlick.width > sheetPreviewFlick.height * 1.05 ? 2 : 1
                                        rowSpacing: NuTokens.spaceLg
                                        columnSpacing: NuTokens.spaceLg
                                        x: Math.max(0, (sheetPreviewFlick.width - implicitWidth) / 2)
                                        y: Math.max(0, (sheetPreviewFlick.height - implicitHeight) / 2)

                                        Repeater {
                                            model: root.previewPageSources

                                            Rectangle {
                                                property real pageAspect: root.printForm === 1 || root.printForm === 4 ? 11 / 8.5 : 8.5 / 11
                                                property real fitWidth: previewGrid.columns === 2
                                                                        ? Math.max(80, (sheetPreviewFlick.width - NuTokens.spaceLg) / 2)
                                                                        : Math.max(80, sheetPreviewFlick.width)
                                                property real fitHeight: Math.max(80, sheetPreviewFlick.height)
                                                property real basePageWidth: previewGrid.columns === 2
                                                                             ? Math.min(fitWidth, fitHeight * pageAspect)
                                                                             : fitWidth
                                                property real pagePreviewWidth: Math.max(140, basePageWidth * root.previewZoom)
                                                Layout.preferredWidth: pagePreviewWidth
                                                Layout.preferredHeight: pagePreviewWidth / pageAspect
                                                radius: 2
                                                color: "white"
                                                border.color: "#cfd8df"

                                                Image {
                                                    anchors.fill: parent
                                                    anchors.margins: 1
                                                    source: modelData
                                                    fillMode: Image.PreserveAspectFit
                                                    smooth: true
                                                    asynchronous: false
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: root.previewLoading
                                    color: Qt.rgba(246 / 255, 247 / 255, 244 / 255, 0.74)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: NuTokens.spaceSm

                                        BusyIndicator {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            running: root.previewLoading
                                        }

                                        Label {
                                            text: "Generating sheet preview..."
                                            color: NuTokens.textPrimary
                                            font.pixelSize: NuTokens.fontSmall
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

    Window {
        id: paperWalletPopout
        title: "Defcoin Paper Wallet Preview"
        visible: false
        width: 1040
        height: 900
        minimumWidth: 760
        minimumHeight: 620
        color: NuTokens.backgroundBase

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: NuTokens.spaceXl
            spacing: NuTokens.spaceLg

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceXs
                    Label {
                        Layout.fillWidth: true
                        text: "Full Page Preview"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTitle
                        font.weight: Font.DemiBold
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.previewStatusText()
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                    }
                }

                RowLayout {
                    spacing: NuTokens.spaceXs

                    PreviewZoomButton {
                        text: "−"
                        helpText: "Zoom preview out."
                        onClicked: root.popoutPreviewZoom = Math.max(0.35, root.popoutPreviewZoom - 0.12)
                    }
                    PreviewZoomButton {
                        text: "1"
                        helpText: "Show preview at 1:1."
                        onClicked: root.popoutPreviewZoom = 1.0
                    }
                    PreviewZoomButton {
                        text: "+"
                        helpText: "Zoom preview in."
                        onClicked: root.popoutPreviewZoom = Math.min(2.2, root.popoutPreviewZoom + 0.12)
                    }
                }

                NuActionButton {
                    text: "Print"
                    primary: true
                    Layout.preferredWidth: 112
                    onClicked: NuService.printPaperWallet(root.printForm,
                                                          root.addressesToGenerate,
                                                          root.addressesPerPage,
                                                          root.hideArt,
                                                          root.printedAmount)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: NuTokens.radiusLarge
                color: "#f6f7f4"
                border.color: NuTokens.lineSubtle
                clip: true

                Item {
                    anchors.fill: parent
                    anchors.margins: NuTokens.spaceLg

                    Flickable {
                        id: popoutPreviewFlick
                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: popoutPreviewGrid.implicitWidth
                        contentHeight: popoutPreviewGrid.implicitHeight
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        GridLayout {
                            id: popoutPreviewGrid
                            columns: root.selectedDesignDoubleSided && popoutPreviewFlick.width > popoutPreviewFlick.height * 1.05 ? 2 : 1
                            rowSpacing: NuTokens.spaceLg
                            columnSpacing: NuTokens.spaceLg
                            x: Math.max(0, (popoutPreviewFlick.width - implicitWidth) / 2)
                            y: Math.max(0, (popoutPreviewFlick.height - implicitHeight) / 2)

                            Repeater {
                                model: root.previewPageSources

                                Rectangle {
                                    property real fitWidth: popoutPreviewGrid.columns === 2
                                                            ? (popoutPreviewFlick.width - NuTokens.spaceLg) / 2
                                                            : popoutPreviewFlick.width
                                    property real fitHeight: popoutPreviewFlick.height
                                    property real pageAspect: root.printForm === 1 || root.printForm === 4 ? 11 / 8.5 : 8.5 / 11
                                    property real fitPageWidth: Math.min(fitWidth, fitHeight * pageAspect) * root.popoutPreviewZoom
                                    Layout.preferredWidth: Math.max(120, fitPageWidth)
                                    Layout.preferredHeight: Math.max(120, fitPageWidth / pageAspect)
                                    radius: 2
                                    color: "white"
                                    border.color: "#cfd8df"

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: modelData
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    NuDialog {
        id: fundingReviewDialog
        title: "Fund paper wallets"
        acceptText: "Send"
        cancelText: "Cancel"
        dialogWidth: 720
        acceptEnabled: root.canFundPaperWallets()

        Label {
            Layout.fillWidth: true
            text: "Nu will ask the active wallet to send one transaction with these paper-wallet public-address outputs. Verify every amount before sending."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: root.fundingTotalText()
            color: root.canFundPaperWallets() ? NuTokens.stateConnected : NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.fundingRows()

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceSm

                Label {
                    Layout.fillWidth: true
                    text: modelData.address
                    color: NuTokens.textPrimary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontTiny
                    elide: Text.ElideMiddle
                }

                Label {
                    Layout.preferredWidth: 128
                    text: modelData.amount + " DFC"
                    color: NuTokens.textPrimary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontTiny
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Private keys are not sent to Core. Only the generated public addresses and DFC amounts are used for this funding transaction."
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        onAccepted: NuService.fundPaperWallets(root.fundingRows())
    }

    Dialog {
        id: printOffer
        modal: true
        title: "Review and print?"
        anchors.centerIn: parent
        width: Math.min(parent.width - NuTokens.spaceXl * 2, 560)
        padding: NuTokens.spaceLg
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: NuTokens.spaceMd

            Label {
                Layout.fillWidth: true
                text: "The paper wallet sheet is ready. Review the full-page preview or print now."
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBody
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                text: "Private keys are visible only in this session. Do not print through shared or cloud print queues unless you intentionally accept that risk."
                color: NuTokens.stateWarning
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }
        }

        footer: Item {
            implicitHeight: footerRow.implicitHeight + NuTokens.spaceLg + NuTokens.spaceMd

            RowLayout {
                id: footerRow
                anchors.fill: parent
                anchors.leftMargin: NuTokens.spaceLg
                anchors.rightMargin: NuTokens.spaceLg
                anchors.topMargin: NuTokens.spaceSm
                anchors.bottomMargin: NuTokens.spaceLg
                spacing: NuTokens.spaceMd

                Item { Layout.fillWidth: true }

                NuActionButton {
                    text: "Preview"
                    Layout.preferredWidth: 110
                    onClicked: {
                        printOffer.close()
                        paperWalletPopout.visible = true
                        paperWalletPopout.raise()
                        paperWalletPopout.requestActivate()
                    }
                }

                NuActionButton {
                    text: "Print"
                    primary: true
                    Layout.preferredWidth: 110
                    onClicked: {
                        printOffer.close()
                        NuService.printPaperWallet(root.printForm,
                                                  root.addressesToGenerate,
                                                  root.addressesPerPage,
                                                  root.hideArt,
                                                  root.printedAmount)
                    }
                }
            }
        }
    }

    component FieldBlock: ColumnLayout {
        property string title: ""
        property string detail: ""
        default property alias content: body.data
        spacing: NuTokens.spaceXs

        Label {
            Layout.fillWidth: true
            text: title
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontSmall
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: detail
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontTiny
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: NuTokens.spaceXs
        }
    }

    component StageCard: NuPanel {
        id: card
        property int stage: 0
        property string title: ""
        property string status: ""
        property bool expanded: false
        signal headerClicked()
        default property alias cardContent: contentHost.data

        Layout.fillWidth: true
        Layout.preferredHeight: contentColumn.implicitHeight + padding * 2
        implicitHeight: contentColumn.implicitHeight + padding * 2
        padding: NuTokens.spaceMd

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: card.expanded ? NuTokens.spaceMd : 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: NuTokens.radiusMedium
                color: headerHover.containsMouse ? Qt.rgba(96 / 255, 70 / 255, 140 / 255, 0.10) : "transparent"
                border.color: headerHover.containsMouse ? "#5d3d88" : "transparent"
                border.width: headerHover.containsMouse ? 1 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: NuTokens.spaceSm
                    anchors.rightMargin: NuTokens.spaceSm
                    spacing: NuTokens.spaceMd

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: card.expanded ? NuTokens.accentSky : NuTokens.panelHover
                        border.color: NuTokens.lineSubtle

                        Label {
                            anchors.centerIn: parent
                            text: card.stage
                            color: card.expanded ? NuTokens.textInverse : NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontSmall
                            font.weight: Font.DemiBold
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: card.title
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBody
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Label {
                        text: card.status
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: headerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.headerClicked()
                }
            }

            ColumnLayout {
                id: contentHost
                Layout.fillWidth: true
                Layout.preferredHeight: card.expanded ? implicitHeight : 0
                visible: card.expanded
                spacing: NuTokens.spaceMd
            }
        }
    }

    component PreviewZoomButton: Rectangle {
        property alias text: zoomLabel.text
        property string helpText: ""
        signal clicked()

        width: 32
        height: 32
        radius: 16
        color: zoomHover.containsMouse ? "#24272d" : "#15171b"
        border.color: "#2d3138"
        border.width: 1

        Label {
            id: zoomLabel
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: NuTokens.fontSmall
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: zoomHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        ToolTip.visible: zoomHover.containsMouse && helpText.length > 0
        ToolTip.text: helpText
        ToolTip.delay: NuTokens.tooltipDelay
        ToolTip.timeout: NuTokens.tooltipTimeout
    }
}
