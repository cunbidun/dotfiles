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
    width: implicitWidth
    height: implicitHeight
    radius: theme.workspaceRadius
    color: active ? theme.selectedBackground : theme.notSelectedBackground

    Text {
        id: labelItem

        anchors.centerIn: parent
        height: root.height
        text: root.label
        color: root.active ? root.theme.selectedForeground : root.theme.notSelectedForeground
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize
        font.weight: Font.Medium
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.activate()
    }
}
