import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root

    signal navigateRequested(string route)

    spacing: NuTokens.spaceLg

    function currentWalletIndex() {
        if (!NuService.walletSelected)
            return -1
        for (var i = 0; i < NuService.availableWallets.length; ++i) {
            if (String(NuService.availableWallets[i]) === NuService.currentWalletName)
                return i
        }
        return -1
    }

    function walletIsLoaded(walletName) {
        for (var i = 0; i < NuService.loadedWallets.length; ++i) {
            if (String(NuService.loadedWallets[i]) === String(walletName))
                return true
        }
        return false
    }

    function chooseWallet(walletName) {
        if (walletIsLoaded(walletName))
            NuService.setCurrentWallet(walletName)
        else
            NuService.loadWallet(walletName)
    }

    function longestWalletDisplayName() {
        var longest = "Default wallet"
        for (var i = 0; i < NuService.availableWallets.length; ++i) {
            var name = NuService.walletDisplayName(String(NuService.availableWallets[i]))
            if (name.length > longest.length)
                longest = name
        }
        return longest
    }

    TextMetrics {
        id: walletNameMetrics
        font.family: NuTokens.bodyFont
        font.pixelSize: NuTokens.fontBody
        text: root.longestWalletDisplayName()
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Home"
        detail: ""
        dense: true
    }

    Rectangle {
        Layout.fillWidth: true
        visible: NuService.showLanNodeDiscoveryNotice
        Layout.preferredHeight: visible ? lanNoticeLayout.implicitHeight + NuTokens.spaceMd * 2 : 0
        color: NuTokens.panelBase
        border.color: NuTokens.lineSubtle
        radius: NuTokens.radiusMedium

        RowLayout {
            id: lanNoticeLayout
            anchors.fill: parent
            anchors.margins: NuTokens.spaceMd
            spacing: NuTokens.spaceMd

            Label {
                Layout.fillWidth: true
                text: "Note: if you are running other Defcoin wallets on your local network, for faster blockchain synchronization go to Settings and enable LAN node discovery. This message is shown only upon first installation and will not be shown again."
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }
            NuActionButton {
                text: "Got it"
                Layout.preferredWidth: 96
                onClicked: NuService.acknowledgeLanNodeDiscoveryNotice()
            }
        }
    }

    NuPanel {
        Layout.fillWidth: true
        implicitHeight: NuService.availableWallets.length > 0 ? 188 : 154

        ColumnLayout {
            anchors.fill: parent
            spacing: NuTokens.spaceSm

            RowLayout {
                Layout.fillWidth: true
                visible: NuService.availableWallets.length > 0
                spacing: NuTokens.spaceMd

                Label {
                    text: "Wallet"
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    font.weight: Font.DemiBold
                }

                NuComboBox {
                    Layout.preferredWidth: Math.max(240, Math.min(620, walletNameMetrics.width + 82))
                    Layout.maximumWidth: 620
                    model: NuService.availableWallets
                    currentIndex: root.currentWalletIndex()
                    textFormatter: function(value) {
                        return NuService.walletDisplayName(String(value))
                    }
                    helpText: "Select or load the active wallet used by Home, Send, Receive, Transactions, and Wallet tools."
                    onActivated: function(index) {
                        if (index >= 0 && index < NuService.availableWallets.length)
                            root.chooseWallet(NuService.availableWallets[index])
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Label {
                text: "Total balance"
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontBody
            }
            Label {
                text: NuService.totalBalance
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontTitle
                font.weight: Font.DemiBold
            }
            RowLayout {
                spacing: NuTokens.spaceXl
                NuMetricRow { label: "Available"; value: NuService.availableBalance }
                NuMetricRow { label: "Pending"; value: NuService.pendingBalance }
                NuMetricRow { label: "Immature"; value: NuService.immatureBalance }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: NuTokens.spaceLg

        NuActionButton {
            Layout.preferredWidth: 160
            text: "Receive"
            primary: true
            helpText: "Create a payment request or copy a receiving address."
            onClicked: navigateRequested("receive")
        }
        NuActionButton {
            Layout.preferredWidth: 160
            text: "Send"
            helpText: "Compose a payment and review it before signing."
            onClicked: navigateRequested("send")
        }
        NuActionButton {
            Layout.preferredWidth: 180
            text: "Mask balances"
            helpText: "Hide or show balance values on this screen."
            onClicked: NuService.maskBalances = !NuService.maskBalances
        }
        Item { Layout.fillWidth: true }
    }

    NuDataTable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        tableId: "homeRecentTransactions"
        columns: ["", "Date", "Type", "Label", "Amount"]
        columnTypes: ["action", "date", "text", "text", "amount"]
        columnWeights: [0.1, 1.1, 0.65, 2.8, 1.25]
        columnMinimums: [44, 150, 70, 180, 130]
        columnMaximums: [44, 180, 110, 520, 180]
        rows: NuService.recentTransactions
        emptyText: "Recent transactions will appear here."
        onRowActivated: (row) => NuService.requestTransactionDetails(row && row.meta ? row.meta.txid : "")
    }
}
