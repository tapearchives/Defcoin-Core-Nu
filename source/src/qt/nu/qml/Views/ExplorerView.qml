import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg
    readonly property real indexProgress: NuService.explorerIndexTip > 0
                                          ? Math.max(0, Math.min(1, NuService.explorerIndexHeight / NuService.explorerIndexTip))
                                          : 0

    function indexPercentText() {
        if (NuService.explorerIndexTip <= 0) return "0.00%"
        return (root.indexProgress * 100).toFixed(2) + "%"
    }

    function openRow(row) {
        const meta = row && row.meta ? row.meta : {}
        const type = String(meta.type || "")
        const id = String(meta.id || "")
        if (type === "transaction") NuService.openTransactionInExplorer(id)
        else if (type === "address") NuService.openAddressInExplorer(id)
        else if (type === "block") NuService.openBlockInExplorer(id)
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Explorer"
        detail: "Local block, transaction, and address lookups backed by a SQLite WAL cache."
    }

    NuPanel {
        Layout.fillWidth: true
        ColumnLayout {
            anchors.fill: parent
            spacing: NuTokens.spaceMd

            Label {
                Layout.fillWidth: true
                text: "Search blockchain"
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBodyLarge
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: "Open anything the Defcoin explorer can identify: block height, block hash, transaction ID, or wallet address. Nu checks the local SQLite explorer cache first, then asks the connected backend when needed."
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontBody
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                NuTextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    font.pixelSize: NuTokens.fontBodyLarge
                    topPadding: NuTokens.spaceMd
                    bottomPadding: NuTokens.spaceMd
                    placeholderText: "Block height, block hash, transaction ID, or address"
                    helpText: "Search block heights, 64-character block or transaction hashes, and supported Defcoin Base58 address forms."
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            NuService.searchExplorer(searchField.text)
                            event.accepted = true
                        }
                    }
                }

                NuActionButton {
                    text: "Search"
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 56
                    primary: true
                    helpText: "Open the matching item in an independent internal explorer window."
                    onClicked: NuService.searchExplorer(searchField.text)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: "Index database: " + NuService.explorerDatabasePath
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    elide: Text.ElideMiddle
                }

                NuActionButton {
                    text: "Reload recent"
                    Layout.preferredWidth: 150
                    helpText: "Refresh the list of recent explorer lookups cached in SQLite."
                    onClicked: NuService.refreshExplorerRecentLookups()
                }
            }
        }
    }

    NuPanel {
        Layout.fillWidth: true
        ColumnLayout {
            anchors.fill: parent
            spacing: NuTokens.spaceMd

            ColumnLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceSm

                Label {
                    text: "Background index"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: NuService.explorerIndexStatus
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                NuActionButton {
                    text: NuService.explorerIndexing ? "Indexing" : "Start / Resume"
                    width: 150
                    enabled: !NuService.explorerIndexing
                    primary: !NuService.explorerIndexing
                    helpText: "Build or resume the local block, transaction-ID, and standard address-output index from the connected backend."
                    onClicked: NuService.startExplorerIndexing()
                }

                NuActionButton {
                    text: "Pause"
                    width: 110
                    enabled: NuService.explorerIndexing
                    helpText: "Pause indexing after the current RPC request completes. Progress is kept in SQLite."
                    onClicked: NuService.stopExplorerIndexing()
                }

                NuActionButton {
                    text: "Reset index"
                    width: 130
                    enabled: !NuService.explorerIndexing
                    danger: true
                    helpText: "Clear only the block and transaction-ID index. Recent manual lookups are kept."
                    onClicked: NuService.resetExplorerIndex()
                }
            }

            Basic.ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 12
                from: 0
                to: 1
                value: root.indexProgress
                indeterminate: NuService.explorerIndexing && NuService.explorerIndexTip <= 0
            }

            Flow {
                Layout.fillWidth: true
                spacing: NuTokens.spaceLg

                Label {
                    text: "Progress: " + root.indexPercentText()
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }

                Label {
                    text: "Next block: " + NuService.explorerIndexHeight
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }

                Label {
                    text: "Tip: " + NuService.explorerIndexTip
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }

                Label {
                    text: "Cached blocks: " + NuService.explorerIndexedBlockCount
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }

                Label {
                    text: "Outputs: " + NuService.explorerIndexedOutputCount
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                }
            }

            Label {
                Layout.fillWidth: true
                text: "The indexer is throttled and resumable. It stores public block summaries, transaction IDs, and standard address outputs in the local SQLite WAL explorer cache so internal lookups can work without exposing wallet-private data."
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }

    NuPanel {
        Layout.fillWidth: true
        Layout.fillHeight: true
        ColumnLayout {
            anchors.fill: parent
            spacing: NuTokens.spaceMd

            Label {
                text: "Recent local explorer lookups"
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBody
                font.weight: Font.DemiBold
            }

            NuDataTable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                tableId: "internalExplorerRecent"
                columns: ["Type", "Identifier", "Title", "Cached"]
                columnTypes: ["text", "hash", "text", "date"]
                columnWeights: [0.7, 2.7, 1.1, 1.2]
                rows: NuService.explorerRecentLookups
                emptyText: "No internal explorer lookups cached yet. Search above or open an explorer link from Wallet, Transactions, or Addresses."
                defaultSortColumn: 3
                defaultSortAscending: false
                onRowActivated: (row) => root.openRow(row)
            }
        }
    }
}
