import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15

import "../Theme"

Dialog {
    id: root
    modal: true
    padding: NuTokens.spaceLg
    parent: Overlay.overlay
    property int dialogWidth: 560
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragStartDialogX: 0
    property real dragStartDialogY: 0
    property real dragStartWidth: 0
    property real dragStartHeight: 0
    property int dialogHeight: 0
    property int minimumDialogWidth: 360
    property int minimumDialogHeight: 260
    property bool resizable: false
    width: Math.max(root.minimumDialogWidth, Math.min(root.dialogWidth, Overlay.overlay ? Overlay.overlay.width - NuTokens.spaceXl * 2 : root.dialogWidth))
    height: root.resizable && root.dialogHeight > 0
            ? Math.max(root.minimumDialogHeight, Math.min(root.dialogHeight, Overlay.overlay ? Overlay.overlay.height - NuTokens.spaceXl * 2 : root.dialogHeight))
            : implicitHeight

    default property alias content: body.data
    property string acceptText: "Close"
    property string cancelText: "Cancel"
    property bool showCancel: true
    property bool showHeaderClose: false
    property bool acceptEnabled: true
    property var beforeAccept: null

    function requestAccept() {
        if (!root.acceptEnabled) return
        if (root.beforeAccept && root.beforeAccept() === false) return
        root.accept()
    }

    function centeredX() {
        return Overlay.overlay ? Math.round((Overlay.overlay.width - width) / 2) : 0
    }

    function centeredY() {
        return Overlay.overlay ? Math.round((Overlay.overlay.height - height) / 2) : 0
    }

    function clampToOverlay(value, size, limit) {
        if (!Overlay.overlay) return value
        return Math.max(NuTokens.spaceSm, Math.min(value, limit - size - NuTokens.spaceSm))
    }

    onOpened: {
        x = centeredX()
        y = centeredY()
    }

    background: Rectangle {
        color: NuTokens.panelBase
        border.color: NuTokens.lineStrong
        border.width: 1
        radius: NuTokens.radiusLarge
    }

    header: Item {
        visible: root.title.length > 0
        width: root.width
        implicitHeight: titleLabel.implicitHeight

        Label {
            id: titleLabel
            text: root.title
            width: parent.width - (headerCloseButton.visible ? headerCloseButton.width + NuTokens.spaceMd : 0)
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBodyLarge
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            padding: NuTokens.spaceLg
            bottomPadding: NuTokens.spaceSm
        }

        NuActionButton {
            id: headerCloseButton
            visible: root.showHeaderClose
            anchors.right: parent.right
            anchors.rightMargin: NuTokens.spaceMd
            anchors.top: parent.top
            anchors.topMargin: NuTokens.spaceSm
            text: qsTr("X")
            Layout.preferredWidth: 34
            width: 34
            height: 30
            helpText: qsTr("Close this window. Any recovery already running continues in the background.")
            onClicked: root.reject()
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: headerCloseButton.visible ? headerCloseButton.left : parent.right
            cursorShape: Qt.SizeAllCursor
            onPressed: {
                const point = parent.mapToItem(Overlay.overlay, mouse.x, mouse.y)
                root.dragStartX = point.x
                root.dragStartY = point.y
                root.dragStartDialogX = root.x
                root.dragStartDialogY = root.y
            }
            onPositionChanged: {
                if (!pressed || !Overlay.overlay) return
                const point = parent.mapToItem(Overlay.overlay, mouse.x, mouse.y)
                root.x = root.clampToOverlay(root.dragStartDialogX + point.x - root.dragStartX, root.width, Overlay.overlay.width)
                root.y = root.clampToOverlay(root.dragStartDialogY + point.y - root.dragStartY, root.height, Overlay.overlay.height)
            }
        }
    }

    contentItem: Basic.ScrollView {
        id: contentScroll
        width: Math.max(1, root.availableWidth)
        implicitWidth: Math.max(1, root.availableWidth)
        implicitHeight: Math.min(body.implicitHeight, Overlay.overlay ? Math.max(140, Overlay.overlay.height - 240) : body.implicitHeight)
        contentWidth: Math.max(1, availableWidth)
        clip: true
        Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff

        ColumnLayout {
            id: body
            width: Math.max(1, contentScroll.availableWidth)
            Layout.maximumWidth: Math.max(1, contentScroll.availableWidth)
            implicitWidth: Math.max(1, contentScroll.availableWidth)
            spacing: NuTokens.spaceMd
        }
    }

    footer: Item {
        width: root.width
        implicitHeight: footerRow.implicitHeight + NuTokens.spaceLg + NuTokens.spaceSm

        RowLayout {
            id: footerRow
            anchors.fill: parent
            anchors.leftMargin: NuTokens.spaceLg
            anchors.rightMargin: NuTokens.spaceLg
            anchors.topMargin: NuTokens.spaceSm
            anchors.bottomMargin: NuTokens.spaceLg
            spacing: NuTokens.spaceMd

            Item { Layout.fillWidth: true }
            NuActionButton {
                visible: root.showCancel
                text: root.cancelText
                Layout.preferredWidth: 120
                onClicked: root.reject()
            }
            NuActionButton {
                text: root.acceptText
                primary: true
                enabled: root.acceptEnabled
                Layout.preferredWidth: 140
                onClicked: root.requestAccept()
            }
        }

        MouseArea {
            visible: root.resizable
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 28
            height: 28
            cursorShape: Qt.SizeFDiagCursor
            onPressed: {
                const point = parent.mapToItem(Overlay.overlay, mouse.x, mouse.y)
                root.dragStartX = point.x
                root.dragStartY = point.y
                root.dragStartWidth = root.width
                root.dragStartHeight = root.height
            }
            onPositionChanged: {
                if (!pressed || !Overlay.overlay) return
                const point = parent.mapToItem(Overlay.overlay, mouse.x, mouse.y)
                root.dialogWidth = Math.max(root.minimumDialogWidth,
                                            Math.min(root.dragStartWidth + point.x - root.dragStartX,
                                                     Overlay.overlay.width - root.x - NuTokens.spaceSm))
                root.dialogHeight = Math.max(root.minimumDialogHeight,
                                             Math.min(root.dragStartHeight + point.y - root.dragStartY,
                                                      Overlay.overlay.height - root.y - NuTokens.spaceSm))
            }
        }
    }
}
