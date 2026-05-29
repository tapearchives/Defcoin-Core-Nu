import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Theme"

MenuItem {
    id: control
    property var shortcut: ""
    readonly property bool darkNativeMenu: Qt.platform.os === "osx"
    implicitWidth: Math.max(label.implicitWidth + 96, 430)
    implicitHeight: Math.max(label.implicitHeight + 14, 34)

    contentItem: Text {
        id: label
        text: control.text
        color: !control.enabled ? (control.darkNativeMenu ? "#9a9a9a" : NuTokens.textSecondary)
                                : (control.highlighted ? NuTokens.textInverse
                                                       : (control.darkNativeMenu ? NuTokens.textInverse : NuTokens.textPrimary))
        opacity: control.enabled ? 1.0 : 0.88
        font.family: NuTokens.bodyFont
        font.pixelSize: NuTokens.fontBody
        elide: Text.ElideNone
        verticalAlignment: Text.AlignVCenter
        leftPadding: 10
        rightPadding: 10
        width: Math.max(1, control.width - 24)
    }

    background: Rectangle {
        color: control.highlighted && control.enabled
               ? (control.darkNativeMenu ? "#3a3a3c" : NuTokens.lineStrong)
               : (control.darkNativeMenu ? "#1c1c1e" : NuTokens.panelBase)
    }

    Shortcut {
        sequences: control.shortcut === "" ? [] : [control.shortcut]
        enabled: control.enabled && control.visible && control.shortcut !== ""
        onActivated: control.triggered()
    }
}
