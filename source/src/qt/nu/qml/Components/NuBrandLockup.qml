import QtQuick 2.15

import "../Theme"

Item {
    id: root

    property int coinWidth: Math.round(root.wordmarkSize * 2.12)
    property int coinHeight: root.coinWidth
    property int gap: Math.max(NuTokens.spaceSm, Math.round(root.wordmarkSize * 0.32))
    property int wordmarkSize: 24
    property int wordmarkWeight: Font.ExtraBold
    property real wordmarkTracking: Math.max(1.0, root.wordmarkSize * 0.04)
    property real coreNuTracking: Math.max(1.0, root.wordmarkSize * 0.042)
    property real fcGapAdjust: root.wordmarkSize * 0.0345
    property bool fitThirdLineToWordmark: true
    property int lineSpacing: Math.max(0, Math.round(root.wordmarkSize * 0.025))
    property color textColor: NuTokens.textInverse
    property url coinSource: "../../assets/brand/defcoin-v26-coin.png"
    property string thirdLine: ""
    readonly property string displayFont: Qt.platform.os === "windows" ? "Bahnschrift Condensed" : "Avenir Next Condensed"
    readonly property real wordmarkTargetWidth: defcoinLine.implicitWidth
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
        sourceSize.width: 1254
        sourceSize.height: 1254
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
            spacing: root.wordmarkTracking

            Repeater {
                model: ["D", "E", "F", "C", "O", "I", "N"]

                Row {
                    spacing: 0

                    Item {
                        width: index === 3 ? root.fcGapAdjust : 0
                        height: 1
                    }

                    Text {
                        text: modelData
                        color: root.textColor
                        font.family: root.displayFont
                        font.pixelSize: root.wordmarkSize
                        font.weight: root.wordmarkWeight
                        font.letterSpacing: 0
                    }
                }
            }
        }

        Row {
            id: coreLine
            width: root.wordmarkTargetWidth

            Text {
                id: coreRun
                text: "CORE"
                color: root.textColor
                font.family: root.displayFont
                font.pixelSize: root.wordmarkSize
                font.weight: root.wordmarkWeight
                font.letterSpacing: root.coreNuTracking
            }

            Item {
                width: Math.max(0, coreLine.width - coreRun.implicitWidth - nuRun.implicitWidth)
                height: 1
            }

            Text {
                id: nuRun
                text: "NU"
                color: root.textColor
                font.family: root.displayFont
                font.pixelSize: root.wordmarkSize
                font.weight: root.wordmarkWeight
                font.letterSpacing: root.coreNuTracking
            }
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
