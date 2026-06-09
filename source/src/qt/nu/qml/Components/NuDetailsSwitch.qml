import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15

import "../Theme"

Basic.Switch {
    id: root
    text: "Details"
    implicitWidth: 118
    implicitHeight: 30
    hoverEnabled: true
    activeFocusOnTab: true

    property string helpText: "Show the full detailed view."

    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.description: helpText

    ToolTip.visible: (hovered || activeFocus) && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    indicator: Rectangle {
        implicitWidth: 38
        implicitHeight: 20
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        radius: height / 2
        color: root.checked ? NuTokens.accentSky : NuTokens.panelBase
        border.color: root.checked ? NuTokens.accentSky : NuTokens.lineStrong
        border.width: root.activeFocus ? 2 : 1

        Rectangle {
            width: 16
            height: 16
            radius: 8
            y: 2
            x: root.checked ? parent.width - width - 2 : 2
            color: root.checked ? NuTokens.panelBase : NuTokens.textSecondary
            Behavior on x { NumberAnimation { duration: NuTokens.motionFast } }
            Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        }
    }

    contentItem: Text {
        text: root.text
        color: root.enabled ? NuTokens.textPrimary : NuTokens.textMuted
        font.pixelSize: NuTokens.fontSmall
        font.weight: Font.DemiBold
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + NuTokens.spaceSm
        elide: Text.ElideRight
    }
}
