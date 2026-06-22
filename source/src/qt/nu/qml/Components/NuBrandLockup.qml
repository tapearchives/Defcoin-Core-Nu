import QtQuick 2.15

import "../Theme"

Item {
    id: root

    property int wordmarkSize: 24
    readonly property int baseWordmarkSize: 256
    readonly property int baseImageWidth: 1652
    readonly property int baseImageHeight: 567
    readonly property real lockupScale: root.wordmarkSize / root.baseWordmarkSize

    implicitWidth: Math.round(root.baseImageWidth * root.lockupScale)
    implicitHeight: Math.round(root.baseImageHeight * root.lockupScale)

    Image {
        anchors.fill: parent
        source: "../../assets/brand/defcoin-core-nu-lockup.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
