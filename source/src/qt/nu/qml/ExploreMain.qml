import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Defcoin.Nu 1.0

import "Shell"
import "Theme"
import "Components"

ApplicationWindow {
    id: root
    visible: true
    width: 1440
    height: 820
    minimumWidth: 1240
    minimumHeight: 680
    title: "Defcoin Core Nu Explore"
    color: NuTokens.backgroundBase

    property alias currentRoute: frame.currentRoute
    property alias nodeInitialTab: frame.nodeInitialTab
    property alias peerInitialView: frame.peerInitialView
    property string buildVersion: NuBuildVersion
    property string buildId: NuBuildId
    property string buildTimestamp: NuBuildTimestamp
    property string gitCommit: NuGitCommit
    property bool quitRequested: false
    readonly property string releaseCodeName: "Core Memories"
    readonly property string trademarkNotice: "Defcoin Core Nu Explore is an adjunct explorer and forensics interface for local Defcoin Core Nu data. It uses the same local backend and SQLite explorer cache surfaces, but keeps heavy indexing and analysis away from the wallet-first Nu shell."

    palette.window: NuTokens.panelBase
    palette.base: NuTokens.panelBase
    palette.alternateBase: NuTokens.backgroundBase
    palette.text: NuTokens.textPrimary
    palette.windowText: NuTokens.textPrimary
    palette.button: NuTokens.panelBase
    palette.buttonText: NuTokens.textPrimary
    palette.highlight: NuTokens.lineStrong
    palette.highlightedText: NuTokens.textInverse

    onClosing: function(close) {
        if (!root.quitRequested) {
            close.accepted = false
            root.requestQuit()
        }
    }

    function runEditAction(actionName) {
        var target = root.activeFocusItem
        if (!target)
            return
        while (target && target.parent
               && !(actionName === "undo" && target.undo)
               && !(actionName === "redo" && target.redo)
               && !(actionName === "cut" && target.cut)
               && !(actionName === "copy" && target.copy)
               && !(actionName === "paste" && target.paste))
            target = target.parent
        try {
            if (actionName === "undo" && target.undo) target.undo()
            else if (actionName === "redo" && target.redo) target.redo()
            else if (actionName === "cut" && target.cut) target.cut()
            else if (actionName === "copy" && target.copy) target.copy()
            else if (actionName === "paste" && target.paste) target.paste()
        } catch (e) {
        }
    }

    function openPreferences() {
        frame.currentRoute = "indexing"
    }

    function closeMainWindow() {
        root.close()
    }

    function requestQuit() {
        root.quitRequested = true
        NuPlatform.quitApplication()
    }

    function openAboutSummary() {
        aboutDialog.open()
    }

    function basicAboutText() {
        return "Defcoin Core Nu Explore v" + root.buildVersion + " - local explorer, indexing, forensics, and contact graph analysis for Defcoin Core Nu."
    }

    function openHelpManual() {
        messageDialog.title = "Help not included"
        messageDialog.text = "Explore currently reuses the Nu explorer and forensics screens. Build notes remain in Defcoin Core Nu."
        messageDialog.open()
    }

    function openDetailedAbout() {
        root.openAboutSummary()
    }

    function uiSelfTestClosePopups() {
        messageDialog.close()
        aboutDialog.close()
        frame.closePaperWalletPopoutForUiSelfTest()
    }

    function uiSelfTestOpenPaperWalletPopout() {
        frame.openPaperWalletPopoutForUiSelfTest()
    }

    function uiSelfTestClosePaperWalletPopout() {
        frame.closePaperWalletPopoutForUiSelfTest()
    }

    function uiSelfTestOpenMenuDialog(name) {
        var target = String(name)
        if (target === "brand-button") {
            frame.aboutRequested()
        } else if (target === "about") {
            root.openAboutSummary()
        } else if (target === "help") {
            root.openHelpManual()
        } else if (target === "about-details") {
            root.openDetailedAbout()
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("File")
            NuMenuItem {
                text: Qt.platform.os === "osx" ? qsTr("Close Window") : qsTr("Exit")
                shortcut: Qt.platform.os === "osx" ? "Meta+W" : "Alt+F4"
                onTriggered: Qt.platform.os === "osx" ? root.closeMainWindow() : root.requestQuit()
            }
        }

        Menu {
            title: qsTr("Edit")
            NuMenuItem { text: qsTr("Undo"); shortcut: StandardKey.Undo; onTriggered: root.runEditAction("undo") }
            NuMenuItem { text: qsTr("Redo"); shortcut: StandardKey.Redo; onTriggered: root.runEditAction("redo") }
            MenuSeparator {}
            NuMenuItem { text: qsTr("Cut"); shortcut: StandardKey.Cut; onTriggered: root.runEditAction("cut") }
            NuMenuItem { text: qsTr("Copy"); shortcut: StandardKey.Copy; onTriggered: root.runEditAction("copy") }
            NuMenuItem { text: qsTr("Paste"); shortcut: StandardKey.Paste; onTriggered: root.runEditAction("paste") }
            MenuSeparator { visible: Qt.platform.os !== "osx"; height: visible ? implicitHeight : 0 }
            NuMenuItem {
                text: Qt.platform.os === "windows" ? qsTr("Settings") : qsTr("Preferences")
                shortcut: "Ctrl+,"
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: root.openPreferences()
            }
        }

        Menu {
            title: qsTr("View")
            NuMenuItem { text: qsTr("Explorer Search"); shortcut: Qt.platform.os === "osx" ? "Meta+1" : "Ctrl+1"; onTriggered: frame.currentRoute = "explorer" }
            NuMenuItem { text: qsTr("Network Pulse"); shortcut: Qt.platform.os === "osx" ? "Meta+2" : "Ctrl+2"; onTriggered: frame.currentRoute = "pulse" }
            NuMenuItem { text: qsTr("Holder Atlas"); shortcut: Qt.platform.os === "osx" ? "Meta+3" : "Ctrl+3"; onTriggered: frame.currentRoute = "holders" }
            NuMenuItem { text: qsTr("Movement Map"); shortcut: Qt.platform.os === "osx" ? "Meta+4" : "Ctrl+4"; onTriggered: frame.currentRoute = "movements" }
            NuMenuItem { text: qsTr("Droid Trails"); shortcut: Qt.platform.os === "osx" ? "Meta+5" : "Ctrl+5"; onTriggered: frame.currentRoute = "coindroids" }
            MenuSeparator {}
            NuMenuItem { text: qsTr("/r/Defcoin"); shortcut: Qt.platform.os === "osx" ? "Meta+6" : "Ctrl+6"; onTriggered: frame.currentRoute = "reddit" }
            NuMenuItem { text: qsTr("Message Scan"); shortcut: Qt.platform.os === "osx" ? "Meta+7" : "Ctrl+7"; onTriggered: frame.currentRoute = "messages" }
            NuMenuItem { text: qsTr("Contacts"); shortcut: Qt.platform.os === "osx" ? "Meta+8" : "Ctrl+8"; onTriggered: frame.currentRoute = "contacts" }
            MenuSeparator {}
            NuMenuItem { text: qsTr("Index Engines"); shortcut: Qt.platform.os === "osx" ? "Meta+9" : "Ctrl+9"; onTriggered: frame.currentRoute = "indexing" }
            NuMenuItem { text: qsTr("Paper Wallet"); shortcut: Qt.platform.os === "osx" ? "Meta+0" : "Ctrl+0"; onTriggered: frame.currentRoute = "paper" }
            NuMenuItem { text: qsTr("Witness Repair"); onTriggered: frame.currentRoute = "witness" }
        }

        Menu {
            id: macWindowMenu
            title: qsTr("Window")
            Component.onCompleted: {
                if (Qt.platform.os !== "osx") macWindowMenu.destroy()
            }
            NuMenuItem { text: qsTr("Minimize"); shortcut: "Meta+M"; onTriggered: root.showMinimized() }
            NuMenuItem {
                text: qsTr("Zoom")
                onTriggered: {
                    if (root.visibility === Window.Maximized)
                        root.showNormal()
                    else
                        root.showMaximized()
                }
            }
        }

        Menu {
            title: qsTr("Help")
            NuMenuItem {
                text: qsTr("Check for Updates...")
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: NuService.checkForUpdates(true)
            }
            MenuSeparator { visible: Qt.platform.os !== "osx"; height: visible ? implicitHeight : 0 }
            NuMenuItem {
                text: qsTr("Developer Documentation")
                visible: Qt.platform.os === "osx"
                height: visible ? implicitHeight : 0
                onTriggered: NuService.openExternalUrl("https://github.com/DefcoinCore/Defcoin-Core-Nu/tree/main/doc")
            }
            NuMenuItem {
                text: qsTr("About Defcoin Core Nu Explore")
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: root.openAboutSummary()
            }
            NuMenuItem {
                text: qsTr("About Qt")
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: NuPlatform.showAboutQt()
            }
        }
    }

    ExploreFrame {
        id: frame
        anchors.fill: parent
        onAboutRequested: root.openAboutSummary()
    }

    Connections {
        target: NuService
        function onUserMessage(title, message) {
            messageDialog.title = title
            messageDialog.text = message
            messageDialog.open()
        }
        function onExplorerWindowRequested(title, html) {
            frame.showExplorerResult(title, html)
        }
    }

    NuDialog {
        id: messageDialog
        showCancel: false
        dialogWidth: 700
        property alias text: messageText.text

        TextEdit {
            id: messageText
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(1, messageDialog.availableWidth)
            width: Math.max(1, messageDialog.availableWidth)
            Layout.preferredHeight: Math.min(Math.max(contentHeight + NuTokens.spaceSm, 104), Math.max(160, root.height - 300))
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            color: NuTokens.textPrimary
            selectedTextColor: NuTokens.textInverse
            selectionColor: NuTokens.lineStrong
            font.pixelSize: NuTokens.fontBody
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            textFormat: TextEdit.PlainText
        }
    }

    NuDialog {
        id: aboutDialog
        title: "About Defcoin Core Nu Explore"
        showCancel: false
        acceptText: "Close"
        dialogWidth: 760
        height: Math.min(root.height - 96, 640)
        anchors.centerIn: parent
        padding: NuTokens.spaceLg
        background: Rectangle {
            color: NuTokens.panelBase
            border.color: NuTokens.lineStrong
            radius: NuTokens.radiusLarge
        }

        contentItem: ColumnLayout {
            spacing: NuTokens.spaceMd

            NuAboutSummary {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(405, aboutDialog.height - 200)
                showDetailsButton: false
                showOverlayText: true
                buildVersion: root.buildVersion
                buildId: root.buildId
                codeName: root.releaseCodeName
                heroHeight: Math.min(405, aboutDialog.height - 200)
                textHeight: 0
            }

            TextEdit {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(56, implicitHeight)
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                wrapMode: TextEdit.WordWrap
                text: root.trademarkNotice
                color: NuTokens.textSecondary
                selectedTextColor: NuTokens.textInverse
                selectionColor: NuTokens.lineStrong
                font.pixelSize: NuTokens.fontSmall
            }
        }
    }
}
