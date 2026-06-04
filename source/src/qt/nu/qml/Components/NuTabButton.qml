import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Theme"

TabButton {
    id: root
    implicitHeight: 40
    font.pixelSize: NuTokens.fontTiny
    font.weight: checked ? Font.DemiBold : Font.Normal
    activeFocusOnTab: true
    hoverEnabled: true

    contentItem: Text {
        text: root.text
        color: root.enabled ? NuTokens.textPrimary : NuTokens.textMuted
        font: root.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: NuTokens.radiusSmall
        color: root.checked ? NuTokens.panelBase : (root.hovered ? "#dddddf" : "#d0d0d4")
        border.color: root.activeFocus ? NuTokens.accentSky : (root.checked ? NuTokens.lineSubtle : NuTokens.panelBase)
        border.width: root.activeFocus ? 2 : 1
        Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: NuTokens.lineStrong
            opacity: root.checked ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: NuTokens.motionFast } }
        }
    }
}
