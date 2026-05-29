import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15

import "../Theme"

Rectangle {
    id: root
    radius: NuTokens.radiusMedium
    color: NuTokens.panelBase
    border.color: NuTokens.lineSubtle
    implicitHeight: 50

    property string value: ""
    property bool copyEnabled: value.length > 0
    signal copyRequested(string value)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: NuTokens.spaceMd
        spacing: NuTokens.spaceSm

        Label {
            Layout.fillWidth: true
            text: root.value
            elide: Text.ElideMiddle
            color: NuTokens.textPrimary
            font.family: "Menlo"
            font.pixelSize: NuTokens.fontBody
        }

        Basic.Button {
            text: "Copy"
            enabled: root.copyEnabled
            activeFocusOnTab: true
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.description: root.copyEnabled ? "Copy this value." : "No value is available to copy."
            onClicked: root.copyRequested(root.value)
            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
            Keys.onSpacePressed: clicked()
        }
    }
}
