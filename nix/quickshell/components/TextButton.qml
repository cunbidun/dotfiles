import QtQuick

Rectangle {
    id: root

    required property var theme
    property string icon: ""
    property string text: ""
    property var activate: () => {}

    width: labelRow.implicitWidth + theme.gap * 2
    height: theme.popupElementSize
    radius: theme.popupSectionRadius
    color: hover.containsMouse && enabled ? theme.chipHoverBackground : theme.transparentColor
    opacity: enabled ? 1 : 0.55

    Row {
        id: labelRow

        anchors.centerIn: parent
        spacing: root.theme.gap

        Text {
            text: root.icon
            color: root.theme.iconColor
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
        }

        Text {
            text: root.text
            color: root.theme.popupText
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.bold: true
        }
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
