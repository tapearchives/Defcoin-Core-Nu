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

    signal aboutRequested

    function routeIndex(route) {
        switch (route) {
        case "explorer": return 1
        case "indexing": return 2
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

                    ForensicsView {}

                    ExplorerView {
                        active: root.currentRoute === "explorer"
                        preferredTab: 0
                    }

                    ExplorerView {
                        active: root.currentRoute === "indexing"
                        preferredTab: 1
                    }
                }
            }
        }
    }
}
