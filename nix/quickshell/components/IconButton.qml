import QtQuick

Rectangle {
    id: root

    required property var theme
    property string icon: ""
    property var activate: () => {}

    width: theme.popupElementSize
    height: theme.popupElementSize
    radius: theme.popupSectionRadius
    color: hover.containsMouse && enabled ? theme.chipHoverBackground : theme.chipBackground
    opacity: enabled ? 1 : 0.45

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.theme.iconColor
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.ArrowCursor
        hoverEnabled: root.enabled
        onClicked: root.activate()
    }
}
