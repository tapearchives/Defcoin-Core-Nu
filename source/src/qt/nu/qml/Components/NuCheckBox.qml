import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic

import "../Theme"

Basic.CheckBox {
    id: root
    spacing: NuTokens.spaceSm
    font.pixelSize: NuTokens.fontBody
    hoverEnabled: true
    activeFocusOnTab: true

    property string helpText: ""
    property bool suppressToolTip: false
    property bool inverse: false

    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.description: helpText

    ToolTip.visible: !suppressToolTip && (hovered || activeFocus) && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    onPressedChanged: if (pressed) suppressToolTip = true
    onHoveredChanged: if (!hovered) suppressToolTip = false
    onActiveFocusChanged: if (!activeFocus) suppressToolTip = false

    Keys.onSpacePressed: toggle()

    indicator: Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        radius: NuTokens.radiusSmall
        color: root.checked ? NuTokens.accentSky : "transparent"
        border.color: root.checked ? NuTokens.accentSky : (root.inverse ? Qt.rgba(255, 255, 255, 0.72) : NuTokens.lineStrong)
        border.width: root.activeFocus ? 2 : 1

        Canvas {
            anchors.centerIn: parent
            width: 14
            height: 12
            visible: root.checked
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = root.inverse ? NuTokens.inverseBase : NuTokens.checkMarkGreen
                ctx.lineWidth = 2.2
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(1.5, 6.5)
                ctx.lineTo(5.2, 10.0)
                ctx.lineTo(12.5, 2.0)
                ctx.stroke()
            }
        }
    }

    contentItem: Text {
        text: root.text
        color: root.enabled ? (root.inverse ? NuTokens.textInverse : NuTokens.textPrimary)
                            : (root.inverse ? Qt.rgba(246, 246, 242, 0.48) : NuTokens.textMuted)
        font: root.font
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
        wrapMode: Text.WordWrap
    }
}
