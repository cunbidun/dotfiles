import QtQuick
import Quickshell

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    property var openSettings: () => {}
    readonly property var adapter: bluetoothSource.adapter
    readonly property bool enabled: bluetoothSource.enabled
    readonly property bool discovering: bluetoothSource.discovering
    readonly property var sortedDevices: bluetoothSource.devices.slice(0, 8)

    spacing: theme.gap

    BluetoothDeviceSource {
        id: bluetoothSource
    }

    Rectangle {
        width: parent.width
        height: root.theme.sectionHeaderHeight
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground

        TextButton {
            theme: root.theme
            anchors.left: parent.left
            anchors.leftMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            icon: "󰁍"
            text: "Bluetooth"
            activate: root.goBack
        }

        SettingsSwitch {
            id: powerSwitch

            theme: root.theme
            anchors.right: parent.right
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            checked: root.enabled
            activate: () => bluetoothSource.setEnabled(!root.enabled)
        }
    }

    Text {
        width: parent.width
        text: {
            const connected = bluetoothSource.connectedDevices.length;
            return `${bluetoothSource.devices.length} devices available${connected > 0 ? ` (${connected} connected)` : ""}`;
        }
        color: root.theme.popupMutedText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
    }

    Column {
        width: parent.width
        spacing: root.theme.gap

        Repeater {
            model: root.sortedDevices

            Rectangle {
                id: deviceRow

                required property var modelData
                readonly property bool connected: modelData.connected
                readonly property bool loading: String(modelData.state).toLowerCase().includes("connecting") || String(modelData.state).toLowerCase().includes("disconnecting")

                width: parent.width
                height: root.theme.listRowHeight
                radius: root.theme.popupSectionRadius
                color: deviceHover.containsMouse || connected ? root.theme.chipHoverBackground : root.theme.popupSectionBackground

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.bluetoothIcon(deviceRow.modelData.icon)
                    color: deviceRow.connected ? root.theme.iconActiveColor : root.theme.iconColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.popupElementSize
                    anchors.right: connectIcon.left
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: bluetoothSource.displayName(deviceRow.modelData)
                        color: deviceRow.connected ? root.theme.popupAccent : root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: deviceRow.connected
                    }

                    Text {
                        width: parent.width
                        text: deviceRow.connected ? "Connected" : bluetoothSource.isPaired(deviceRow.modelData) ? "Paired" : "Available"
                        color: root.theme.popupMutedText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSizeSmall
                    }
                }

                Text {
                    id: batteryIcon

                    visible: deviceRow.connected && deviceRow.modelData.batteryAvailable
                    anchors.right: connectIcon.left
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.round(deviceRow.modelData.battery * 100)}%`
                    color: root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                }

                Text {
                    id: connectIcon

                    anchors.right: forgetIcon.left
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: deviceRow.loading ? "󰑓" : deviceRow.connected ? "󰌙" : "󰌘"
                    color: deviceRow.connected ? root.theme.iconActiveColor : root.theme.iconColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                Text {
                    id: forgetIcon

                    visible: bluetoothSource.isPaired(deviceRow.modelData)
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰆴"
                    color: root.theme.iconMutedColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -root.theme.gap * 0.6
                        cursorShape: Qt.ArrowCursor
                        hoverEnabled: true
                        onClicked: bluetoothSource.forgetDevice(deviceRow.modelData)
                    }
                }

                MouseArea {
                    id: deviceHover

                    anchors.fill: parent
                    anchors.rightMargin: forgetIcon.visible ? root.theme.popupElementSize : 0
                    cursorShape: Qt.ArrowCursor
                    hoverEnabled: true
                    onClicked: bluetoothSource.toggleDevice(deviceRow.modelData)
                }
            }
        }

        Item {
            width: parent.width
            height: root.sortedDevices.length === 0 ? root.theme.popupElementSize * 2 : 0
            visible: root.sortedDevices.length === 0

            Text {
                anchors.centerIn: parent
                text: root.enabled ? "No Bluetooth devices" : "Bluetooth disabled"
                color: root.theme.popupMutedText
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize
            }
        }
    }

    SettingsRow {
        theme: root.theme
        width: parent.width
        icon: "󰒓"
        text: "Bluetooth Settings"
        activate: root.openSettings
    }

    component SettingsRow: Rectangle {
        required property var theme
        property string icon: ""
        property string text: ""
        property var activate: () => {}

        height: theme.compactRowHeight
        radius: theme.popupSectionRadius
        color: hover.containsMouse ? theme.chipHoverBackground : theme.popupSectionBackground
        border.width: theme.popupBorderWidth
        border.color: theme.popupBorder

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: theme.gap
            anchors.rightMargin: theme.gap
            spacing: theme.gap

            Text { text: icon; color: theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
            Text { width: parent.width - theme.popupElementSize; text: parent.parent.text; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSizeSmall; font.bold: true; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea { id: hover; anchors.fill: parent; cursorShape: Qt.ArrowCursor; hoverEnabled: true; onClicked: parent.activate() }
    }

    function bluetoothIcon(iconName) {
        const name = String(iconName || "").toLowerCase();
        if (name.includes("audio") || name.includes("headset") || name.includes("headphone")) return "󰋋";
        if (name.includes("keyboard")) return "󰌌";
        if (name.includes("mouse")) return "󰍽";
        if (name.includes("phone")) return "󰏲";
        return "󰂯";
    }

}
