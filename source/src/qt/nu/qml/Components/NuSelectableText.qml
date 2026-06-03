import QtQuick 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15

import Defcoin.Nu 1.0
import "../Theme"

Basic.TextArea {
    id: root

    property color textColor: NuTokens.textSecondary
    property int textPixelSize: NuTokens.fontSmall
    property int textWeight: Font.Normal
    property real minimumTextHeight: 0
    property real maximumTextHeight: 10000

    implicitHeight: Math.max(minimumTextHeight, Math.min(maximumTextHeight, contentHeight + topPadding + bottomPadding + 2))
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight
    textFormat: TextEdit.PlainText
    color: textColor
    selectedTextColor: NuTokens.textInverse
    selectionColor: NuTokens.lineStrong
    font.pixelSize: textPixelSize
    font.weight: textWeight
    wrapMode: TextEdit.WordWrap
    readOnly: true
    selectByMouse: true
    persistentSelection: true
    activeFocusOnTab: true
    background: Item {}
    padding: 0

    Shortcut {
        sequences: [StandardKey.Copy]
        enabled: root.activeFocus && root.selectedText.length > 0
        onActivated: NuService.copyText(root.selectedText)
    }
}
