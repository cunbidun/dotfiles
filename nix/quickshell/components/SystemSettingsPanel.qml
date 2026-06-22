import QtQuick

Item {
    id: root

    required property var theme
    required property var wifiSource
    required property var bluetoothSource
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
                            font.pixelSize: root.theme.fontSizeMedium
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - root.theme.popupElementSize
                            text: "Settings"
                            color: root.theme.popupText
                            elide: Text.ElideRight
                            font.family: root.theme.fontFamilyEmphasis
                            font.pixelSize: root.theme.fontSizeMedium
                        }
                    }

                    SettingsTabButton { theme: root.theme; width: parent.width; icon: "󰤨"; text: "Network"; active: root.currentTab === "network"; activate: () => root.currentTab = "network" }
                    SettingsTabButton { theme: root.theme; width: parent.width; icon: "󰂯"; text: "Bluetooth"; active: root.currentTab === "bluetooth"; activate: () => root.currentTab = "bluetooth" }
                }
            }

            Item {
                width: parent.width - root.sidebarWidth
                height: parent.height

                Flickable {
                    anchors.fill: parent
                    anchors.margins: root.theme.gap
                    anchors.topMargin: root.theme.gap * 2 + root.theme.popupElementSize
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

        Rectangle {
            id: closeButton

            width: root.theme.popupElementSize
            height: root.theme.popupElementSize
            anchors.top: parent.top
            anchors.topMargin: root.theme.gap
            anchors.right: parent.right
            anchors.rightMargin: root.theme.gap
            radius: root.theme.popupSectionRadius
            color: closeHover.containsMouse ? root.theme.chipHoverBackground : root.theme.popupSectionBackground

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: root.theme.popupText
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
                hoverEnabled: true
                onClicked: root.close()
            }
        }
    }

    Component {
        id: networkPage

        SystemNetworkSettings {
            theme: root.theme
            width: contentLoader.width - root.theme.gap * 2
            wifiSource: root.wifiSource
            goBack: root.close
        }
    }

    Component {
        id: bluetoothPage

        SystemBluetoothSettings {
            theme: root.theme
            width: contentLoader.width - root.theme.gap * 2
            bluetoothSource: root.bluetoothSource
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

        height: theme.compactRowHeight
        radius: theme.popupSectionRadius
        color: hover.containsMouse ? theme.chipHoverBackground : active ? theme.selectedBackground : theme.transparentColor

        Row {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap

            Text { text: tabButton.icon; color: tabButton.active ? theme.selectedForeground : theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize }
            Text { text: tabButton.text; color: tabButton.active ? theme.selectedForeground : theme.popupText; font.family: theme.fontFamilyEmphasis; font.pixelSize: theme.fontSizeSmall }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            hoverEnabled: true
            onClicked: tabButton.activate()
        }
    }
}
