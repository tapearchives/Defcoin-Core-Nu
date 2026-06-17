import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"
import "../Components"

Rectangle {
    id: root
    color: "#080313"

    property string currentRoute: "explorer"
    readonly property var lookupRoutes: [
        {
            route: "explorer",
            label: "Explorer Search",
            icon: "../../assets/icons/explorer.svg",
            help: "Look up block heights, block hashes, transaction IDs, wallet addresses, and recent searches."
        }
    ]
    readonly property var analysisRoutes: [
        {
            route: "pulse",
            label: "Network Pulse",
            icon: "../../assets/icons/activity.svg",
            help: "Monitor hashrate, difficulty, block spacing, and indexed macro network history."
        },
        {
            route: "holders",
            label: "Holder Atlas",
            icon: "../../assets/icons/explorer.svg",
            help: "Study largest holder ranks, supply bands, concentration, and holder timeline checkpoints."
        },
        {
            route: "movements",
            label: "Movement Map",
            icon: "../../assets/icons/activity.svg",
            help: "Trace large DFC transfers, movement tables, and address-to-address flow graphs."
        },
        {
            route: "coindroids",
            label: "Droid Trails",
            icon: "../../assets/icons/forensics.svg",
            help: "Discover Coindroids-era action endpoints, payout swarms, candidate winners, and transaction evidence."
        }
    ]
    readonly property var communityRoutes: [
        {
            route: "reddit",
            label: "/r/Defcoin",
            icon: "../../assets/icons/activity.svg",
            help: "Scan Defcoin community history from the subreddit event index and annual DEF CON anchors."
        }
    ]
    readonly property var evidenceRoutes: [
        {
            route: "messages",
            label: "Message Scan",
            icon: "../../assets/icons/forensics.svg",
            help: "Inspect unusual OP_RETURN text, burned outputs, and irregular accepted-chain messages."
        },
        {
            route: "contacts",
            label: "Contacts",
            icon: "../../assets/icons/wallet.svg",
            help: "Build local contact and address-cluster lists from wallet labels or investigation notes."
        }
    ]
    readonly property var operationsRoutes: [
        {
            route: "indexing",
            label: "Index Engines",
            icon: "../../assets/icons/sync.svg",
            help: "Monitor Explorer, Holder Atlas, movement, and forensics indexing jobs and tune long runs."
        },
        {
            route: "paper",
            label: "Paper Wallet",
            icon: "../../assets/icons/qr.svg",
            help: "Generate and print a branded Defcoin paper wallet with local entropy."
        },
        {
            route: "witness",
            label: "Witness Repair",
            icon: "../../assets/icons/warning.svg",
            help: "Inspect and repair missing witness data when imported block data needs maintenance."
        }
    ]

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
            Accessible.name: "About Defcoin Core Nu Explore"
            Accessible.description: "Open build and application details."
            ToolTip.visible: !brandButtonMouse.suppressToolTip && (brandButtonMouse.containsMouse || activeFocus)
            ToolTip.text: "Open About Defcoin Core Nu Explore."
            ToolTip.delay: NuTokens.tooltipDelay
            ToolTip.timeout: NuTokens.tooltipTimeout

            NuBrandLockup {
                id: brandLockup
                anchors.left: parent.left
                anchors.top: parent.top
                thirdLine: "EXPLORE"
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

        Component {
            id: navButtonDelegate
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
                policy: navScroll.contentHeight > navScroll.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: navItems
                width: navScroll.width
                spacing: NuTokens.spaceSm

                Label {
                    Layout.fillWidth: true
                    text: "LOOK UP"
                    color: "#dccfee"
                    font.pixelSize: NuTokens.fontTiny
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Repeater { model: root.lookupRoutes; delegate: navButtonDelegate }

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: NuTokens.spaceXs
                    text: "ANALYZE"
                    color: "#dccfee"
                    font.pixelSize: NuTokens.fontTiny
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Repeater { model: root.analysisRoutes; delegate: navButtonDelegate }

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: NuTokens.spaceXs
                    text: "COMMUNITY"
                    color: "#dccfee"
                    font.pixelSize: NuTokens.fontTiny
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Repeater { model: root.communityRoutes; delegate: navButtonDelegate }

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: NuTokens.spaceXs
                    text: "EVIDENCE"
                    color: "#dccfee"
                    font.pixelSize: NuTokens.fontTiny
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Repeater { model: root.evidenceRoutes; delegate: navButtonDelegate }

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: NuTokens.spaceXs
                    text: "OPERATIONS"
                    color: "#dccfee"
                    font.pixelSize: NuTokens.fontTiny
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Repeater { model: root.operationsRoutes; delegate: navButtonDelegate }
            }
        }
    }
}
