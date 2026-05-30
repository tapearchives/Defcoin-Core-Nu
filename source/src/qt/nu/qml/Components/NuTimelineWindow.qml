import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Theme"

Item {
    id: root
    implicitHeight: 52
    activeFocusOnTab: true

    property real start: 0
    property real end: 1
    property real minSpan: 0.04
    property alias label: title.text

    signal viewportChanged(real start, real end)

    function clampWindow(s, e) {
        let span = Math.max(root.minSpan, e - s)
        s = Math.max(0, Math.min(1 - span, s))
        e = Math.min(1, s + span)
        root.start = s
        root.end = e
        root.viewportChanged(root.start, root.end)
    }

    function moveWindow(delta) {
        root.clampWindow(root.start + delta, root.end + delta)
    }

    function scaleWindow(factor) {
        const center = (root.start + root.end) / 2
        const span = Math.max(root.minSpan, Math.min(1, (root.end - root.start) * factor))
        root.clampWindow(center - span / 2, center + span / 2)
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Left) {
            root.moveWindow(-0.02)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.moveWindow(0.02)
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            root.scaleWindow(0.9)
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Minus) {
            root.scaleWindow(1.1)
            event.accepted = true
        }
    }

    Label {
        id: title
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        text: "Timeline"
        color: NuTokens.textSecondary
        font.pixelSize: NuTokens.fontSmall
        elide: Text.ElideRight
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.topMargin: 12
        height: 8
        radius: 4
        color: NuTokens.lineSubtle
        border.color: root.activeFocus ? NuTokens.lineStrong : "transparent"
        border.width: root.activeFocus ? 1 : 0

        Rectangle {
            id: viewport
            x: Math.round(root.start * track.width)
            width: Math.max(18, Math.round((root.end - root.start) * track.width))
            anchors.verticalCenter: parent.verticalCenter
            height: 18
            radius: 3
            color: NuTokens.accentSky
            border.color: NuTokens.lineStrong
            opacity: 0.9
        }

        Rectangle {
            id: leftHandle
            x: viewport.x - width / 2
            anchors.verticalCenter: viewport.verticalCenter
            width: 10
            height: 24
            radius: 2
            color: NuTokens.panelBase
            border.color: NuTokens.lineStrong
        }

        Rectangle {
            id: rightHandle
            x: viewport.x + viewport.width - width / 2
            anchors.verticalCenter: viewport.verticalCenter
            width: 10
            height: 24
            radius: 2
            color: NuTokens.panelBase
            border.color: NuTokens.lineStrong
        }

        MouseArea {
            id: grabber
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            cursorShape: {
                const normalizedX = mouseX / track.width
                const left = root.start
                const right = root.end
                if (Math.abs(normalizedX - left) < 0.035 || Math.abs(normalizedX - right) < 0.035) return Qt.SizeHorCursor
                if (normalizedX > left && normalizedX < right) return Qt.OpenHandCursor
                return Qt.PointingHandCursor
            }

            property string mode: "none"
            property real pressStart: 0
            property real pressEnd: 1
            property real pressX: 0

            onPressed: (mouse) => {
                pressStart = root.start
                pressEnd = root.end
                pressX = Math.max(0, Math.min(track.width, mouse.x))
                const normalizedX = pressX / Math.max(1, track.width)
                const edgeThreshold = Math.max(0.035, 12 / Math.max(1, track.width))
                if (Math.abs(normalizedX - root.start) < edgeThreshold) {
                    mode = "left"
                } else if (Math.abs(normalizedX - root.end) < edgeThreshold) {
                    mode = "right"
                } else if (normalizedX > root.start && normalizedX < root.end) {
                    mode = "move"
                    cursorShape = Qt.ClosedHandCursor
                } else {
                    const span = root.end - root.start
                    root.clampWindow(normalizedX - span / 2, normalizedX + span / 2)
                    mode = "move"
                    pressStart = root.start
                    pressEnd = root.end
                    pressX = Math.max(0, Math.min(track.width, mouse.x))
                }
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                const normalizedX = Math.max(0, Math.min(track.width, mouse.x)) / Math.max(1, track.width)
                if (mode === "left") {
                    root.clampWindow(Math.min(normalizedX, pressEnd - root.minSpan), pressEnd)
                } else if (mode === "right") {
                    root.clampWindow(pressStart, Math.max(normalizedX, pressStart + root.minSpan))
                } else if (mode === "move") {
                    const delta = (Math.max(0, Math.min(track.width, mouse.x)) - pressX) / Math.max(1, track.width)
                    root.clampWindow(pressStart + delta, pressEnd + delta)
                }
            }

            onReleased: {
                mode = "none"
                cursorShape = Qt.OpenHandCursor
            }
        }
    }
}
