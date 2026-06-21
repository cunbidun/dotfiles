import QtQuick
import Quickshell.Bluetooth

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var connectedDevices: root.sortedDevices().filter(device => device.connected).slice(0, 4)
    readonly property var pairedDevices: root.sortedDevices().filter(device => !device.connected && (device.bonded || device.paired)).slice(0, 5)
    readonly property var availableDevices: root.sortedDevices().filter(device => !device.connected && !(device.bonded || device.paired)).slice(0, 5)

    spacing: theme.gap

    Rectangle {
        width: parent.width
        height: headerContent.implicitHeight + root.theme.gap * 2
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground

        Row {
            id: headerContent

            anchors.left: parent.left
            anchors.leftMargin: root.theme.gap
            anchors.right: parent.right
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.gap

            TextButton {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                icon: "󰁍"
                text: "Bluetooth"
                activate: root.goBack
            }

            Column {
                width: parent.width - root.theme.popupElementSize * 9
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Connect keyboards, headphones, controllers, and other devices."
                    color: root.theme.popupText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.86
                }

                Text {
                    width: parent.width
                    text: root.enabled ? (root.discovering ? "Scanning for nearby devices." : "Start scan to find nearby devices.") : "Turn on Bluetooth to connect devices."
                    color: root.theme.popupMutedText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.76
                }
            }

            IconButton {
                id: scanButton

                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                enabled: root.enabled
                icon: root.discovering ? "󰑓" : "󰐊"
                activate: () => {
                    if (root.adapter) {
                        root.adapter.discovering = !root.adapter.discovering;
                    }
                }
            }

            SettingsSwitch {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                checked: root.enabled
                activate: () => {
                    if (root.adapter) {
                        root.adapter.enabled = !root.adapter.enabled;
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: adapterColumn.implicitHeight + root.theme.gap * 2
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground
        border.width: root.theme.popupBorderWidth
        border.color: root.theme.popupBorder

        Column {
            id: adapterColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.theme.gap
            spacing: 0

            Row {
                width: parent.width
                height: root.theme.popupElementSize * 1.1
                spacing: root.theme.gap

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.enabled ? "󰂯" : "󰂲"
                    color: root.enabled ? root.theme.iconActiveColor : root.theme.iconMutedColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 1.25
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - root.theme.popupElementSize
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.adapter ? (root.adapter.name || "Bluetooth") : "No Adapter"
                        color: root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.enabled ? (root.discovering ? "Discoverable and scanning" : "Ready") : "Disabled"
                        color: root.theme.popupMutedText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 0.78
                    }
                }
            }

            InfoRow { theme: root.theme; label: "Connected"; value: String(root.connectedDevices.length) }
            InfoRow { theme: root.theme; label: "Paired"; value: String(root.pairedDevices.length) }
            InfoRow { theme: root.theme; label: "Available"; value: String(root.availableDevices.length) }
        }
    }

    DeviceSection {
        theme: root.theme
        width: parent.width
        title: "Connected"
        emptyText: "No connected devices"
        devices: root.connectedDevices
    }

    DeviceSection {
        theme: root.theme
        width: parent.width
        title: "Paired"
        emptyText: "No paired devices"
        devices: root.pairedDevices
    }

    DeviceSection {
        theme: root.theme
        width: parent.width
        title: root.discovering ? "Available" : "Available (scan off)"
        emptyText: root.enabled ? (root.discovering ? "Searching for devices" : "Start scan to find devices") : "Bluetooth disabled"
        devices: root.enabled && root.discovering ? root.availableDevices : []
    }

    function sortedDevices() {
        return [...Bluetooth.devices.values].sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.bonded || b.paired) - Number(a.bonded || a.paired) || String(a.name || a.address || "").localeCompare(String(b.name || b.address || "")));
    }

    component DeviceSection: Column {
        id: deviceSection

        required property var theme
        property string title: ""
        property string emptyText: ""
        property var devices: []

        spacing: theme.gap

        Text {
            width: parent.width
            text: parent.title
            color: theme.popupMutedText
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize * 0.86
            font.bold: true
        }

        Repeater {
            model: deviceSection.devices

            DeviceRow {
                theme: deviceSection.theme
                width: deviceSection.width
                device: modelData
            }
        }

        Item {
            width: deviceSection.width
            height: deviceSection.devices.length === 0 ? theme.popupElementSize * 1.4 : 0
            visible: deviceSection.devices.length === 0

            Text {
                anchors.centerIn: parent
                text: deviceSection.emptyText
                color: theme.popupMutedText
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize * 0.86
            }
        }
    }

    component DeviceRow: Rectangle {
        id: deviceRow

        required property var theme
        required property var device
        readonly property bool connected: !!device.connected
        readonly property bool paired: !!(device.bonded || device.paired)
        readonly property bool loading: String(device.state).toLowerCase().includes("connecting") || String(device.state).toLowerCase().includes("disconnecting") || String(device.state).toLowerCase().includes("pairing")

        height: theme.popupElementSize * 1.25
        radius: theme.popupSectionRadius
        color: deviceHover.containsMouse || connected ? theme.chipHoverBackground : theme.popupSectionBackground
        opacity: loading ? 0.7 : 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            text: deviceRow.bluetoothIcon(deviceRow.device.icon)
            color: deviceRow.connected ? theme.popupAccent : theme.popupText
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: theme.popupElementSize
            anchors.right: forgetIcon.left
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: deviceRow.device.name || deviceRow.device.address || "Bluetooth device"
                color: deviceRow.connected ? theme.popupAccent : theme.popupText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize
                font.bold: deviceRow.connected
            }

            Text {
                width: parent.width
                text: deviceRow.statusText()
                color: theme.popupMutedText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize * 0.76
            }
        }

        Text {
            id: connectText

            anchors.right: forgetIcon.visible ? forgetIcon.left : parent.right
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            text: deviceRow.loading ? "󰑓" : deviceRow.connected ? "Disconnect" : "Connect"
            color: deviceRow.connected ? theme.popupAccent : theme.popupText
            font.family: theme.fontFamily
            font.pixelSize: deviceRow.connected || !deviceRow.loading ? theme.fontSize * 0.78 : theme.fontSize
            font.bold: !deviceRow.loading
        }

        Text {
            id: forgetIcon

            visible: deviceRow.paired
            anchors.right: parent.right
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            text: "󰆴"
            color: theme.popupMutedText
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize * 0.9

            MouseArea {
                anchors.fill: parent
                anchors.margins: -theme.gap * 0.7
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: deviceRow.device.forget()
            }
        }

        MouseArea {
            id: deviceHover

            anchors.fill: parent
            anchors.rightMargin: deviceRow.paired ? theme.popupElementSize : 0
            cursorShape: deviceRow.loading ? Qt.ArrowCursor : Qt.PointingHandCursor
            hoverEnabled: !deviceRow.loading
            enabled: !deviceRow.loading
            onClicked: deviceRow.device.connected = !deviceRow.device.connected
        }

        function statusText() {
            if (deviceRow.loading) return "Working";
            if (deviceRow.connected && deviceRow.device.batteryAvailable) return `Connected • ${Math.round(deviceRow.device.battery * 100)}%`;
            if (deviceRow.connected) return "Connected";
            if (deviceRow.paired) return "Paired";
            if (deviceRow.device.signalStrength > 0) return `Available • ${deviceRow.device.signalStrength}%`;
            return "Available";
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

    component InfoRow: Item {
        required property var theme
        property string label: ""
        property string value: ""

        width: parent.width
        height: theme.statRowHeight

        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: label; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.86; font.bold: true }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: value; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.86 }
    }

}
