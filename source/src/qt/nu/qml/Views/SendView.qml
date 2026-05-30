import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg

    property var addressRows: NuService.addressBook
    property var feeModes: ["Recommended", "Economical", "Custom"]
    property var feeTargets: ["2", "6", "12", "24"]
    property bool advancedOpen: false

    function selectedFeeMode() {
        var text = feeMode.currentText.toLowerCase()
        if (text.indexOf("custom") !== -1)
            return "custom"
        if (text.indexOf("economical") !== -1)
            return "economical"
        return "conservative"
    }

    function feeModeSummary() {
        if (selectedFeeMode() === "custom")
            return "Custom fee rate: " + (customFeeRate.text.trim().length > 0 ? customFeeRate.text.trim() : "not set") + " motes/vB."
        return (selectedFeeMode() === "economical" ? "Economical backend estimate" : "Recommended conservative backend estimate")
            + " with target " + feeTarget.currentText + " blocks."
    }

    function canReview() {
        return recipientField.text.trim().length > 0 && amountField.text.trim().length > 0
    }

    function addressBookModel() {
        var out = ["Choose from address book..."]
        for (var i = 0; i < addressRows.length; ++i) {
            var row = addressRows[i]
            out.push(row[0] + "  |  " + row[1])
        }
        return out
    }

    function selectedAddressBookAddress() {
        if (addressBook.currentIndex <= 0)
            return ""
        var row = root.addressRows[addressBook.currentIndex - 1]
        return row && row.length > 1 ? String(row[1]) : ""
    }

    function recipientAddressForInspect() {
        const selected = selectedAddressBookAddress().trim()
        if (selected.length > 0)
            return selected
        let text = recipientField.text.trim()
        if (text.toLowerCase().indexOf("defcoin:") === 0) {
            text = text.substring("defcoin:".length)
            const queryStart = text.indexOf("?")
            if (queryStart >= 0)
                text = text.substring(0, queryStart)
        }
        return text.trim()
    }

    function loadUri(uri) {
        var text = String(uri === undefined || uri === null ? "" : uri).trim()
        if (text.length === 0)
            return
        recipientField.text = text
        if (text.toLowerCase().indexOf("defcoin:") !== 0)
            return
        var queryStart = text.indexOf("?")
        var query = queryStart >= 0 ? text.substring(queryStart + 1) : ""
        var addressPart = queryStart >= 0 ? text.substring(0, queryStart) : text
        recipientField.text = addressPart.substring("defcoin:".length)
        var pairs = query.length > 0 ? query.split("&") : []
        for (var i = 0; i < pairs.length; ++i) {
            var parts = pairs[i].split("=")
            var key = decodeURIComponent(parts[0] || "")
            var value = decodeURIComponent(parts.slice(1).join("=") || "")
            if (key === "amount")
                amountField.text = value
            else if (key === "label")
                labelField.text = value
        }
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Send"
        detail: "Create a payment, set fee intent, and review before broadcast."
    }

    NuPanel {
        Layout.fillWidth: true
        implicitHeight: root.advancedOpen ? 590 : 430

        GridLayout {
            anchors.fill: parent
            columns: 2
            rowSpacing: NuTokens.spaceLg
            columnSpacing: NuTokens.spaceLg

            Label { text: "Address book"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            RowLayout {
                Layout.fillWidth: true

                NuComboBox {
                    id: addressBook
                    Layout.fillWidth: true
                    model: root.addressBookModel()
                    helpText: "Pick a labeled wallet address or contact."
                    onActivated: function(index) {
                        if (index <= 0) return
                        var row = root.addressRows[index - 1]
                        labelField.text = row[0] === "(no label)" ? "" : row[0]
                        recipientField.text = row[1]
                    }
                }

                NuInspectButton {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    enabled: root.recipientAddressForInspect().length > 0
                    helpText: "Inspect the selected or entered address in the configured blockchain explorer."
                    onClicked: NuService.openAddressInExplorer(root.recipientAddressForInspect())
                }
            }

            Label { text: "Recipient"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            NuTextField {
                id: recipientField
                Layout.fillWidth: true
                placeholderText: "Defcoin address or defcoin: URI"
            }

            Label { text: "Label"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            NuTextField {
                id: labelField
                Layout.fillWidth: true
                placeholderText: "Optional wallet label"
            }

            Label { text: "Amount"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            NuTextField {
                id: amountField
                Layout.fillWidth: true
                placeholderText: "0.00000000 DFC"
            }

            Label { text: "Fee"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    NuComboBox {
                        id: feeMode
                        Layout.preferredWidth: 180
                        model: root.feeModes
                        helpText: "Recommended uses the backend's conservative smart-fee estimate. Economical allows a lower-priority backend estimate. Custom sends the entered fee rate."
                    }
                    NuComboBox {
                        id: feeTarget
                        Layout.preferredWidth: 140
                        model: root.feeTargets
                        enabled: root.selectedFeeMode() !== "custom"
                        helpText: "Target confirmation window in blocks. The backend may use fallback policy when fee estimates are unavailable."
                    }
                    Label {
                        text: "blocks"
                        color: feeTarget.enabled ? NuTokens.textSecondary : NuTokens.textMuted
                        font.pixelSize: NuTokens.fontBody
                        visible: root.selectedFeeMode() !== "custom"
                    }
                    NuTextField {
                        id: customFeeRate
                        Layout.preferredWidth: 180
                        visible: root.selectedFeeMode() === "custom"
                        placeholderText: "motes/vB"
                        helpText: "Custom fee rate in motes per virtual byte. Leave Recommended selected unless you understand fee-rate policy."
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: root.feeModeSummary() + " " + NuService.feeEstimateStatus
                    color: NuService.feeEstimateAvailable ? NuTokens.textSecondary : NuTokens.stateWarning
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
            }

            Item { Layout.preferredHeight: 1 }
            NuCheckBox {
                id: subtractFee
                Layout.fillWidth: true
                text: "Subtract fee from amount"
            }

            Item { Layout.preferredHeight: 1 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceSm

                NuActionButton {
                    text: root.advancedOpen ? "Hide advanced send options" : "Advanced send options"
                    Layout.preferredWidth: 260
                    helpText: "Show custom change address controls. Coin selection remains available through the RPC console."
                    onClicked: root.advancedOpen = !root.advancedOpen
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    visible: root.advancedOpen
                    rowSpacing: NuTokens.spaceMd
                    columnSpacing: NuTokens.spaceLg

                    Label {
                        text: "Custom change address"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                    }
                    NuTextField {
                        id: changeAddressField
                        Layout.fillWidth: true
                        placeholderText: "Optional wallet-owned change address"
                    }

                    Label {
                        text: "PSBT"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                        Layout.alignment: Qt.AlignTop
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm

                        Flow {
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            spacing: NuTokens.spaceSm

                            NuActionButton {
                                text: "Load file..."
                                width: 112
                                helpText: "Load a Partially Signed Defcoin Transaction from a .psbt or text file."
                                onClicked: NuService.loadPsbtFromFile()
                            }
                            NuActionButton {
                                text: "Load clipboard"
                                width: 130
                                helpText: "Load text PSBT data from the clipboard."
                                onClicked: NuService.loadPsbtFromClipboard()
                            }
                            NuActionButton {
                                text: "Sign"
                                width: 76
                                enabled: NuService.psbtLoaded
                                opacity: enabled ? 1.0 : 0.48
                                helpText: enabled ? "Ask the wallet backend to sign what it can in the loaded PSBT." : "Load a PSBT before signing."
                                onClicked: NuService.signCurrentPsbt()
                            }
                            NuActionButton {
                                text: "Finalize"
                                width: 92
                                enabled: NuService.psbtLoaded
                                opacity: enabled ? 1.0 : 0.48
                                helpText: enabled ? "Finalize the loaded PSBT into a raw transaction when enough signatures are present." : "Load a PSBT before finalizing."
                                onClicked: NuService.finalizeCurrentPsbt()
                            }
                            NuActionButton {
                                text: "Broadcast"
                                width: 104
                                enabled: NuService.psbtFinalized
                                opacity: enabled ? 1.0 : 0.48
                                helpText: enabled ? "Broadcast the finalized transaction." : "Finalize a complete PSBT before broadcasting."
                                onClicked: NuService.broadcastFinalizedPsbt()
                            }
                            NuActionButton {
                                text: "Copy PSBT"
                                width: 100
                                enabled: NuService.psbtLoaded
                                opacity: enabled ? 1.0 : 0.48
                                onClicked: NuService.copyCurrentPsbt()
                            }
                            NuActionButton {
                                text: "Save PSBT..."
                                width: 110
                                enabled: NuService.psbtLoaded
                                opacity: enabled ? 1.0 : 0.48
                                onClicked: NuService.saveCurrentPsbt()
                            }
                            NuActionButton {
                                text: "Clear"
                                width: 76
                                enabled: NuService.psbtLoaded
                                opacity: enabled ? 1.0 : 0.48
                                onClicked: NuService.clearCurrentPsbt()
                            }
                        }

                        TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 96
                            readOnly: true
                            selectByMouse: true
                            selectByKeyboard: true
                            activeFocusOnPress: true
                            focusPolicy: Qt.StrongFocus
                            wrapMode: Text.WrapAnywhere
                            text: NuService.currentPsbtSummary
                            color: NuTokens.textPrimary
                            selectionColor: NuTokens.lineStrong
                            selectedTextColor: NuTokens.textInverse
                            font.family: NuTokens.monoFont
                            font.pixelSize: NuTokens.fontSmall
                            background: Rectangle {
                                color: NuTokens.backgroundBase
                                border.color: NuTokens.lineSubtle
                                radius: NuTokens.radiusSmall
                            }
                            Keys.onPressed: function(event) {
                                if (event.matches(StandardKey.Copy)) {
                                    copy()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: "Review every payment before broadcast. Advanced coin selection is available in Diagnostics > Console through the backend RPC command set."
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }
        NuActionButton {
            text: "Review transaction"
            primary: true
            opacity: root.canReview() ? 1.0 : 0.55
            Layout.preferredWidth: 220
            helpText: root.canReview() ? "Open a final confirmation before signing or broadcasting." : "Enter a recipient and amount before reviewing the transaction."
            onClicked: root.canReview() ? reviewDialog.open() : incompleteDialog.open()
        }
    }

    NuDialog {
        id: incompleteDialog
        title: "Transaction needs details"
        showCancel: false
        dialogWidth: 520

        Label {
            Layout.fillWidth: true
            text: "Enter a recipient and amount before reviewing the transaction."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }
    }

    NuDialog {
        id: reviewDialog
        title: "Review transaction"
        acceptText: "Send"
        dialogWidth: 620

        Label {
            Layout.fillWidth: true
            text: "Amount: " + amountField.text + " DFC\nRecipient: " + recipientField.text
                  + "\nFee: " + root.feeModeSummary()
                  + (!NuService.feeEstimateAvailable && root.selectedFeeMode() !== "custom" ? "\nFee estimate note: backend estimate is unavailable; backend fallback policy may be used." : "")
                  + (changeAddressField.text.length > 0 ? "\nChange: " + changeAddressField.text : "")
                  + "\n\nDefcoin transactions cannot be reversed after broadcast."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        NuActionButton {
            text: "Create PSBT"
            Layout.preferredWidth: 160
            helpText: "Create a Partially Signed Defcoin Transaction from this payment without broadcasting it."
            onClicked: {
                NuService.createPsbt(recipientField.text,
                                     amountField.text,
                                     root.selectedFeeMode(),
                                     feeTarget.currentText,
                                     customFeeRate.text,
                                     subtractFee.checked,
                                     labelField.text,
                                     changeAddressField.text)
                root.advancedOpen = true
                reviewDialog.close()
            }
        }

        onAccepted: NuService.sendCoins(recipientField.text,
                                        amountField.text,
                                        root.selectedFeeMode(),
                                        feeTarget.currentText,
                                        customFeeRate.text,
                                        subtractFee.checked,
                                        labelField.text,
                                        changeAddressField.text)
    }
}
