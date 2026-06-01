pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../Theme"
import "../Views"

Item {
    id: root

    property string currentRoute: "forensics"
    property int nodeInitialTab: 0
    property int peerInitialView: 0
    property bool forensicsLoaded: true
    property bool explorerLoaded: false

    signal aboutRequested

    onCurrentRouteChanged: {
        if (currentRoute === "explorer" || currentRoute === "indexing")
            explorerLoaded = true
        else
            forensicsLoaded = true
    }

    function routeIndex(route) {
        switch (route) {
        case "explorer":
        case "indexing":
            return 1
        default: return 0
        }
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
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.routeIndex(root.currentRoute)

                    Loader {
                        active: root.forensicsLoaded
                        asynchronous: true
                        sourceComponent: ForensicsView {}
                    }

                    Loader {
                        active: root.explorerLoaded
                        asynchronous: true
                        sourceComponent: ExplorerView {
                            active: root.currentRoute === "explorer" || root.currentRoute === "indexing"
                            preferredTab: root.currentRoute === "indexing" ? 1 : 0
                        }
                    }
                }
            }
        }
    }
}
