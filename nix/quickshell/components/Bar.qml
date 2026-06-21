import QtQuick

Item {
    id: root

    required property var theme
    required property var screen
    required property var panelWindow
    property var openSettings: tab => {}

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

        HyprLayout {
            theme: root.theme
        }

        Submap {
            theme: root.theme
        }

        WindowTitle {
            theme: root.theme
            screen: root.screen
        }
    }

    Row {
        id: rightModules

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.theme.moduleGap

        SystemTray {
            theme: root.theme
            panelWindow: root.panelWindow
        }

        Dashboard {
            theme: root.theme
            panelWindow: root.panelWindow
            openSettings: root.openSettings
        }

        NotificationCenter {
            theme: root.theme
            panelWindow: root.panelWindow
        }

        DateTime {
            theme: root.theme
            panelWindow: root.panelWindow
        }
    }
}
