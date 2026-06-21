import QtQuick
import Quickshell
import Quickshell.Bluetooth

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    property var openSettings: () => {}
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var sortedDevices: [...Bluetooth.devices.values].sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.bonded || b.paired) - Number(a.bonded || a.paired) || String(a.name || "").localeCompare(String(b.name || ""))).slice(0, 8)

    spacing: theme.gap

    Rectangle {
        width: parent.width
        height: root.theme.popupElementSize * 1.45
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

        ToggleButton {
            id: powerButton

            theme: root.theme
            anchors.right: discoverButton.left
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            checked: root.enabled
            text: root.enabled ? "On" : "Off"
            activate: () => {
                if (root.adapter) {
                    root.adapter.enabled = !root.adapter.enabled;
                }
            }
        }

        ToggleButton {
            id: discoverButton

            theme: root.theme
            anchors.right: parent.right
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.enabled
            checked: root.discovering
            text: root.discovering ? "Scan" : "Idle"
            activate: () => {
                if (root.adapter) {
                    root.adapter.discovering = !root.adapter.discovering;
                }
            }
        }
    }

    Text {
        width: parent.width
        text: {
            const connected = Bluetooth.devices.values.filter(device => device.connected).length;
            return `${Bluetooth.devices.values.length} devices available${connected > 0 ? ` (${connected} connected)` : ""}`;
        }
        color: root.theme.popupMutedText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize * 0.86
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
                height: root.theme.popupElementSize * 1.25
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
                        text: deviceRow.modelData.name || deviceRow.modelData.address || "Bluetooth device"
                        color: deviceRow.connected ? root.theme.popupAccent : root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: deviceRow.connected
                    }

                    Text {
                        width: parent.width
                        text: deviceRow.connected ? "Connected" : deviceRow.modelData.bonded || deviceRow.modelData.paired ? "Paired" : "Available"
                        color: root.theme.popupMutedText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 0.76
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
                    font.pixelSize: root.theme.fontSize * 0.78
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

                    visible: deviceRow.modelData.bonded || deviceRow.modelData.paired
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰆴"
                    color: root.theme.iconMutedColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.9

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -root.theme.gap * 0.6
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: deviceRow.modelData.forget()
                    }
                }

                MouseArea {
                    id: deviceHover

                    anchors.fill: parent
                    anchors.rightMargin: forgetIcon.visible ? root.theme.popupElementSize : 0
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: deviceRow.modelData.connected = !deviceRow.modelData.connected
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

    component ToggleButton: Rectangle {
        required property var theme
        property bool checked: false
        property string text: ""
        property var activate: () => {}

        width: Math.max(theme.popupElementSize * 1.65, label.implicitWidth + theme.gap * 2)
        height: theme.popupElementSize
        radius: theme.popupSectionRadius
        color: hover.containsMouse ? theme.chipHoverBackground : checked ? theme.selectedBackground : theme.chipBackground
        opacity: enabled ? 1 : 0.55

        Text { id: label; anchors.centerIn: parent; text: parent.text; color: parent.checked ? theme.selectedForeground : theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.82; font.bold: true }
        MouseArea { id: hover; anchors.fill: parent; enabled: parent.enabled; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: parent.activate() }
    }

    component SettingsRow: Rectangle {
        required property var theme
        property string icon: ""
        property string text: ""
        property var activate: () => {}

        height: theme.popupElementSize * 1.15
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
            Text { width: parent.width - theme.popupElementSize; text: parent.parent.text; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.88; font.bold: true; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea { id: hover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: parent.activate() }
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
