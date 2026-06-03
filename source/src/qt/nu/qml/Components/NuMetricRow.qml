import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"

RowLayout {
    id: root
    spacing: NuTokens.spaceSm

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

    HoverHandler {
        id: metricHover
    }

    Label {
        text: root.label
        Layout.maximumWidth: root.labelMaximumWidth
        color: NuTokens.textSecondary
        font.pixelSize: NuTokens.fontSmall
        elide: Text.ElideRight
    }

    Label {
        text: root.value
        Layout.maximumWidth: root.valueMaximumWidth
        color: NuTokens.textPrimary
        font.pixelSize: NuTokens.fontBody
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }
}
