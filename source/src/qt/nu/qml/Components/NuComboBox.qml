pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic

import "../Theme"

Basic.ComboBox {
    id: root
    property string helpText: ""
    property bool suppressToolTip: false
    property var textFormatter: null

    function formattedText(value) {
        var raw = value === undefined || value === null ? "" : String(value)
        return root.textFormatter ? root.textFormatter(raw) : raw
    }

    font.family: NuTokens.bodyFont
    font.pixelSize: NuTokens.fontBody
    leftPadding: NuTokens.spaceMd
    rightPadding: 36
    topPadding: NuTokens.spaceSm
    bottomPadding: NuTokens.spaceSm
    hoverEnabled: true
    activeFocusOnTab: true
    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.ComboBox
    Accessible.name: displayText
    Accessible.description: helpText

    ToolTip.visible: !suppressToolTip && (hovered || activeFocus) && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: NuTokens.tooltipDelay
    ToolTip.timeout: NuTokens.tooltipTimeout

    onPressedChanged: if (pressed) suppressToolTip = true
    onHoveredChanged: if (!hovered) suppressToolTip = false
    onActiveFocusChanged: if (!activeFocus) suppressToolTip = false

    Keys.onReturnPressed: popup.visible ? popup.close() : popup.open()
    Keys.onEnterPressed: popup.visible ? popup.close() : popup.open()
    Keys.onSpacePressed: popup.visible ? popup.close() : popup.open()

    contentItem: TextInput {
        text: root.editable ? root.editText : root.formattedText(root.currentText)
        color: NuTokens.textPrimary
        font: root.font
        verticalAlignment: Text.AlignVCenter
        readOnly: !root.editable
        selectByMouse: root.editable
        selectedTextColor: NuTokens.textInverse
        selectionColor: NuTokens.lineStrong
        clip: true
        onTextEdited: if (root.editable) root.editText = text

        MouseArea {
            anchors.fill: parent
            visible: !root.editable
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.forceActiveFocus()
                root.popup.open()
            }
        }
    }

    indicator: Item {
        width: 24
        height: 24
        anchors.right: parent.right
        anchors.rightMargin: NuTokens.spaceSm
        anchors.verticalCenter: parent.verticalCenter

        Canvas {
            id: arrowCanvas
            anchors.centerIn: parent
            width: 19
            height: 19
            rotation: root.popup.visible ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: NuTokens.motionNormal; easing.type: Easing.OutCubic } }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = root.activeFocus ? 2.1 : 1.7
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.strokeStyle = root.popup.visible || root.hovered || root.activeFocus ? NuTokens.textPrimary : NuTokens.textSecondary
                ctx.beginPath()
                ctx.moveTo(5.2, 7.2)
                ctx.lineTo(9.5, 11.4)
                ctx.lineTo(13.8, 7.2)
                ctx.stroke()
            }

            Connections {
                target: root
                function onActiveFocusChanged() { arrowCanvas.requestPaint() }
                function onHoveredChanged() { arrowCanvas.requestPaint() }
            }
            Connections {
                target: root.popup
                function onVisibleChanged() { arrowCanvas.requestPaint() }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.forceActiveFocus()
                root.popup.open()
            }
        }
    }

    background: Rectangle {
        color: root.enabled ? NuTokens.panelBase : NuTokens.backgroundBase
        border.color: root.activeFocus || root.popup.visible ? NuTokens.accentSky : (root.hovered ? NuTokens.lineStrong : NuTokens.lineSubtle)
        border.width: root.activeFocus ? 2 : 1
        radius: NuTokens.radiusSmall
        Behavior on color { ColorAnimation { duration: NuTokens.motionFast } }
        Behavior on border.color { ColorAnimation { duration: NuTokens.motionFast } }
    }

    delegate: Item {
        id: delegateRoot
        required property int index
        required property string modelData
        width: root.popup.width
        implicitHeight: 34
        height: 34

        HoverHandler {
            id: rowHover
        }

        Rectangle {
            anchors.fill: parent
            color: rowHover.hovered || root.highlightedIndex === delegateRoot.index ? "#eeeeea" : NuTokens.panelBase
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: NuTokens.spaceMd
            anchors.rightMargin: NuTokens.spaceXl
            text: root.formattedText(delegateRoot.modelData)
            color: NuTokens.textPrimary
            font: root.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            clip: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.currentIndex = delegateRoot.index
                root.activated(delegateRoot.index)
                root.popup.close()
            }
        }
    }

    popup: Basic.Popup {
        y: root.height + 2
        width: Math.max(root.width, 420)
        implicitHeight: Math.min(contentItem.implicitHeight, 340)
        padding: 1
        contentItem: ListView {
            id: popupList
            clip: true
            implicitHeight: Math.min(contentHeight, 340)
            model: root.popup.visible ? root.delegateModel : null
            boundsBehavior: Flickable.StopAtBounds
            Basic.ScrollBar.vertical: Basic.ScrollBar {
                policy: popupList.contentHeight > popupList.height ? Basic.ScrollBar.AlwaysOn : Basic.ScrollBar.AlwaysOff
            }
        }
        background: Rectangle {
            color: NuTokens.panelBase
            border.color: NuTokens.lineStrong
            radius: NuTokens.radiusSmall
        }
    }
}
