import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Components"
import "../Theme"
import "../Views"

Item {
    id: root

    property string currentRoute: "home"
    property string pendingRoute: ""
    property int nodeInitialTab: 0
    property int peerInitialView: 0
    readonly property int pageMargin: width < 1280 ? NuTokens.spaceLg : NuTokens.spaceXl
    readonly property int railWidth: width < 1280 ? 204 : 216

    signal aboutRequested
    signal createWalletRequested
    signal restoreRecoveryWalletRequested

    function routeIndex(route) {
        switch (route) {
        case "send": return 1
        case "receive": return 2
        case "activity": return 3
        case "wallet": return 4
        case "mining": return 5
        case "rpc": return 6
        case "node": return 7
        case "settings": return 8
        default: return 0
        }
    }

    function openUri(uri) {
        root.currentRoute = "send"
        sendView.loadUri(uri)
    }

    function uiSelfTestOpenPaperWalletTab() {
        root.currentRoute = "wallet"
        walletView.requestWalletTab(2)
    }

    function uiSelfTestOpenSettingsTab(tabName) {
        root.currentRoute = "settings"
        const clean = String(tabName || "").toLowerCase()
        settingsView.openTab(clean === "display" ? 1 : clean === "updates" ? 2 : 0)
    }

    function uiSelfTestOpenMiningTab(tabName) {
        root.currentRoute = "mining"
        miningView.requestMiningTab(tabName)
    }

    function requestRoute(route) {
        if (route === root.currentRoute)
            return
        if (NuService.paperWalletReady) {
            root.pendingRoute = route
            leavePaperWalletKeysDialog.open()
            return
        }
        root.currentRoute = route
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        NavigationRail {
            id: nav
            Layout.preferredWidth: root.railWidth
            Layout.fillHeight: true
            currentRoute: root.currentRoute
            onRouteRequested: (route) => root.requestRoute(route)
            onAboutRequested: root.aboutRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.pageMargin
                spacing: NuTokens.spaceLg

                StatusStrip {
                    Layout.fillWidth: true
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    currentIndex: root.routeIndex(root.currentRoute)

                    HomeView {
                        onNavigateRequested: (route) => root.requestRoute(route)
                    }
                    SendView {
                        id: sendView
                    }
                    ReceiveView {}
                    ActivityView {}
                    WalletView {
                        id: walletView
                        onCreateWalletRequested: root.createWalletRequested()
                        onRestoreRecoveryWalletRequested: root.restoreRecoveryWalletRequested()
                    }
                    MiningView {
                        id: miningView
                    }
                    RpcConsoleView {}
                    NodeView {
                        initialTab: root.nodeInitialTab
                        initialPeerView: root.peerInitialView
                    }
                    SettingsView {
                        id: settingsView
                    }
                }
            }
        }
    }

    NuDialog {
        id: leavePaperWalletKeysDialog
        title: "Leave Paper Wallet?"
        acceptText: "Erase Keys and Leave"
        cancelText: "Return to Paper Wallet"
        dialogWidth: 660

        Label {
            Layout.fillWidth: true
            text: "Generated paper-wallet private keys are still in memory. If you leave now, Nu will clear them and they cannot be printed or recovered from this session."
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: "Cancel if you still need to print, fund, or review these paper wallets."
            color: NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            NuService.clearPaperWallet()
            if (root.pendingRoute.length > 0)
                root.currentRoute = root.pendingRoute
            root.pendingRoute = ""
        }
        onRejected: {
            root.pendingRoute = ""
            root.currentRoute = "wallet"
        }
    }
}
