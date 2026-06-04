pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

Rectangle {
    id: root
    color: NuTokens.inverseBase

    property string currentRoute: "home"
    signal routeRequested(string route)
    signal aboutRequested

    function isAdvancedRoute(route) {
        return route === "mining" || route === "rpc" || route === "node" || route === "settings"
    }

    function navigationItems() {
        const items = [
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
            }
        ]

        if (NuService.advancedToolsVisible) {
            items.push(
                {
                    route: "mining",
                    label: "Mining",
                    icon: "../../assets/icons/mining.svg",
                    help: "Configure and monitor a local scrypt miner executable."
                },
                {
                    route: "rpc",
                    label: "RPC Console",
                    icon: "../../assets/icons/node.svg",
                    help: "Run advanced node and wallet RPC commands through the local backend."
                },
                {
                    route: "node",
                    label: "Metrics",
                    icon: "../../assets/icons/network.svg",
                    help: "Traffic, sync status, peer details, and network health."
                },
                {
                    route: "settings",
                    label: "Settings",
                    icon: "../../assets/icons/settings.svg",
                    help: "Network, display, and update settings."
                }
            )
        }

        return items
    }

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

        Flickable {
            id: navScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: navItems.implicitHeight

            ScrollBar.vertical: ScrollBar {
                policy: navScroll.contentHeight > navScroll.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: navItems
                width: navScroll.width
                spacing: NuTokens.spaceSm

                Repeater {
                    model: root.navigationItems()

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
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(48, advancedToggle.implicitHeight + NuTokens.spaceMd)
            radius: NuTokens.radiusSmall
            color: NuService.advancedToolsVisible
                   ? Qt.rgba(NuTokens.accentSky.r, NuTokens.accentSky.g, NuTokens.accentSky.b, advancedMouse.containsMouse ? 0.24 : 0.17)
                   : (advancedMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.055))
            border.color: NuService.advancedToolsVisible ? NuTokens.accentSky : Qt.rgba(255, 255, 255, advancedMouse.containsMouse ? 0.28 : 0.16)
            border.width: 1

            ToolTip.visible: advancedMouse.containsMouse
            ToolTip.text: NuService.advancedToolsVisible
                          ? "Hide Mining, RPC Console, Metrics, and Settings from the left menu."
                          : "Show Mining, RPC Console, Metrics, and Settings."
            ToolTip.delay: NuTokens.tooltipDelay
            ToolTip.timeout: NuTokens.tooltipTimeout

            MouseArea {
                id: advancedMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: advancedToggle.toggle()
            }

            NuCheckBox {
                id: advancedToggle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: NuTokens.spaceSm
                anchors.rightMargin: NuTokens.spaceSm
                text: "Advanced tools"
                inverse: true
                checked: NuService.advancedToolsVisible
                helpText: "Show or hide Mining, RPC Console, Metrics, and Settings in the main menu."
                onToggled: {
                    NuService.advancedToolsVisible = checked
                    if (!checked && root.isAdvancedRoute(root.currentRoute))
                        root.routeRequested("home")
                }
            }
        }
    }
}
