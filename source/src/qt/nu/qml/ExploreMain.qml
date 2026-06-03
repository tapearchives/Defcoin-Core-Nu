import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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
