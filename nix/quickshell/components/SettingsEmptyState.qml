import QtQuick

Item {
    id: root

    required property var theme
    property string text: ""

    height: visible ? theme.listRowHeight : 0

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.theme.popupMutedText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
    }
}
