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
    property int valueMaximumWidth: 180

    ToolTip.visible: metricHover.hovered && root.helpText.length > 0
    ToolTip.text: root.helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    HoverHandler {
        id: metricHover
    }

    Label {
        text: root.label
        color: NuTokens.textSecondary
        font.pixelSize: NuTokens.fontSmall
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
