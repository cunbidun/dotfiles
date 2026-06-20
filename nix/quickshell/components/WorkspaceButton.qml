import QtQuick

Rectangle {
    id: root

    required property var theme
    required property string label
    required property bool active
    required property bool occupied
    required property bool virtualWorkspace
    required property var activate

    readonly property int horizontalPadding: active ? theme.workspaceActivePaddingX : theme.workspaceInactivePaddingX

    implicitWidth: Math.max(labelItem.implicitWidth + horizontalPadding * 2, active ? theme.workspaceActiveMinWidth : theme.workspaceMinWidth)
    implicitHeight: theme.workspaceHeight
    radius: theme.workspaceRadius
    color: {
        if (hoverArea.containsMouse) {
            return theme.moduleHoverBackground;
        }

        if (active) {
            return theme.workspaceActiveBackground;
        }

        if (virtualWorkspace) {
            return theme.workspaceVirtualBackground;
        }

        if (occupied) {
            return theme.workspaceOccupiedBackground;
        }

        return theme.workspaceAvailableBackground;
    }

    Text {
        id: labelItem

        anchors.centerIn: parent
        text: root.label
        color: root.active ? root.theme.workspaceActiveText : root.theme.workspaceText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.activate()
    }
}
