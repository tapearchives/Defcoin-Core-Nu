pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Views"

Item {
    id: root

    property string currentRoute: "explorer"
    property int nodeInitialTab: 0
    property int peerInitialView: 0
    property bool forensicsLoaded: false
    property bool explorerLoaded: true
    property string explorerSearchText: ""
    property int explorerSearchNonce: 0
    property string explorerResultTitle: ""
    property string explorerResultHtml: ""
    property int explorerResultNonce: 0

    signal aboutRequested

    onCurrentRouteChanged: {
        if (currentRoute === "explorer" || currentRoute === "holders" || currentRoute === "movements" || currentRoute === "indexing")
            explorerLoaded = true
        else
            forensicsLoaded = true
    }

    function routeIndex(route) {
        switch (route) {
        case "explorer":
        case "holders":
        case "movements":
        case "indexing":
            return 1
        default: return 0
        }
    }

    function explorerRouteActive() {
        return root.currentRoute === "explorer"
               || root.currentRoute === "holders"
               || root.currentRoute === "movements"
               || root.currentRoute === "indexing"
    }

    function forensicsPreferredTab(route) {
        if (route === "witness") return 1
        if (route === "contacts") return 2
        return 0
    }

    function forensicsSectionTitle(route) {
        if (route === "witness") return "Witness Repair"
        if (route === "contacts") return "Contacts"
        return "Message Scan"
    }

    function forensicsSectionDetail(route) {
        if (route === "witness")
            return "Inspect and repair missing witness data in imported block files."
        if (route === "contacts")
            return "Build local address clusters from wallet labels, contacts, pools, projects, and investigation notes."
        return "Scan accepted Defcoin blocks for unusual OP_RETURN text, burned outputs, and message patterns."
    }

    function explorerPreferredTab(route) {
        if (route === "holders") return 1
        if (route === "movements") return 2
        if (route === "indexing") return 3
        return 0
    }

    function explorerSectionTitle(route) {
        if (route === "holders") return "Holder Atlas"
        if (route === "movements") return "Movement Map"
        if (route === "indexing") return "Index Engines"
        return "Explorer Search"
    }

    function explorerSectionDetail(route) {
        if (route === "holders")
            return "Largest holders, supply bands, concentration, and holder timeline checkpoints."
        if (route === "movements")
            return "Large transfer tables and address-to-address flow graphs backed by the local explorer index."
        if (route === "indexing")
            return "Monitor and tune the Explorer, Holder Atlas, movement, and forensics indexing engines."
        return "Local block, transaction, address, Holder Atlas, and movement lookups backed by a SQLite WAL cache."
    }

    function submitExplorerSearch(query) {
        const clean = String(query || "").trim()
        if (clean.length === 0) return
        root.explorerSearchText = clean
        root.explorerSearchNonce += 1
        root.currentRoute = "explorer"
        root.explorerLoaded = true
        NuService.searchExplorer(clean)
    }

    function showExplorerResult(title, html) {
        root.currentRoute = "explorer"
        root.explorerLoaded = true
        root.explorerResultTitle = title
        root.explorerResultHtml = html
        root.explorerResultNonce += 1
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ExpForNavigationRail {
            Layout.preferredWidth: 216
            Layout.fillHeight: true
            currentRoute: root.currentRoute
            onRouteRequested: (route) => root.currentRoute = route
            onAboutRequested: root.aboutRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: NuTokens.backgroundBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceXl
                spacing: NuTokens.spaceLg

                StatusStrip {
                    Layout.fillWidth: true
                    showExplorerIndexTools: true
                    onExplorerSearchRequested: (query) => root.submitExplorerSearch(query)
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.routeIndex(root.currentRoute)

                    Loader {
                        active: root.forensicsLoaded
                        asynchronous: true
                        sourceComponent: ForensicsView {
                            active: !root.explorerRouteActive()
                            preferredTab: root.forensicsPreferredTab(root.currentRoute)
                            sectionTitle: root.forensicsSectionTitle(root.currentRoute)
                            sectionDetail: root.forensicsSectionDetail(root.currentRoute)
                        }
                    }

                    Loader {
                        active: root.explorerLoaded
                        asynchronous: true
                        sourceComponent: ExplorerView {
                            active: root.explorerRouteActive()
                            preferredTab: root.explorerPreferredTab(root.currentRoute)
                            sectionTitle: root.explorerSectionTitle(root.currentRoute)
                            sectionDetail: root.explorerSectionDetail(root.currentRoute)
                            mastSearchText: root.explorerSearchText
                            mastSearchNonce: root.explorerSearchNonce
                            explorerResultTitle: root.explorerResultTitle
                            explorerResultHtml: root.explorerResultHtml
                            explorerResultNonce: root.explorerResultNonce
                        }
                    }
                }
            }
        }
    }
}
