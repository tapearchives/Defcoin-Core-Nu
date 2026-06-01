pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"
import "../Components"

Rectangle {
    id: root
    color: "#080313"

    property string currentRoute: "forensics"
    signal routeRequested(string route)
    signal aboutRequested

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#13051f" }
            GradientStop { position: 0.42; color: "#0b0617" }
            GradientStop { position: 1.0; color: "#07020d" }
        }
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.82
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = 1
            ctx.strokeStyle = "rgba(184, 113, 255, 0.13)"
            for (let x = -height; x < width; x += 18) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x + height, height)
                ctx.stroke()
            }
            ctx.strokeStyle = "rgba(75, 190, 255, 0.08)"
            for (let x2 = 0; x2 < width + height; x2 += 24) {
                ctx.beginPath()
                ctx.moveTo(x2, 0)
                ctx.lineTo(x2 - height, height)
                ctx.stroke()
            }
            ctx.fillStyle = "rgba(243, 212, 71, 0.12)"
            for (let y = 10; y < height; y += 28) {
                for (let dx = 10; dx < width; dx += 28) {
                    ctx.beginPath()
                    ctx.arc(dx, y, 1.15, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Rectangle {
        anchors.fill: parent
        color: "#06020a"
        opacity: 0.36
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NuTokens.spaceLg
        spacing: NuTokens.spaceMd

        Item {
            id: brandButton
            Layout.preferredWidth: brandLockup.implicitWidth
            Layout.preferredHeight: brandLockup.implicitHeight
            Layout.bottomMargin: NuTokens.spaceLg
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: "About Defcoin Core ExpFor"
            Accessible.description: "Open build and application details."
            ToolTip.visible: !brandButtonMouse.suppressToolTip && (brandButtonMouse.containsMouse || activeFocus)
            ToolTip.text: "Open About Defcoin Core ExpFor."
            ToolTip.delay: NuTokens.tooltipDelay
            ToolTip.timeout: NuTokens.tooltipTimeout

            NuBrandLockup {
                id: brandLockup
                anchors.left: parent.left
                anchors.top: parent.top
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                color: "transparent"
                border.color: brandButton.activeFocus ? NuTokens.lineStrong : "transparent"
                border.width: brandButton.activeFocus ? 2 : 0
                radius: NuTokens.radiusSmall
            }

            MouseArea {
                id: brandButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool suppressToolTip: false
                onClicked: {
                    suppressToolTip = true
                    root.aboutRequested()
                }
                onContainsMouseChanged: if (!containsMouse) suppressToolTip = false
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.aboutRequested()
                    event.accepted = true
                }
            }
        }

        Repeater {
            model: [
                {
                    route: "forensics",
                    label: "Forensics",
                    icon: "../../assets/icons/forensics.svg",
                    help: "Irregular blockchain messages, witness inspection, and relationship/contact analysis."
                },
                {
                    route: "explorer",
                    label: "Explorer",
                    icon: "../../assets/icons/explorer.svg",
                    help: "Search blocks, transactions, addresses, Top 100, and movement data."
                },
                {
                    route: "indexing",
                    label: "Indexing",
                    icon: "../../assets/icons/sync.svg",
                    help: "Build, pause, reset, and tune the local SQLite explorer indexes."
                }
            ]

            NuNavButton {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.label
                iconSource: modelData.icon
                helpText: modelData.help
                selected: root.currentRoute === modelData.route
                onClicked: root.routeRequested(modelData.route)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
