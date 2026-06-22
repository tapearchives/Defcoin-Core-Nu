import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceMd

    signal detailsRequested

    property bool showDetailsButton: true
    property bool showOverlayText: false
    property string buildVersion: NuBuildVersion
    property string buildId: typeof NuBuildId !== "undefined" ? NuBuildId : ""
    property string codeName: "Core Memories"
    property int heroHeight: 184
    property int textHeight: 126

    readonly property string summaryText: "Defcoin Core Nu v" + root.buildVersion + " • " + root.codeName + " • Backend derives from Litecoin Core v0.21.5.5 + Defcoin parameters\n© 2014-2026 Defcoin Core developers • © 2011-2026 Litecoin Core developers • © 2009-2026 Bitcoin Core developers" + (root.buildId.length > 0 ? "\nBuild ID: " + root.buildId : "")

    Item {
        id: hero

        Layout.fillWidth: true
        Layout.preferredHeight: root.heroHeight
        Layout.minimumHeight: 130

        readonly property int brandWordmarkSize: Math.round(Math.max(30, Math.min(58, width * 0.074, height * 0.145)))

        Rectangle {
            anchors.fill: parent
            color: "#07020d"
            clip: true

            Canvas {
                id: aboutGrid
                anchors.fill: parent
                opacity: 0.68

                onPaint: {
                    const ctx = getContext("2d");
                    const step = 12;
                    ctx.clearRect(0, 0, width, height);
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = "rgba(84, 42, 132, 0.20)";
                    for (let y = 0.5; y < height; y += step) {
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }
                    ctx.strokeStyle = "rgba(246, 246, 242, 0.035)";
                    for (let x = 0.5; x < width; x += step) {
                        ctx.beginPath();
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x, height);
                        ctx.stroke();
                    }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0.0
                        color: "#07020d"
                    }
                    GradientStop {
                        position: 0.34
                        color: "#0b0314"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#05080a"
                    }
                }
                opacity: 0.92
            }
        }

        NuBrandLockup {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.showOverlayText ? -24 : 0
            wordmarkSize: hero.brandWordmarkSize
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 74
            visible: root.showOverlayText
            color: "#dc05080a"

            TextEdit {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                wrapMode: TextEdit.WordWrap
                text: root.summaryText
                color: NuTokens.textInverse
                selectedTextColor: NuTokens.inverseBase
                selectionColor: NuTokens.textInverse
                font.pixelSize: 11
            }
        }
    }

    TextArea {
        Layout.fillWidth: true
        Layout.preferredHeight: root.textHeight
        Layout.minimumHeight: root.textHeight
        visible: !root.showOverlayText
        readOnly: true
        selectByMouse: true
        wrapMode: Text.WordWrap
        text: root.summaryText
        color: NuTokens.textPrimary
        selectedTextColor: NuTokens.textInverse
        selectionColor: NuTokens.lineStrong
        font.pixelSize: NuTokens.fontBody
        background: Rectangle {
            color: "transparent"
            border.color: "transparent"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.showDetailsButton

        Item {
            Layout.fillWidth: true
        }

        NuActionButton {
            text: "Details"
            Layout.preferredWidth: 132
            helpText: "Open detailed build, feature, history, and design notes."
            onClicked: root.detailsRequested()
        }
    }
}
