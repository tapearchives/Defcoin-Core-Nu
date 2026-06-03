import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../Theme"

RowLayout {
    id: root
    spacing: NuTokens.spaceLg

    property string title: ""
    property string detail: ""
    readonly property bool compact: width > 0 && width < 900

    ColumnLayout {
        Layout.fillWidth: true
        spacing: NuTokens.spaceXs

        Label {
            Layout.fillWidth: true
            text: root.title
            color: NuTokens.textPrimary
            font.pixelSize: root.compact ? NuTokens.fontBodyLarge : NuTokens.fontTitle
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Label {
            text: root.detail
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            visible: root.detail.length > 0
            wrapMode: Text.WordWrap
            maximumLineCount: root.compact ? 3 : 2
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
