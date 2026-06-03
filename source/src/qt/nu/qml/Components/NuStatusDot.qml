import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"

RowLayout {
    id: root
    spacing: NuTokens.spaceSm

    property string label: ""
    property color stateColor: NuTokens.stateInactive
    property string helpText: ""
    property int labelMaximumWidth: 220

    ToolTip.visible: dotHover.hovered && root.helpText.length > 0
    ToolTip.text: root.helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    HoverHandler {
        id: dotHover
    }

    Rectangle {
        implicitWidth: 14
        implicitHeight: 14
        radius: 7
        color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.16)
        border.color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.38)
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            width: 8
            height: 8
            radius: 4
            anchors.centerIn: parent
            color: root.stateColor
        }
    }

    Label {
        Layout.maximumWidth: root.labelMaximumWidth
        text: root.label
        color: NuTokens.textPrimary
        font.pixelSize: NuTokens.fontBody
        elide: Text.ElideRight
    }
}
