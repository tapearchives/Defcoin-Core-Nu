import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"

Rectangle {
    id: root
    implicitWidth: metricLayout.implicitWidth + NuTokens.spaceSm * 2
    implicitHeight: Math.max(26, metricLayout.implicitHeight + NuTokens.spaceXs * 2)
    radius: NuTokens.radiusSmall
    color: metricHover.hovered ? Qt.rgba(0, 0, 0, 0.035) : "transparent"

    property string label: ""
    property string value: ""
    property string helpText: ""
    property int labelMaximumWidth: 150
    property int valueMaximumWidth: 180
    readonly property string displayHelpText: helpText.length > 0 ? helpText : (label + ": " + value)

    ToolTip.visible: metricHover.hovered && root.displayHelpText.length > 1
    ToolTip.text: root.displayHelpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }

    HoverHandler {
        id: metricHover
    }

    RowLayout {
        id: metricLayout
        anchors.fill: parent
        anchors.leftMargin: NuTokens.spaceSm
        anchors.rightMargin: NuTokens.spaceSm
        spacing: NuTokens.spaceXs

        Label {
            text: root.label
            Layout.maximumWidth: root.labelMaximumWidth
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Label {
            text: root.value
            Layout.maximumWidth: root.valueMaximumWidth
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
