import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic

import "../Theme"

Basic.TextField {
    id: root
    property string helpText: ""
    color: NuTokens.textPrimary
    placeholderTextColor: NuTokens.textMuted
    selectedTextColor: NuTokens.textInverse
    selectionColor: NuTokens.lineStrong
    font.family: NuTokens.bodyFont
    font.pixelSize: NuTokens.fontBody
    leftPadding: NuTokens.spaceMd
    rightPadding: NuTokens.spaceMd
    topPadding: NuTokens.spaceSm
    bottomPadding: NuTokens.spaceSm
    hoverEnabled: true
    activeFocusOnTab: true
    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.EditableText
    Accessible.name: placeholderText
    Accessible.description: helpText

    ToolTip.visible: (hovered || activeFocus) && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    background: Rectangle {
        color: root.enabled ? NuTokens.panelBase : NuTokens.backgroundBase
        border.color: root.activeFocus ? NuTokens.accentSky : (root.hovered ? NuTokens.lineStrong : NuTokens.lineSubtle)
        border.width: root.activeFocus ? 2 : 1
        radius: NuTokens.radiusSmall
        Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }
    }
}
