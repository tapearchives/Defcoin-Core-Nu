import QtQuick 2.15

import "../Theme"

Item {
    id: root

    property int coinWidth: 48
    property int coinHeight: 68
    property int gap: NuTokens.spaceMd
    property int wordmarkSize: 24
    property int wordmarkWeight: Font.ExtraBold
    property real wordmarkTracking: 1.0
    property real fcGapAdjust: 1.0
    property bool fitThirdLineToWordmark: true
    property int lineSpacing: -8
    property color textColor: NuTokens.textInverse
    property url coinSource: "../../assets/brand/defcoin-nu-coin-stack-hires.png"
    property string thirdLine: ""
    readonly property string displayFont: Qt.platform.os === "windows" ? "Bahnschrift Condensed" : "Avenir Next Condensed"
    readonly property real wordmarkTargetWidth: Math.max(defcoinLine.implicitWidth, coreText.implicitWidth)
    readonly property real thirdLineTracking: {
        if (!fitThirdLineToWordmark || root.thirdLine.length <= 1)
            return root.wordmarkTracking
        const extra = root.wordmarkTargetWidth - thirdLineMetrics.advanceWidth
        return Math.max(0, extra / (root.thirdLine.length - 1))
    }

    implicitWidth: coin.width + root.gap + Math.max(root.wordmarkTargetWidth, exploreText.visible ? exploreText.width : 0)
    implicitHeight: Math.max(coin.height, wordmark.implicitHeight)

    TextMetrics {
        id: thirdLineMetrics
        font.family: root.displayFont
        font.pixelSize: root.wordmarkSize
        font.weight: root.wordmarkWeight
        font.letterSpacing: 0
        text: root.thirdLine
    }

    Image {
        id: coin
        width: root.coinWidth
        height: root.coinHeight
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        source: root.coinSource
        sourceSize.width: 692
        sourceSize.height: 978
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Column {
        id: wordmark
        anchors.left: coin.right
        anchors.leftMargin: root.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.lineSpacing

        Row {
            id: defcoinLine
            spacing: root.fcGapAdjust

            Text {
                text: "DEF"
                color: root.textColor
                font.family: root.displayFont
                font.pixelSize: root.wordmarkSize
                font.weight: root.wordmarkWeight
                font.letterSpacing: root.wordmarkTracking
            }

            Text {
                text: "COIN"
                color: root.textColor
                font.family: root.displayFont
                font.pixelSize: root.wordmarkSize
                font.weight: root.wordmarkWeight
                font.letterSpacing: root.wordmarkTracking
            }
        }

        Text {
            id: coreText
            text: "CORE NU"
            color: root.textColor
            font.family: root.displayFont
            font.pixelSize: root.wordmarkSize
            font.weight: root.wordmarkWeight
            font.letterSpacing: root.wordmarkTracking
        }

        Text {
            id: exploreText
            visible: root.thirdLine.length > 0
            width: root.fitThirdLineToWordmark ? root.wordmarkTargetWidth : implicitWidth
            text: root.thirdLine
            color: root.textColor
            font.family: root.displayFont
            font.pixelSize: root.wordmarkSize
            font.weight: root.wordmarkWeight
            font.letterSpacing: root.thirdLineTracking
        }
    }
}
