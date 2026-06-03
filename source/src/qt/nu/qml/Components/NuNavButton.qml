import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15

import "../Theme"

Basic.Button {
    id: root
    implicitHeight: 52
    leftPadding: NuTokens.spaceMd
    rightPadding: NuTokens.spaceMd
    topPadding: NuTokens.spaceSm
    bottomPadding: NuTokens.spaceSm
    font.pixelSize: NuTokens.fontBody
    font.weight: selected ? Font.DemiBold : Font.Normal
    hoverEnabled: true
    activeFocusOnTab: true

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
        spacing: NuTokens.spaceSm
        clip: true

        Image {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            source: root.iconSource
            visible: root.iconSource.length > 0
            fillMode: Image.PreserveAspectFit
            opacity: root.enabled ? (root.selected ? 1.0 : 0.88) : 0.42
        }

        Text {
            Layout.fillWidth: true
            text: root.text
            color: root.selected ? NuTokens.inverseBase : NuTokens.textInverse
            font: root.font
            minimumPixelSize: NuTokens.fontTiny
            fontSizeMode: Text.HorizontalFit
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1
            elide: Text.ElideRight
            clip: true
        }
    }

    background: Rectangle {
        radius: NuTokens.radiusMedium
        color: root.selected
               ? NuTokens.panelBase
               : (root.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.color: root.activeFocus
                      ? NuTokens.accentSky
                      : (root.selected ? NuTokens.panelBase : Qt.rgba(1, 1, 1, 0.16))
        border.width: root.activeFocus ? 2 : 1

        Rectangle {
            width: 3
            height: Math.max(18, parent.height - NuTokens.spaceLg)
            radius: 2
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            visible: root.selected
            color: NuTokens.lineStrong
        }
    }
}
