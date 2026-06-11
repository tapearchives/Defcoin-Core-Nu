import QtQuick 2.15

import "../Theme"

Rectangle {
    id: root
    radius: NuTokens.radiusLarge
    color: NuTokens.panelBase
    border.color: panelHover.hovered ? Qt.rgba(0.26, 0.10, 0.42, 0.55) : NuTokens.lineSubtle
    border.width: 1

    default property alias content: body.data
    property int padding: NuTokens.spaceLg
    property bool hoverOutlineEnabled: true

    Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }

    HoverHandler {
        id: panelHover
        enabled: root.hoverOutlineEnabled
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
