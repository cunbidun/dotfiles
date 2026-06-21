import QtQuick

Item {
    id: root

    required property var theme
    property string currentTab: "network"
    property var close: () => {}

    readonly property int panelWidth: Math.min(width - theme.gap * 4, theme.fontSize * 68)
    readonly property int panelHeight: Math.min(height - theme.gap * 6, theme.fontSize * 52)
    readonly property int sidebarWidth: Math.round(theme.fontSize * 14.5)

    anchors.fill: parent

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
    }

    Rectangle {
        id: panel

        width: root.panelWidth
        height: root.panelHeight
        anchors.centerIn: parent
        radius: root.theme.popupSectionRadius
        color: root.theme.popupBackground
        border.width: root.theme.popupBorderWidth
        border.color: root.theme.popupBorder

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Row {
            anchors.fill: parent

            Rectangle {
                width: root.sidebarWidth
                height: parent.height
                radius: root.theme.popupSectionRadius
                color: root.theme.popupSectionBackground

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: root.theme.popupBorder
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: root.theme.gap
                    spacing: root.theme.gap

                    Row {
                        width: parent.width
                        height: root.theme.popupElementSize
                        spacing: root.theme.gap

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰒓"
                            color: root.theme.popupAccent
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize * 1.1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - root.theme.popupElementSize
                            text: "Settings"
                            color: root.theme.popupText
                            elide: Text.ElideRight
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize * 1.05
                            font.bold: true
                        }
                    }

                    SettingsTabButton { theme: root.theme; width: parent.width; icon: "󰤨"; text: "Network"; active: root.currentTab === "network"; activate: () => root.currentTab = "network" }
                    SettingsTabButton { theme: root.theme; width: parent.width; icon: "󰂯"; text: "Bluetooth"; active: root.currentTab === "bluetooth"; activate: () => root.currentTab = "bluetooth" }
                    Item { width: 1; height: 1 }

                    Rectangle {
                        width: parent.width
                        height: root.theme.popupElementSize * 1.1
                        radius: root.theme.popupSectionRadius
                        color: closeHover.containsMouse ? root.theme.chipHoverBackground : root.theme.transparentColor

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.gap
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.theme.gap

                            Text { text: "󰅖"; color: root.theme.popupText; font.family: root.theme.fontFamily; font.pixelSize: root.theme.fontSize }
                            Text { text: "Close"; color: root.theme.popupText; font.family: root.theme.fontFamily; font.pixelSize: root.theme.fontSize * 0.9; font.bold: true }
                        }

                        MouseArea {
                            id: closeHover

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.close()
                        }
                    }
                }
            }

            Item {
                width: parent.width - root.sidebarWidth
                height: parent.height

                Flickable {
                    anchors.fill: parent
                    anchors.margins: root.theme.gap
                    clip: true
                    contentWidth: width
                    contentHeight: Math.max(height, contentLoader.item ? contentLoader.item.implicitHeight : height)

                    Loader {
                        id: contentLoader

                        width: parent.width
                    sourceComponent: root.currentTab === "bluetooth" ? bluetoothPage : networkPage
                    }
                }
            }
        }
    }

    Component {
        id: networkPage

        SystemNetworkSettings {
            theme: root.theme
            width: contentLoader.width - root.theme.gap * 2
            goBack: root.close
        }
    }

    Component {
        id: bluetoothPage

        SystemBluetoothSettings {
            theme: root.theme
            width: contentLoader.width - root.theme.gap * 2
            goBack: root.close
        }
    }

    component SettingsTabButton: Rectangle {
        id: tabButton

        required property var theme
        property string icon: ""
        property string text: ""
        property bool active: false
        property var activate: () => {}

        height: theme.popupElementSize * 1.15
        radius: theme.popupSectionRadius
        color: hover.containsMouse ? theme.chipHoverBackground : active ? theme.selectedBackground : theme.transparentColor

        Row {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap

            Text { text: tabButton.icon; color: tabButton.active ? theme.selectedForeground : theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize }
            Text { text: tabButton.text; color: tabButton.active ? theme.selectedForeground : theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.9; font.bold: true }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: tabButton.activate()
        }
    }
}
