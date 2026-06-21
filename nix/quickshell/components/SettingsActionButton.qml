import QtQuick

Rectangle {
    id: root

    required property var theme
    property string text: ""
    property bool active: false
    property var activate: () => {}

    height: theme.compactRowHeight
    radius: theme.popupSectionRadius
    color: active ? theme.selectedBackground : actionHover.containsMouse ? theme.popupHoverBackground : theme.popupElevatedBackground
    border.width: active ? 0 : theme.popupBorderWidth
    border.color: theme.popupBorder

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.active ? theme.selectedForeground : theme.popupText
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSizeSmall
        font.bold: true
    }

    MouseArea {
        id: actionHover

        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.activate()
    }
}
