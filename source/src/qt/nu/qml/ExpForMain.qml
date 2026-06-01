pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
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
    title: "Defcoin Core ExpFor"
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
    readonly property string trademarkNotice: "Defcoin Core ExpFor is an adjunct explorer and forensics interface for local Defcoin Core Nu data. It uses the same local backend and SQLite explorer cache surfaces, but keeps heavy indexing and analysis away from the wallet-first Nu shell."

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
        return "Defcoin Core ExpFor v" + root.buildVersion + " - local explorer, indexing, forensics, and contact graph analysis for Defcoin Core Nu."
    }

    function openHelpManual() {
        messageDialog.title = "Help not included"
        messageDialog.text = "ExpFor currently reuses the Nu explorer and forensics screens. Build notes remain in Defcoin Core Nu."
        messageDialog.open()
    }

    function openDetailedAbout() {
        root.openAboutSummary()
    }

    ExpForFrame {
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
            const explorerWindow = explorerWindowComponent.createObject(root, {
                "title": title,
                "explorerHtml": html
            })
            if (explorerWindow) explorerWindow.show()
        }
    }

    Component {
        id: explorerWindowComponent

        Window {
            id: explorerWindow
            width: 920
            height: 700
            minimumWidth: 720
            minimumHeight: 520
            color: NuTokens.backgroundBase
            property string explorerHtml: ""

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceLg
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: explorerWindow.title
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTitle
                        font.weight: Font.DemiBold
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 2
                    }
                    NuActionButton {
                        text: qsTr("Close")
                        Layout.preferredWidth: 112
                        onClicked: explorerWindow.close()
                    }
                }

                Basic.ScrollView {
                    id: explorerScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
                    clip: true

                    TextEdit {
                        width: Math.max(1, explorerScroll.availableWidth)
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        textFormat: TextEdit.RichText
                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                        text: explorerWindow.explorerHtml
                        color: NuTokens.textPrimary
                        selectedTextColor: NuTokens.textInverse
                        selectionColor: NuTokens.lineStrong
                        font.pixelSize: NuTokens.fontBody
                        onLinkActivated: NuService.openExplorerLink(link)
                    }
                }
            }
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
        title: "About Defcoin Core ExpFor"
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
