import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceMd

    property int consoleFontSize: NuTokens.fontLog
    property string selectedWalletName: NuService.walletSelected ? NuService.currentWalletName : "__node__"

    function walletModel() {
        var items = ["__node__"]
        for (var i = 0; i < NuService.loadedWallets.length; ++i)
            items.push(String(NuService.loadedWallets[i]))
        if (NuService.walletSelected && items.indexOf(NuService.currentWalletName) < 0)
            items.push(NuService.currentWalletName)
        return items
    }

    function walletIndex(name) {
        var items = walletModel()
        for (var i = 0; i < items.length; ++i) {
            if (String(items[i]) === String(name))
                return i
        }
        return 0
    }

    function walletLabel(name) {
        if (String(name) === "__node__")
            return "Node / global"
        return NuService.walletDisplayName(String(name))
    }

    function runCommand() {
        var command = commandLine.text.trim()
        if (command.length === 0)
            return
        NuService.runRpcConsoleCommand(command, root.selectedWalletName)
        commandLine.text = ""
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "RPC Console"
        detail: "Advanced Core commands and backend debug log."
    }

    NuTabBar {
        id: rpcTabs
        Layout.fillWidth: true
        NuTabButton { text: "RPC Console" }
        NuTabButton { text: "Debug Log" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: rpcTabs.currentIndex

        NuPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    Label {
                        text: "Wallet"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        font.weight: Font.DemiBold
                    }

                    NuComboBox {
                        id: walletSelector
                        Layout.preferredWidth: 320
                        model: root.walletModel()
                        currentIndex: root.walletIndex(root.selectedWalletName)
                        textFormatter: function(value) { return root.walletLabel(value) }
                        helpText: "Choose Node / global for non-wallet RPC commands, or a loaded wallet for wallet-scoped commands."
                        onActivated: function(index) {
                            var items = root.walletModel()
                            if (index >= 0 && index < items.length)
                                root.selectedWalletName = items[index]
                        }
                        Connections {
                            target: NuService
                            function onWalletChanged() {
                                walletSelector.model = root.walletModel()
                                walletSelector.currentIndex = root.walletIndex(root.selectedWalletName)
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    NuActionButton {
                        text: "A-"
                        Layout.preferredWidth: 54
                        helpText: "Reduce console text size."
                        onClicked: root.consoleFontSize = Math.max(9, root.consoleFontSize - 1)
                    }
                    NuActionButton {
                        text: "A+"
                        Layout.preferredWidth: 54
                        helpText: "Increase console text size."
                        onClicked: root.consoleFontSize = Math.min(22, root.consoleFontSize + 1)
                    }
                    NuActionButton {
                        text: "Clear"
                        Layout.preferredWidth: 82
                        helpText: "Clear the visible console history."
                        onClicked: NuService.clearConsoleOutput()
                    }
                }

                Basic.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: consoleOutput
                        readOnly: true
                        selectByMouse: true
                        wrapMode: Text.WrapAnywhere
                        text: NuService.consoleOutput
                        color: NuTokens.textPrimary
                        selectedTextColor: NuTokens.textInverse
                        selectionColor: NuTokens.lineStrong
                        font.family: NuTokens.monoFont
                        font.pixelSize: root.consoleFontSize
                        background: Rectangle {
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            radius: NuTokens.radiusSmall
                        }

                        Shortcut {
                            sequences: [StandardKey.Copy]
                            enabled: consoleOutput.activeFocus && consoleOutput.selectedText.length > 0
                            onActivated: NuService.copyText(consoleOutput.selectedText)
                        }
                        Keys.onPressed: (event) => {
                            if ((event.matches(StandardKey.Copy)
                                    || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C)
                                    || ((event.modifiers & Qt.MetaModifier) && event.key === Qt.Key_C))
                                    && selectedText.length > 0) {
                                NuService.copyText(selectedText)
                                event.accepted = true
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm

                    Label {
                        text: ">"
                        color: NuTokens.textPrimary
                        font.family: NuTokens.monoFont
                        font.pixelSize: root.consoleFontSize + 2
                        font.weight: Font.DemiBold
                    }

                    NuTextField {
                        id: commandLine
                        Layout.fillWidth: true
                        placeholderText: "getblockchaininfo"
                        helpText: "Enter a Core RPC command. Examples: getnetworkinfo, getbalance, listtransactions \"*\" 5, addnode host:port add."
                        onAccepted: root.runCommand()
                    }

                    NuActionButton {
                        text: "Run"
                        primary: true
                        Layout.preferredWidth: 94
                        helpText: "Run the command against the selected target."
                        onClicked: root.runCommand()
                    }
                }
            }
        }

        NuPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NuDebugLogPanel {
                anchors.fill: parent
            }
        }
    }

    Connections {
        target: NuService
        function onConsoleChanged() {
            consoleOutput.cursorPosition = consoleOutput.text.length
        }
        function onWalletChanged() {
            if (NuService.walletSelected && root.selectedWalletName === "__node__")
                return
            if (NuService.walletSelected)
                root.selectedWalletName = NuService.currentWalletName
        }
    }
}
