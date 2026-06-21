import QtQuick

Rectangle {
    id: root

    required property var theme
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool showSwitch: true
    property var toggle: () => {}

    height: theme.sectionHeaderHeight
    radius: theme.popupSectionRadius
    color: theme.popupSectionBackground

    Column {
        anchors.left: parent.left
        anchors.leftMargin: root.theme.gap
        anchors.right: root.showSwitch ? powerSwitch.left : parent.right
        anchors.rightMargin: root.theme.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: root.theme.popupText
            elide: Text.ElideRight
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSizeSmall
            font.bold: true
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: root.theme.popupMutedText
            elide: Text.ElideRight
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSizeSmall
        }
    }

    SettingsSwitch {
        id: powerSwitch

        visible: root.showSwitch
        theme: root.theme
        anchors.right: parent.right
        anchors.rightMargin: root.theme.gap
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        activate: root.toggle
    }
}
