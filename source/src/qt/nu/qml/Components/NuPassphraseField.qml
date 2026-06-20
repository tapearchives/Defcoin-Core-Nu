import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Theme"

NuTextField {
    id: root

    property bool passphraseVisible: false
    property bool statusActive: false
    property color statusColor: NuTokens.lineSubtle
    signal visibilityToggled(bool visible)

    echoMode: passphraseVisible ? TextInput.Normal : TextInput.Password
    rightPadding: NuTokens.spaceMd + 38
    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData

    background: Rectangle {
        color: root.enabled ? NuTokens.panelBase : NuTokens.backgroundBase
        border.color: root.statusActive ? root.statusColor : (root.activeFocus ? NuTokens.accentSky : (root.hovered ? NuTokens.lineStrong : NuTokens.lineSubtle))
        border.width: (root.statusActive || root.activeFocus) ? 2 : 1
        radius: NuTokens.radiusSmall
        Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }
    }

    Image {
        anchors.right: parent.right
        anchors.rightMargin: NuTokens.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        source: root.passphraseVisible ? "../../assets/icons/eye.svg" : "../../assets/icons/eye-off.svg"
        fillMode: Image.PreserveAspectFit
        opacity: root.enabled ? 0.9 : 0.45
    }

    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 38
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.passphraseVisible = !root.passphraseVisible
            root.visibilityToggled(root.passphraseVisible)
            root.forceActiveFocus()
        }
        ToolTip.visible: hovered
        ToolTip.text: root.passphraseVisible ? qsTr("Hide passphrase") : qsTr("Show passphrase")
        ToolTip.delay: NuTokens.tooltipDelay
        ToolTip.timeout: NuTokens.tooltipTimeout
    }
}
