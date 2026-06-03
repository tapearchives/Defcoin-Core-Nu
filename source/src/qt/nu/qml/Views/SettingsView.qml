import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg
    property bool helpEnabled: NuHelpEnabled
    function delimiterStyleIndex(style) {
        const values = ["csv", "tsv", "pipe", "semicolon", "custom"]
        const index = values.indexOf(String(style).toLowerCase())
        return index >= 0 ? index : 1
    }
    function delimiterStyleAt(index) {
        const values = ["csv", "tsv", "pipe", "semicolon", "custom"]
        return index >= 0 && index < values.length ? values[index] : "tsv"
    }
    function explorerModeIndex(mode) {
        const values = ["internal", "dc903", "legacy", "custom"]
        const index = values.indexOf(String(mode).toLowerCase())
        return index >= 0 ? index : 0
    }
    function explorerModeAt(index) {
        const values = ["internal", "dc903", "legacy", "custom"]
        return index >= 0 && index < values.length ? values[index] : "internal"
    }
    NuPageHeader {
        Layout.fillWidth: true
        title: "Settings"
        detail: "Network, display, and update preferences."
    }

    NuTabBar {
        id: tabs
        Layout.fillWidth: true
        NuTabButton { text: "Network" }
        NuTabButton { text: "Display" }
        NuTabButton { text: "Updates" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: tabs.currentIndex

        NuPanel {
            ScrollView {
                id: networkScroll
                anchors.fill: parent
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: networkScroll.availableWidth
                    spacing: NuTokens.spaceLg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm

                        Label {
                            text: "Network state"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBody
                            font.weight: Font.DemiBold
                        }

                        NuStatusDot {
                            label: NuService.networkState === "connected" ? "Network connected" : "Network isolated"
                            stateColor: NuService.networkState === "connected" ? NuTokens.stateConnected : NuTokens.stateError
                        }

                        RowLayout {
                            spacing: NuTokens.spaceMd

                            NuActionButton {
                                text: "Connect"
                                Layout.preferredWidth: 130
                                primary: NuService.networkState !== "connected"
                                helpText: "Enable P2P network activity."
                                onClicked: NuService.setNetworkActive(true)
                            }

                            NuActionButton {
                                text: "Isolate"
                                Layout.preferredWidth: 130
                                danger: NuService.networkState === "connected"
                                helpText: "Disable P2P network activity without closing the wallet."
                                onClicked: NuService.setNetworkActive(false)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm

                        Label {
                            text: "Peer compatibility"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBody
                            font.weight: Font.DemiBold
                        }

                        NuCheckBox {
                            text: "Only show and accept peers whose user agent begins with /Defcoin"
                            checked: NuService.onlyDefcoinUserAgents
                            helpText: "Filters peers by the Defcoin user-agent prefix before accepting their address relay data."
                            onToggled: NuService.onlyDefcoinUserAgents = checked
                        }

                        NuCheckBox {
                            text: "Only use Defcoin magic bytes"
                            checked: NuService.onlyDefcoinMagicBytes
                            helpText: "On accepts only Defcoin-specific defc014e magic and reduces legacy peer pollution. Off enables dual-magic compatibility for old wallets, but can admit more polluted peers. Pool and seed servers can bridge legacy wallets, so most users should not need legacy mode."
                            onToggled: NuService.onlyDefcoinMagicBytes = checked
                        }

                        NuCheckBox {
                            text: "Switch to Defcoin-only magic starting July 1, 2026"
                            checked: NuService.switchToDefcoinOnlyMagicStartingJuly2026
                            helpText: "Recommended. On or after July 1, 2026, Nu automatically enables Defcoin-only magic before networking starts. Unchecking keeps legacy dual-magic available longer, which can help old wallets but may add peer pollution; pool and seed servers can usually provide that bridge."
                            onToggled: NuService.switchToDefcoinOnlyMagicStartingJuly2026 = checked
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: NuTokens.lineSubtle
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm

                        Label {
                            text: "Connectivity"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBody
                            font.weight: Font.DemiBold
                        }

                        NuCheckBox {
                            text: "Enable LAN node discovery"
                            checked: NuService.lanNodeDiscoveryEnabled
                            helpText: "Off by default. Turn this on when another Defcoin wallet on your local network can help this wallet find peers or identify LAN workstation names. macOS or Windows may ask for local network/firewall permission. Public UDP Fast Sync remains separate from this LAN discovery permission."
                            onToggled: NuService.lanNodeDiscoveryEnabled = checked
                        }

                        NuCheckBox {
                            text: "Enable UDP fast sync"
                            checked: NuService.lanFastSyncEnabled
                            helpText: "On by default. Experimental. Nu can request checksum-protected raw block chunks over UDP port 10334 from connected Defcoin peers over IPv4 or IPv6. Peers must advertise the Defcoin Fast Sync service bit and return a valid UDP response before Nu treats them as usable. Every block is still submitted through normal Core validation, and TCP sync remains the fallback."
                            onToggled: NuService.lanFastSyncEnabled = checked
                        }

                        NuCheckBox {
                            text: "Enable UPnP port mapping"
                            checked: NuService.upnpConnectionsEnabled
                            helpText: "Off by default. UPnP asks a compatible router to open Defcoin's peer port for inbound connections. Leave it off on restricted, shared, or untrusted networks."
                            onToggled: NuService.upnpConnectionsEnabled = checked
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Peer compatibility and connectivity settings are saved and applied to the running backend when RPC is connected."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontBody
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg
                Label {
                    Layout.fillWidth: true
                    text: "Nu uses a neutral high-contrast interface designed for legibility, clear hierarchy, and fewer visual distractions."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm

                    Label {
                        text: "Window behavior"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBody
                        font.weight: Font.DemiBold
                    }

                    NuCheckBox {
                        text: Qt.platform.os === "osx" ? "Keep running in the menu bar when window is closed" : "Minimize to System Tray when closing the window"
                        checked: NuService.backgroundCloseEnabled
                        enabled: NuPlatform.trayAvailable
                        helpText: Qt.platform.os === "osx"
                                  ? "When enabled, closing the window keeps Defcoin Core Nu running from the macOS menu bar status item so the node can stay synchronized."
                                  : "When enabled, closing the window keeps Defcoin Core Nu running from the system tray so the node can stay synchronized."
                        onToggled: NuService.backgroundCloseEnabled = checked
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: NuTokens.lineSubtle
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm

                    Label {
                        text: "Explorer links"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBody
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: NuTokens.spaceMd
                        columnSpacing: NuTokens.spaceLg

                        Label {
                            text: "Open explorer links with"
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontBody
                        }
                        NuComboBox {
                            id: explorerMode
                            Layout.fillWidth: true
                            model: ["Nu Explore app", "External: DC903 Explorer", "External: Legacy Explorer", "External: Custom URL"]
                            currentIndex: root.explorerModeIndex(NuService.explorerMode)
                            helpText: "Nu Explore is the default local lookup target. It opens the adjunct Defcoin Core Nu Explore app for address, transaction, and block details. External choices open a browser."
                            onActivated: function(index) {
                                NuService.setExplorerMode(root.explorerModeAt(index))
                            }
                            Connections {
                                target: NuService
                                function onSettingsChanged() {
                                    explorerMode.currentIndex = root.explorerModeIndex(NuService.explorerMode)
                                }
                            }
                        }

                        Label {
                            text: "External transaction URL"
                            visible: NuService.explorerMode === "custom"
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontBody
                        }
                        NuTextField {
                            id: explorerUrl
                            Layout.fillWidth: true
                            visible: NuService.explorerMode === "custom"
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            text: NuService.thirdPartyTxUrl
                            placeholderText: "https://example.invalid/tx/%s"
                            helpText: "Use %s where the transaction ID should be inserted. Address links are derived from the same template."
                            onEditingFinished: {
                                NuService.thirdPartyTxUrl = text
                                NuService.setExplorerMode("custom")
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: NuService.explorerMode === "internal"
                              ? "Nu Explore lookups stay local, open in the separate Explore app, and use the local SQLite cache at: " + NuService.explorerDatabasePath
                              : (NuService.thirdPartyTxUrl.indexOf("%s") < 0
                                 ? "External explorer links need a URL template containing %s."
                                 : "External explorer links open in the system browser.")
                        color: NuService.explorerMode !== "internal" && NuService.thirdPartyTxUrl.indexOf("%s") < 0 ? NuTokens.stateWarning : NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: NuTokens.lineSubtle
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm

                    Label {
                        text: "Table behavior"
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontBody
                        font.weight: Font.DemiBold
                    }

                    NuActionButton {
                        text: "Reset widths"
                        Layout.preferredWidth: 168
                        helpText: "Forget saved table column widths, remove active table sorts, and restore first-launch table defaults."
                        onClicked: NuService.resetTableColumnWidths("")
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: NuTokens.spaceMd
                        columnSpacing: NuTokens.spaceLg

                        Label {
                            text: "Table copy delimiter"
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontBody
                        }
                        NuComboBox {
                            id: delimiterStyle
                            Layout.fillWidth: true
                            model: ["CSV", "TSV", "|", ";", "Custom"]
                            currentIndex: root.delimiterStyleIndex(NuService.tableCopyDelimiterStyle)
                            helpText: "Choose how copied table columns are separated when multiple cells, rows, or columns are copied."
                            onActivated: function(index) {
                                NuService.tableCopyDelimiterStyle = root.delimiterStyleAt(index)
                            }
                            Connections {
                                target: NuService
                                function onSettingsChanged() {
                                    delimiterStyle.currentIndex = root.delimiterStyleIndex(NuService.tableCopyDelimiterStyle)
                                }
                            }
                        }

                        Label {
                            text: "Custom delimiter"
                            visible: NuService.tableCopyDelimiterStyle === "custom"
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontBody
                        }
                        NuTextField {
                            id: customDelimiter
                            Layout.fillWidth: true
                            visible: NuService.tableCopyDelimiterStyle === "custom"
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            text: NuService.tableCopyCustomDelimiter
                            maximumLength: 15
                            placeholderText: "|"
                            helpText: "Delimiter inserted between copied table columns when Custom is selected. Up to 15 characters."
                            onEditingFinished: NuService.tableCopyCustomDelimiter = text
                        }
                    }
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                Label {
                    Layout.fillWidth: true
                    text: "Nu checks GitHub and Velopack metadata for newer Defcoin Core Nu packages. Automatic checks run after launch when enabled."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                NuCheckBox {
                    text: "Check for wallet updates at startup"
                    checked: NuService.automaticUpdateChecksEnabled
                    helpText: "On by default. Nu checks for Defcoin Core Nu releases after launch and uses Velopack when the app was installed with it; otherwise it falls back to verified GitHub packages."
                    onToggled: NuService.automaticUpdateChecksEnabled = checked
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    NuActionButton {
                        text: "Check now"
                        Layout.preferredWidth: 150
                        helpText: "Check for the latest Defcoin Core Nu package now."
                        onClicked: NuService.checkForUpdates(true)
                    }

                    Label {
                        Layout.fillWidth: true
                        text: NuService.updateStatus.length > 0 ? NuService.updateStatus : "Manual update checks are available from the app menu on macOS and the Help menu on Windows and Linux."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
