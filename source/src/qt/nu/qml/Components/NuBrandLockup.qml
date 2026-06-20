import QtQuick 2.15

import "../Theme"

Item {
    id: root

    property int wordmarkSize: 24
    property string thirdLine: ""
    readonly property bool exploreVariant: root.thirdLine.length > 0
    readonly property int baseWordmarkSize: 256
    readonly property int baseImageWidth: root.exploreVariant ? 1652 : 1652
    readonly property int baseImageHeight: root.exploreVariant ? 1225 : 567
    readonly property real lockupScale: root.wordmarkSize / root.baseWordmarkSize

    implicitWidth: Math.round(root.baseImageWidth * root.lockupScale)
    implicitHeight: Math.round(root.baseImageHeight * root.lockupScale)

    Image {
        anchors.fill: parent
        source: root.exploreVariant
                ? "../../assets/brand/defcoin-core-nu-explore-lockup.png"
                : "../../assets/brand/defcoin-core-nu-lockup.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
