import QtQuick

Item {
    id: root

    required property var theme
    required property var screen

    implicitHeight: theme.barHeight

    Rectangle {
        id: barPanel

        anchors.fill: parent
        radius: root.theme.barRadius
        color: root.theme.barBackground
        border.width: root.theme.barBorderWidth
        border.color: root.theme.barBorder
    }

    Row {
        id: leftModules

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.theme.moduleGap

        Workspaces {
            theme: root.theme
            screen: root.screen
        }
    }
}
