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
    readonly property color hoverBorderColor: Qt.rgba(0.34, 0.12, 0.55, 0.70)

    scale: pressed ? 0.988 : 1.0
    Behavior on scale { NumberAnimation { duration: NuTokens.motionFast; easing.type: Easing.OutCubic } }

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
            Layout.alignment: Qt.AlignVCenter
            source: root.iconSource
            visible: root.iconSource.length > 0
            fillMode: Image.PreserveAspectFit
            opacity: root.enabled ? (root.selected ? 1.0 : 0.88) : 0.42
            Behavior on opacity { NumberAnimation { duration: NuTokens.motionFast } }
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
                      : (root.hovered ? root.hoverBorderColor : (root.selected ? NuTokens.panelBase : Qt.rgba(1, 1, 1, 0.16)))
        border.width: (root.activeFocus || root.hovered) ? 2 : 1
        Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.width { NumberAnimation { duration: NuTokens.motionFast; easing.type: Easing.OutCubic } }

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
