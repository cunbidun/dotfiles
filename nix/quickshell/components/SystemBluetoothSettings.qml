import QtQuick

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    readonly property var adapter: bluetoothSource.adapter
    readonly property bool enabled: bluetoothSource.enabled
    readonly property bool discovering: bluetoothSource.discovering
    readonly property var connectedDevices: bluetoothSource.connectedDevices.slice(0, 4)
    readonly property var pairedDevices: bluetoothSource.pairedDevices.slice(0, 5)
    readonly property var availableDevices: bluetoothSource.availableDevices.slice(0, 5)
    readonly property string status: bluetoothSource.status
    property var pairingDevice: null
    property var pairingPrompt: null
    property string pairingSecret: ""

    spacing: theme.gap

    BluetoothDeviceSource {
        id: bluetoothSource

        onPairingPrompt: prompt => {
            root.pairingPrompt = prompt;
            root.pairingSecret = "";
        }

        onPairingCancelled: root.cancelPairing()
    }

    SettingsHeader {
        theme: root.theme
        width: parent.width
        title: "Bluetooth"
        subtitle: root.enabled ? "Nearby devices update automatically." : "Turn on Bluetooth to connect devices."
        checked: root.enabled
        toggle: () => bluetoothSource.setEnabled(!root.enabled)
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
                height: root.theme.compactRowHeight
                spacing: root.theme.gap

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.enabled ? "󰂯" : "󰂲"
                    color: root.enabled ? root.theme.iconActiveColor : root.theme.iconMutedColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeLarge
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - root.theme.popupElementSize
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.adapter ? bluetoothSource.adapterDisplayName : "No Adapter"
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
                        font.pixelSize: root.theme.fontSizeSmall
                    }
                }
            }

            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Connected"; value: String(root.connectedDevices.length) }
            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Paired"; value: String(root.pairedDevices.length) }
            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Available"; value: String(root.availableDevices.length) }
        }
    }

    Text {
        width: parent.width
        visible: root.status.length > 0
        text: root.status
        color: root.theme.popupMutedText
        elide: Text.ElideRight
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
    }

    Rectangle {
        id: pairingCard

        width: parent.width
        height: visible ? pairingColumn.implicitHeight + root.theme.gap * 2 : 0
        visible: root.pairingDevice !== null || root.pairingPrompt !== null
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground
        border.width: root.theme.popupBorderWidth
        border.color: root.theme.popupBorder

        Column {
            id: pairingColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.theme.gap
            spacing: root.theme.gap

            Text {
                width: parent.width
                text: root.pairingPrompt ? root.promptTitle() : `Pair ${bluetoothSource.displayName(root.pairingDevice)}`
                color: root.theme.popupText
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.promptBody()
                color: root.theme.popupMutedText
                wrapMode: Text.WordWrap
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeSmall
            }

            Rectangle {
                width: parent.width
                height: root.promptNeedsInput() ? root.theme.compactRowHeight : 0
                visible: root.promptNeedsInput()
                radius: root.theme.popupSectionRadius
                color: root.theme.popupElevatedBackground
                border.width: root.theme.popupBorderWidth
                border.color: promptInput.activeFocus ? root.theme.selectedBackground : root.theme.popupBorder

                TextInput {
                    id: promptInput

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.theme.gap
                    anchors.rightMargin: root.theme.gap
                    text: root.pairingSecret
                    echoMode: TextInput.Password
                    color: root.theme.popupText
                    selectionColor: root.theme.selectedBackground
                    selectedTextColor: root.theme.selectedForeground
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                    onTextChanged: root.pairingSecret = text
                    Keys.onReturnPressed: root.acceptPairingPrompt()
                }
            }

            Row {
                width: parent.width
                height: root.theme.compactRowHeight
                spacing: root.theme.gap

                SettingsActionButton { theme: root.theme; width: (parent.width - root.theme.gap) / 2; text: "Cancel"; activate: root.cancelPairing }
                SettingsActionButton { theme: root.theme; width: (parent.width - root.theme.gap) / 2; text: root.pairingPrompt ? "Allow" : "Pair"; active: true; activate: root.pairingPrompt ? root.acceptPairingPrompt : root.submitPairing }
            }
        }
    }

    DeviceSection {
        theme: root.theme
        width: parent.width
        title: "Connected"
        emptyText: "No connected devices"
        devices: root.connectedDevices
        requestPair: root.requestPairing
    }

    DeviceSection {
        theme: root.theme
        width: parent.width
        title: "Paired"
        emptyText: "No paired devices"
        devices: root.pairedDevices
        requestPair: root.requestPairing
    }

    DeviceSection {
        theme: root.theme
        width: parent.width
        title: "Available"
        emptyText: root.enabled ? "Searching for devices" : "Bluetooth disabled"
        devices: root.enabled ? root.availableDevices : []
        requestPair: root.requestPairing
    }

    function requestPairing(device) {
        root.pairingDevice = device;
    }

    function submitPairing() {
        if (!root.pairingDevice) {
            return;
        }
        bluetoothSource.pairDevice(root.pairingDevice);
        root.cancelPairing();
    }

    function cancelPairing() {
        if (root.pairingPrompt) {
            bluetoothSource.cancelPairingPrompt(root.pairingPrompt);
        }
        root.pairingDevice = null;
        root.pairingPrompt = null;
        root.pairingSecret = "";
    }

    function acceptPairingPrompt() {
        if (!root.pairingPrompt) {
            return;
        }
        const fields = root.pairingPrompt.fields || [];
        const secrets = {};
        if (fields.indexOf("pin") !== -1) secrets.pin = root.pairingSecret;
        if (fields.indexOf("passkey") !== -1) secrets.passkey = root.pairingSecret;
        if (fields.indexOf("decision") !== -1) secrets.decision = "yes";
        bluetoothSource.submitPairingPrompt(root.pairingPrompt.token, true, secrets);
        root.pairingPrompt = null;
        root.pairingSecret = "";
    }

    function promptNeedsInput() {
        const fields = root.pairingPrompt?.fields || [];
        return fields.indexOf("pin") !== -1 || fields.indexOf("passkey") !== -1;
    }

    function promptTitle() {
        const name = root.pairingPrompt?.deviceName || "Bluetooth device";
        const type = root.pairingPrompt?.type || "confirm";
        if (type === "pin" || type === "passkey") return `Enter code for ${name}`;
        if (type === "display-pin" || type === "display-passkey") return `Code for ${name}`;
        return `Pair ${name}`;
    }

    function promptBody() {
        if (!root.pairingPrompt) {
            return "Confirm pairing on the device if a prompt appears.";
        }
        const display = root.pairingPrompt.display || "";
        const type = root.pairingPrompt.type || "confirm";
        if (type === "display-pin" || type === "display-passkey") return display.length > 0 ? `Enter ${display} on the device.` : "Enter the displayed code on the device.";
        if (type === "confirm") return display.length > 0 ? `Confirm code ${display} on both devices.` : "Confirm pairing on both devices.";
        if (type === "authorize" || type === "authorize-service") return "Allow this Bluetooth connection.";
        return "Enter the Bluetooth pairing code.";
    }

    function deviceName(device) {
        return bluetoothSource.displayName(device);
    }

    component DeviceSection: Column {
        id: deviceSection

        required property var theme
        property string title: ""
        property string emptyText: ""
        property var devices: []
        property var requestPair: device => {}

        spacing: theme.gap

        SettingsSectionLabel {
            theme: deviceSection.theme
            width: parent.width
            text: parent.title
        }

        Repeater {
            model: deviceSection.devices

            DeviceRow {
                theme: deviceSection.theme
                width: deviceSection.width
                device: modelData
                deviceSource: bluetoothSource
                requestPair: deviceSection.requestPair
            }
        }

        SettingsEmptyState {
            theme: deviceSection.theme
            width: deviceSection.width
            visible: deviceSection.devices.length === 0
            text: deviceSection.emptyText
        }
    }

    component DeviceRow: Rectangle {
        id: deviceRow

        required property var theme
        required property var device
        required property var deviceSource
        property var requestPair: device => {}
        readonly property bool connected: !!device.connected
        readonly property bool paired: deviceSource.isPaired(device)
        readonly property bool loading: String(device.state).toLowerCase().includes("connecting") || String(device.state).toLowerCase().includes("disconnecting") || String(device.state).toLowerCase().includes("pairing")

        height: theme.listRowHeight
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
                text: deviceRow.deviceSource.displayName(deviceRow.device)
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
                font.pixelSize: theme.fontSizeSmall
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
            font.pixelSize: deviceRow.connected || !deviceRow.loading ? theme.fontSizeSmall : theme.fontSize
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
            font.pixelSize: theme.fontSizeSmall

            MouseArea {
                anchors.fill: parent
                anchors.margins: -theme.gap * 0.7
                cursorShape: Qt.ArrowCursor
                hoverEnabled: true
                onClicked: deviceRow.deviceSource.forgetDevice(deviceRow.device)
            }
        }

        MouseArea {
            id: deviceHover

            anchors.fill: parent
            anchors.rightMargin: deviceRow.paired ? theme.popupElementSize : 0
            cursorShape: Qt.ArrowCursor
            hoverEnabled: !deviceRow.loading
            enabled: !deviceRow.loading
            onClicked: deviceRow.paired ? deviceRow.deviceSource.toggleDevice(deviceRow.device) : deviceRow.requestPair(deviceRow.device)
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

}
