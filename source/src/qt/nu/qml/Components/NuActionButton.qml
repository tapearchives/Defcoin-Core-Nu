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
        color: root.danger ? NuTokens.stateError : (root.primary ? NuTokens.inverseBase : NuTokens.panelBase)
        border.color: root.danger ? NuTokens.stateError : NuTokens.lineStrong
        border.width: root.activeFocus ? 2 : 1
    }
}
