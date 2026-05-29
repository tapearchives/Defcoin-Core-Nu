import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15

import "../Theme"

Basic.Button {
    id: root
    implicitHeight: 56
    font.pixelSize: NuTokens.fontBody
    font.weight: selected ? Font.DemiBold : Font.Normal
    hoverEnabled: true
    activeFocusOnTab: true
    focusPolicy: Qt.StrongFocus

    property string iconSource: ""
    property bool selected: false
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

    contentItem: RowLayout {
        spacing: NuTokens.spaceMd

        Image {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            source: root.iconSource
            visible: root.iconSource.length > 0
            fillMode: Image.PreserveAspectFit
        }

        Text {
            Layout.fillWidth: true
            text: root.text
            color: root.selected ? NuTokens.inverseBase : NuTokens.textInverse
            font: root.font
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        radius: NuTokens.radiusMedium
        color: root.selected ? NuTokens.panelBase : "transparent"
        border.color: root.selected ? NuTokens.panelBase : NuTokens.lineStrong
        border.width: root.activeFocus ? 2 : 1
    }
}
