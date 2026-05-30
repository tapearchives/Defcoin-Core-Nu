pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"
import "../Components"

Rectangle {
    id: root
    color: NuTokens.inverseBase

    property string currentRoute: "home"
    signal routeRequested(string route)
    signal aboutRequested

    Rectangle {
        anchors.fill: parent
        color: NuTokens.inverseBase
    }

    Canvas {
        id: railGrid
        anchors.fill: parent
        opacity: 0.7

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

            ctx.strokeStyle = "rgba(246, 246, 242, 0.038)";
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
                position: 0.24
                color: "#11051d"
            }
            GradientStop {
                position: 0.62
                color: NuTokens.inverseBase
            }
            GradientStop {
                position: 1.0
                color: NuTokens.inverseBase
            }
        }
        opacity: 0.86
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
            Accessible.name: "About Defcoin Core Nu"
            Accessible.description: "Open build and application details."
            ToolTip.visible: !brandButtonMouse.suppressToolTip && (brandButtonMouse.containsMouse || activeFocus)
            ToolTip.text: "Open About Defcoin Core Nu."
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
                    route: "home",
                    label: "Home",
                    icon: "../../assets/icons/home.svg",
                    help: "Balances, recent activity, and quick wallet actions."
                },
                {
                    route: "send",
                    label: "Send",
                    icon: "../../assets/icons/send.svg",
                    help: "Create, review, and submit outgoing payments."
                },
                {
                    route: "receive",
                    label: "Receive",
                    icon: "../../assets/icons/receive.svg",
                    help: "Generate payment requests and copy wallet addresses."
                },
                {
                    route: "activity",
                    label: "Transactions",
                    icon: "../../assets/icons/activity.svg",
                    help: "Search, inspect, and export wallet transaction history."
                },
                {
                    route: "wallet",
                    label: "Wallet",
                    icon: "../../assets/icons/wallet.svg",
                    help: "Wallet files, recovery phrases, passphrases, signing, and addresses."
                },
                {
                    route: "mining",
                    label: "Mining",
                    icon: "../../assets/icons/mining.svg",
                    help: "Configure and monitor a local scrypt miner executable."
                },
                {
                    route: "explorer",
                    label: "Explorer",
                    icon: "../../assets/icons/explorer.svg",
                    help: "Search blocks, transactions, and wallet addresses with the local SQLite explorer cache."
                },
                {
                    route: "forensics",
                    label: "Forensics",
                    icon: "../../assets/icons/forensics.svg",
                    help: "Review irregular OP_RETURN messages and other blockchain oddities."
                },
                {
                    route: "node",
                    label: "Diagnostics",
                    icon: "../../assets/icons/node.svg",
                    help: "Node status, peers, traffic, log, and console access."
                },
                {
                    route: "settings",
                    label: "Settings",
                    icon: "../../assets/icons/settings.svg",
                    help: "Network, display, and update settings."
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

        Item {
            Layout.fillHeight: true
        }
    }
}
