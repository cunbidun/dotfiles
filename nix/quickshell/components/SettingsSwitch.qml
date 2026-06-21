import QtQuick

Rectangle {
    id: root

    required property var theme
    property bool checked: false
    property var activate: () => {}

    width: Math.round(theme.fontSize * 3.35)
    height: Math.round(theme.fontSize * 1.75)
    radius: height / 2
    color: checked ? theme.selectedBackground : theme.popupBorder
    border.width: checked ? 0 : 1
    border.color: theme.popupMutedText

    Rectangle {
        width: Math.round(parent.height * (switchHover.pressed ? 0.82 : 0.74))
        height: Math.round(parent.height * 0.74)
        radius: height / 2
        x: root.checked ? parent.width - width - Math.round(parent.height * 0.13) : Math.round(parent.height * 0.13)
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? theme.selectedForeground : theme.popupMutedText

        Behavior on x { NumberAnimation { duration: 120 } }
        Behavior on width { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: switchHover

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.activate()
    }
}
