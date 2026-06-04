import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic

import "../Theme"

Basic.Button {
    id: root
    implicitHeight: 48
    leftPadding: NuTokens.spaceMd
    rightPadding: NuTokens.spaceMd
    topPadding: NuTokens.spaceXs
    bottomPadding: NuTokens.spaceXs
    font.pixelSize: NuTokens.fontBody
    font.weight: Font.DemiBold
    hoverEnabled: true
    activeFocusOnTab: true
    focusPolicy: Qt.StrongFocus

    property bool primary: false
    property bool danger: false
    property string helpText: ""
    property bool suppressToolTip: false
    readonly property bool hasInteractiveHighlight: hovered || activeFocus || pressed

    scale: pressed ? 0.985 : 1.0
    opacity: enabled ? 1.0 : 0.62
    Behavior on scale { NumberAnimation { duration: NuTokens.motionFast; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: NuTokens.motionFast; easing.type: Easing.OutCubic } }

    function surfaceColor() {
        if (!root.enabled) return NuTokens.backgroundBase
        if (root.danger) {
            if (root.pressed) return "#a32018"
            return root.hovered ? "#c52920" : NuTokens.stateError
        }
        if (root.primary) {
            if (root.pressed) return "#050607"
            return root.hovered ? "#1b2025" : NuTokens.inverseBase
        }
        if (root.pressed) return "#dde2dc"
        return root.hovered ? NuTokens.panelHover : NuTokens.panelBase
    }

    function outlineColor() {
        if (root.activeFocus) return NuTokens.accentSky
        if (root.danger) return root.hovered ? "#a32018" : NuTokens.stateError
        return root.hovered ? NuTokens.lineStrong : NuTokens.lineStrong
    }

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.description: helpText

    ToolTip.visible: !suppressToolTip && (hovered || activeFocus) && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    onPressedChanged: if (pressed) suppressToolTip = true
    onClicked: suppressToolTip = true
    onHoveredChanged: if (!hovered) suppressToolTip = false
    onActiveFocusChanged: if (!activeFocus) suppressToolTip = false

    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()
    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onRightPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()
    Keys.onLeftPressed: nextItemInFocusChain(false).forceActiveFocus()

    contentItem: Text {
        text: root.text
        color: root.enabled ? (root.primary || root.danger ? NuTokens.textInverse : NuTokens.textPrimary) : NuTokens.textMuted
        font: root.font
        minimumPixelSize: NuTokens.fontTiny
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        clip: true
    }

    background: Rectangle {
        radius: NuTokens.radiusMedium
        color: root.surfaceColor()
        border.color: root.outlineColor()
        border.width: root.activeFocus ? 2 : 1

        Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            radius: 1
            opacity: root.hasInteractiveHighlight && root.enabled ? 1.0 : 0.0
            color: root.primary || root.danger ? NuTokens.accentSky : NuTokens.lineStrong
            Behavior on opacity { NumberAnimation { duration: NuTokens.motionFast; easing.type: Easing.OutCubic } }
        }
    }
}
