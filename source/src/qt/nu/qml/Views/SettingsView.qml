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

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: quickCloneCard.implicitHeight + NuTokens.spaceMd * 2
                            radius: NuTokens.radiusMedium
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            border.width: 1

                            ColumnLayout {
                                id: quickCloneCard
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: NuTokens.spaceMd
                                spacing: NuTokens.spaceSm

                                Label {
                                    Layout.fillWidth: true
                                    text: "Quick Clone"
                                    color: NuTokens.textPrimary
                                    font.pixelSize: NuTokens.fontBody
                                    font.weight: Font.DemiBold
                                }

                                NuSelectableText {
                                    Layout.fillWidth: true
                                    text: "Trusted LAN blockchain clone helper. Technical name: DCOL / Direct Copy Over LAN. Quick Clone copies public chain data only and never copies wallet files, private keys, passphrases, configuration, peers, bans, or RPC cookies."
                                    color: NuTokens.textSecondary
                                    font.pixelSize: NuTokens.fontSmall
                                    wrapMode: Text.WordWrap
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: NuTokens.spaceMd

                                    NuCheckBox {
                                        text: "Allow Quick Clone from LAN nodes"
                                        checked: NuService.lanQuickCloneEnabled
                                        helpText: "Advanced. Use only with Defcoin Core Nu nodes on your LAN. Normal validation-based sync remains available; DCOL snapshot replacement is gated by manifests and hash checks before any public chain folders are swapped."
                                        onToggled: NuService.lanQuickCloneEnabled = checked
                                    }

                                    NuCheckBox {
                                        text: "Provide Quick Clones to LAN nodes"
                                        checked: NuService.lanQuickCloneProvideEnabled
                                        helpText: "Allows this wallet to answer trusted-LAN Quick Clone block requests using public blockchain data only. Wallet files, private keys, passphrases, settings, peers, bans, and RPC cookies are never sent."
                                        onToggled: NuService.lanQuickCloneProvideEnabled = checked
                                    }

                                    NuCheckBox {
                                        text: "Automatically validate blocks after Quick Clone"
                                        checked: NuService.quickCloneAutoValidateAfter
                                        helpText: "Runs Core's online verifychain path after a Quick Clone when available. This can slow the wallet while it runs, but it gives a post-copy integrity check without copying any wallet data."
                                        onToggled: NuService.quickCloneAutoValidateAfter = checked
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: NuTokens.spaceSm

                                    NuActionButton {
                                        text: "Sync using Quick Clone now"
                                        Layout.preferredWidth: 230
                                        primary: true
                                        helpText: "Open the trusted-LAN Quick Clone warning and arm discovery only after confirmation. Use this only when you trust the LAN source node."
                                        onClicked: quickCloneStartDialog.open()
                                    }

                                    NuActionButton {
                                        text: "Validate existing blockchain"
                                        Layout.preferredWidth: 230
                                        enabled: !NuService.quickCloneValidationRunning
                                        helpText: "Run Core's verifychain RPC over the existing public blockchain data. This does not reindex and does not touch wallet files."
                                        onClicked: NuService.validateExistingBlockchain()
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                NuSelectableText {
                                    Layout.fillWidth: true
                                    text: NuService.lanQuickCloneStatus + "\n" + NuService.quickCloneValidationStatus
                                    color: NuTokens.textSecondary
                                    font.pixelSize: NuTokens.fontSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
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

                    NuCheckBox {
                        text: "Show startup status indicator"
                        checked: NuService.showStartupSplashStatusIndicator
                        helpText: "Off by default. When enabled, the startup splash shows a small top-center phase and timer line while Nu loads. Startup progress is still written to the launch log when this is off."
                        onToggled: NuService.showStartupSplashStatusIndicator = checked
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

    NuDialog {
        id: quickCloneStartDialog
        title: "Use Quick Clone"
        dialogWidth: 760
        acceptText: "Start Quick Clone"
        cancelText: "Keep normal sync"
        beforeAccept: function() {
            NuService.syncUsingQuickCloneNow()
            return true
        }

        TextEdit {
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(1, quickCloneStartDialog.availableWidth)
            width: Math.max(1, quickCloneStartDialog.availableWidth)
            Layout.preferredHeight: Math.min(Math.max(contentHeight + NuTokens.spaceSm, 250), Math.max(260, root.height - 260))
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            color: NuTokens.textPrimary
            selectedTextColor: NuTokens.textInverse
            selectionColor: NuTokens.lineStrong
            font.pixelSize: NuTokens.fontBody
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            textFormat: TextEdit.PlainText
            text: "Quick Clone is for Defcoin Core Nu nodes you own and trust on the same LAN.\n\n"
                + "It is designed to copy public blockchain data faster by trusting another local node's already-validated blockchain. It never copies wallet files, private keys, passphrases, configuration, peers, bans, address books, or RPC cookies.\n\n"
                + "A partial clone is not usable chain state. Nu must finish the staged copy, verify the source manifest and streaming checksums, briefly stop the receiver backend for the final folder swap, then restart and confirm the expected best block hash.\n\n"
                + "Normal validated sync remains the safest default. Use Quick Clone only when you control the sending node and understand that validation is being deferred unless you run Validate existing blockchain afterward."
        }
    }
}
