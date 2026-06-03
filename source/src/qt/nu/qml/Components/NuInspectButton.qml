import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic

import "../Theme"

Basic.Button {
    id: root

    implicitWidth: 44
    implicitHeight: 44
    hoverEnabled: true
    activeFocusOnTab: true

    property string helpText: ""
    property bool suppressToolTip: false

    Accessible.role: Accessible.Button
    Accessible.name: "Inspect"
    Accessible.description: helpText

    ToolTip.visible: !suppressToolTip && (hovered || activeFocus) && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    onPressedChanged: if (pressed) suppressToolTip = true
    onClicked: suppressToolTip = true
    onHoveredChanged: if (!hovered) suppressToolTip = false
    onActiveFocusChanged: {
        if (!activeFocus) suppressToolTip = false
        glyph.requestPaint()
    }
    onEnabledChanged: glyph.requestPaint()

    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()

    contentItem: Item {
        implicitWidth: 28
        implicitHeight: 28

        Rectangle {
            anchors.centerIn: parent
            width: 28
            height: 28
            radius: 14
            color: root.activeFocus ? NuTokens.inverseBase : "transparent"
            border.color: root.enabled ? NuTokens.lineStrong : NuTokens.textMuted
            border.width: root.activeFocus ? 2 : 1

            Canvas {
                id: glyph
                anchors.fill: parent
                opacity: root.enabled ? 1.0 : 0.42
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = root.activeFocus ? NuTokens.textInverse : NuTokens.textPrimary
                    ctx.beginPath()
                    ctx.arc(width / 2, height * 0.29, 1.9, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.fillRect(width / 2 - 1.1, height * 0.42, 2.2, height * 0.28)
                    ctx.fillRect(width / 2 - 2.8, height * 0.68, 5.6, 2.1)
                }
            }
        }
    }

    background: Rectangle {
        color: root.hovered && root.enabled ? NuTokens.panelHover : "transparent"
        radius: NuTokens.radiusMedium
    }
}
