import QtQuick

Item {
    id: root

    required property var theme
    property string label: ""
    property string value: ""

    height: theme.statRowHeight

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.theme.popupText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
        font.bold: true
    }

    Text {
        width: parent.width * 0.58
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.theme.popupMutedText
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
    }
}
