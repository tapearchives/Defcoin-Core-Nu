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
        implicitWidth: 10
        implicitHeight: 10
        radius: 5
        color: root.stateColor
        Layout.alignment: Qt.AlignVCenter
    }

    Label {
        Layout.maximumWidth: root.labelMaximumWidth
        text: root.label
        color: NuTokens.textPrimary
        font.pixelSize: NuTokens.fontBody
        elide: Text.ElideRight
    }
}
