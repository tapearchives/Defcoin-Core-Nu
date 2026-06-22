import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg
    property var currentRequest: ({})
    property int receiveTab: 0
    property bool paperBip38PassphraseVisible: false

    function paperKeyLooksBip38() {
        return paperPrivateKeyField.text.trim().indexOf("6P") === 0
    }

    function currentDisplayAddress() {
        var selected = root.currentRequest.address || ""
        return selected.length > 0 ? selected : NuService.receiveAddress
    }

    function currentDisplayQrSource() {
        var selected = root.currentRequest.qrSource || ""
        return selected.length > 0 ? selected : NuService.receiveQrSource
    }

    function requestForAddress(address) {
        var wanted = String(address || "")
        for (var i = 0; i < NuService.receiveRequests.length; ++i) {
            var row = NuService.receiveRequests[i]
            var meta = row && row.meta ? row.meta : ({})
            if (String(meta.address || "") === wanted)
                return meta
        }
        return ({})
    }

    function openRequestDetails(row) {
        currentRequest = row && row.meta ? row.meta : ({})
        requestDetailsDialog.open()
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Receive"
        detail: "Create payment requests with a real address and QR payload."
        dense: true
    }

    NuTabBar {
        Layout.fillWidth: true
        currentIndex: root.receiveTab
        NuTabButton { text: "Payment Request"; onClicked: root.receiveTab = 0 }
        NuTabButton { text: "Import"; onClicked: root.receiveTab = 1 }
    }

    NuPanel {
        Layout.fillWidth: true
        visible: root.receiveTab === 0
        Layout.preferredHeight: visible ? implicitHeight : 0
        implicitHeight: 284

        RowLayout {
            anchors.fill: parent
            spacing: NuTokens.spaceLg

            Rectangle {
                Layout.preferredWidth: 216
                Layout.preferredHeight: 216
                color: "#ffffff"
                border.color: NuTokens.lineStrong
                radius: NuTokens.radiusSmall
                Image {
                    anchors.centerIn: parent
                    width: 194
                    height: 194
                    visible: root.currentDisplayQrSource().length > 0
                    source: root.currentDisplayQrSource()
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    anchors.centerIn: parent
                    width: parent.width - 36
                    visible: root.currentDisplayQrSource().length === 0
                    text: "QR appears after address generation"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Payment address"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                NuCopyField {
                    Layout.fillWidth: true
                    value: root.currentDisplayAddress().length > 0 ? root.currentDisplayAddress() : "Generate a request to create a receiving address."
                    copyEnabled: root.currentDisplayAddress().length > 0
                    onCopyRequested: (value) => NuService.copyText(value)
                }
                Label {
                    Layout.fillWidth: true
                    text: "Request details are encoded into the QR URI when supplied. They remain wallet metadata and are not written to the blockchain."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
                NuActionButton {
                    text: "Generate request"
                    primary: true
                    Layout.preferredWidth: 220
                    helpText: "Create a new receiving address and optional payment URI."
                    onClicked: requestDialog.open()
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.receiveTab === 0
        Layout.preferredHeight: visible ? implicitHeight : 0
        spacing: NuTokens.spaceMd

        Label {
            Layout.fillWidth: true
            text: "Generated requests"
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontBody
        }

        NuActionButton {
            text: receiveRequestsTable.selectedRowKeys.length > 0
                  ? "Delete selected (" + receiveRequestsTable.selectedRowKeys.length + ")"
                  : "Delete selected"
            Layout.preferredWidth: 190
            enabled: receiveRequestsTable.selectedRowKeys.length > 0
            opacity: enabled ? 1.0 : 0.55
            helpText: "Delete selected generated requests."
            onClicked: {
                NuService.deleteReceiveRequests(receiveRequestsTable.selectedRowKeys)
                receiveRequestsTable.clearRowSelection()
                requestDetailsDialog.close()
            }
        }
    }

    NuDataTable {
        id: receiveRequestsTable
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.receiveTab === 0
        Layout.preferredHeight: visible ? implicitHeight : 0
        tableId: "receiveRequests"
        columns: ["", "Date", "Label", "Address", "Amount"]
        columnTypes: ["action", "date", "text", "address", "amount"]
        columnWeights: [0.1, 1.0, 1.2, 3.5, 1.0]
        columnMinimums: [44, 150, 140, 260, 130]
        columnMaximums: [44, 180, 360, 620, 180]
        rowSelectionEnabled: true
        plainClickSelectsRows: true
        rowKeyMetaField: "address"
        rows: NuService.receiveRequests
        emptyText: "Requested payments will appear here."
        onRowSelectionChanged: (keys) => {
            if (keys.length === 1)
                root.currentRequest = root.requestForAddress(keys[0])
            else if (keys.length === 0)
                root.currentRequest = ({})
        }
        onRowActivated: (row) => root.openRequestDetails(row)
    }

    NuPanel {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.receiveTab === 1
        Layout.preferredHeight: visible ? implicitHeight : 0

        ColumnLayout {
            anchors.fill: parent
            spacing: NuTokens.spaceMd

            Label {
                Layout.fillWidth: true
                text: "Import a paper-wallet WIF or BIP38 private key into the active wallet. The key is sent only to the local backend RPC for import."
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontBody
                wrapMode: Text.WordWrap
            }

            FieldBlock {
                title: "Private key"
                detail: "Paste the WIF private key, or the BIP38 encrypted key if the paper wallet was passphrase protected. Anyone who sees an unencrypted key can spend the funds."

                NuTextField {
                    id: paperPrivateKeyField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Paper wallet private key or BIP38 key"
                    helpText: "Paste the private key from a Defcoin paper wallet. Keep it off shared screens and clear it after import."
                }
            }

            FieldBlock {
                visible: root.paperKeyLooksBip38()
                title: "BIP38 passphrase"
                detail: "Required only for encrypted BIP38 paper-wallet keys."

                NuPassphraseField {
                    id: paperBip38PassphraseField
                    Layout.fillWidth: true
                    passphraseVisible: root.paperBip38PassphraseVisible
                    statusActive: root.paperKeyLooksBip38()
                    statusColor: text.length > 0 ? NuTokens.stateConnected : NuTokens.stateError
                    placeholderText: "BIP38 passphrase"
                    helpText: "Enter the passphrase used when this BIP38 paper-wallet key was generated."
                    onVisibilityToggled: (visible) => root.paperBip38PassphraseVisible = visible
                }
            }

            Label {
                Layout.fillWidth: true
                visible: root.paperKeyLooksBip38()
                text: paperBip38PassphraseField.text.length > 0
                      ? "BIP38 passphrase will be used locally to decrypt the key before import."
                      : "Enter the BIP38 passphrase before importing this encrypted key."
                color: paperBip38PassphraseField.text.length > 0 ? NuTokens.stateConnected : NuTokens.stateError
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            FieldBlock {
                title: "Label"
                detail: "Optional label used for the imported key."

                NuTextField {
                    id: paperImportLabelField
                    Layout.fillWidth: true
                    text: "Paper wallet import"
                    helpText: "This label is attached to the imported key/address in the active wallet."
                }
            }

            CheckBox {
                id: sweepPaperKeyCheck
                text: "Sweep"
                checked: true
                ToolTip.visible: hovered
                ToolTip.text: "Sweep means move funds from the imported paper wallet to a fresh address in the active wallet after the rescan confirms spendable balance. This build imports and rescans first, then instructs you to send once the balance is visible."
                ToolTip.delay: NuTokens.tooltipDelay
                ToolTip.timeout: NuTokens.tooltipTimeout
            }

            Label {
                Layout.fillWidth: true
                text: sweepPaperKeyCheck.checked
                      ? "Sweep is selected. Nu will import and rescan first; after the funds are visible, move them to a fresh wallet address from Send."
                      : "Import only keeps the private key in this wallet. The paper wallet remains spendable from any copy of that key."
                color: sweepPaperKeyCheck.checked ? NuTokens.stateWarning : NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                NuActionButton {
                    text: "Import Private Key"
                    primary: true
                    enabled: paperPrivateKeyField.text.trim().length > 0
                             && NuService.walletSelected
                             && (!root.paperKeyLooksBip38() || paperBip38PassphraseField.text.length > 0)
                    Layout.preferredWidth: 190
                    helpText: "Import the paper-wallet private key into the active wallet and start a rescan."
                    onClicked: {
                        NuService.importPaperWalletPrivateKey(paperPrivateKeyField.text,
                                                              sweepPaperKeyCheck.checked,
                                                              paperImportLabelField.text,
                                                              paperBip38PassphraseField.text)
                        paperPrivateKeyField.text = ""
                        paperBip38PassphraseField.text = ""
                        root.paperBip38PassphraseVisible = false
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    NuDialog {
        id: requestDialog
        title: "Generate payment request"
        acceptText: "Generate"
        dialogWidth: 620

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: NuTokens.spaceMd
            columnSpacing: NuTokens.spaceLg

            Label { text: "Label"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            NuTextField { id: labelField; Layout.fillWidth: true; placeholderText: "Optional label" }

            Label { text: "Amount"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            NuTextField { id: amountField; Layout.fillWidth: true; placeholderText: "Optional amount in DFC" }

            Label { text: "Message"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            NuTextField { id: messageField; Layout.fillWidth: true; placeholderText: "Optional message" }
        }

        onAccepted: {
            root.currentRequest = ({})
            receiveRequestsTable.clearRowSelection()
            NuService.requestNewAddress(labelField.text, amountField.text, messageField.text)
        }
    }

    NuDialog {
        id: requestDetailsDialog
        title: "Payment request"
        showCancel: false
        acceptText: "Close"
        dialogWidth: 720

        RowLayout {
            Layout.fillWidth: true
            spacing: NuTokens.spaceLg

            Rectangle {
                Layout.preferredWidth: 220
                Layout.preferredHeight: 220
                color: "#ffffff"
                border.color: NuTokens.lineStrong
                radius: NuTokens.radiusSmall
                Image {
                    anchors.centerIn: parent
                    width: 198
                    height: 198
                    source: root.currentRequest.qrSource || NuService.receiveRequestQrSource(root.currentRequest.uri || "")
                    fillMode: Image.PreserveAspectFit
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceSm

                TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    text: "Address: " + (root.currentRequest.address || "")
                          + "\nLabel: " + (root.currentRequest.label || "")
                          + "\nAmount: " + (root.currentRequest.amount || "")
                          + "\nMessage: " + (root.currentRequest.message || "")
                          + "\nURI: " + (root.currentRequest.uri || "")
                    color: NuTokens.textPrimary
                    selectedTextColor: NuTokens.textInverse
                    selectionColor: NuTokens.lineStrong
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                    background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: (root.currentRequest.address || "").length > 0
                    NuActionButton {
                        text: "Inspect address"
                        Layout.preferredWidth: 168
                        helpText: "Open this address with the configured external block explorer."
                        onClicked: NuService.openAddressInExplorer(root.currentRequest.address || "")
                    }
                    Label {
                        Layout.fillWidth: true
                        text: NuService.explorerUrlForAddress(root.currentRequest.address || "")
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: NuTokens.spaceSm
            NuActionButton {
                text: "Copy URI"
                Layout.preferredWidth: 120
                onClicked: NuService.copyText(root.currentRequest.uri || "")
            }
            NuActionButton {
                text: "Copy address"
                Layout.preferredWidth: 150
                onClicked: NuService.copyText(root.currentRequest.address || "")
            }
            Item { Layout.fillWidth: true }
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
}
