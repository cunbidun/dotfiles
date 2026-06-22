import QtQuick
import Quickshell.Bluetooth

Column {
    id: root

    required property var theme
    required property var bluetoothSource
    property var goBack: () => {}
    readonly property var adapter: root.bluetoothSource.adapter
    readonly property bool enabled: root.bluetoothSource.enabled
    readonly property bool discovering: root.bluetoothSource.discovering
    readonly property var connectedDevices: root.bluetoothSource.connectedDevices
    readonly property var pairedDevices: root.bluetoothSource.pairedDevices
    readonly property var availableDevices: root.bluetoothSource.availableDevices
    readonly property string status: root.bluetoothSource.status
    property var pairingDevice: null
    property var pairingPrompt: null
    property string pairingSecret: ""

    spacing: theme.gap

    Connections {
        target: root.bluetoothSource

        function onPairingPrompt(prompt) {
            root.pairingPrompt = prompt;
            root.pairingSecret = "";
        }

        function onPairingCancelled() {
            root.cancelPairing();
        }
    }

    SettingsHeader {
        theme: root.theme
        width: parent.width
        title: "Bluetooth"
        subtitle: root.enabled ? "Nearby devices update automatically." : "Turn on Bluetooth to connect devices."
        checked: root.enabled
        toggle: () => root.bluetoothSource.setEnabled(!root.enabled)
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
                        text: root.adapter ? root.bluetoothSource.adapterDisplayName : "No Adapter"
                        color: root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamilyEmphasis
                        font.pixelSize: root.theme.fontSize
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
                text: root.pairingPrompt ? root.promptTitle() : `Pair ${root.bluetoothSource.displayName(root.pairingDevice)}`
                color: root.theme.popupText
                elide: Text.ElideRight
                font.family: root.theme.fontFamilyEmphasis
                font.pixelSize: root.theme.fontSize
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
        root.bluetoothSource.pairDevice(root.pairingDevice);
        root.cancelPairing();
    }

    function cancelPairing() {
        if (root.pairingPrompt) {
            root.bluetoothSource.cancelPairingPrompt(root.pairingPrompt);
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
        root.bluetoothSource.submitPairingPrompt(root.pairingPrompt.token, true, secrets);
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
        return root.bluetoothSource.displayName(device);
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
            model: deviceSection.devices.length

            DeviceRow {
                required property int index

                theme: deviceSection.theme
                width: deviceSection.width
                device: deviceSection.devices[index]
                deviceSource: root.bluetoothSource
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
        readonly property bool loading: !!device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
        property bool menuOpen: false
        readonly property bool showMenu: deviceRow.connected || deviceRow.paired

        z: deviceRow.menuOpen ? 30 : 0
        height: theme.listRowHeight
        radius: theme.popupSectionRadius
        color: deviceHover.containsMouse || menuButtonHover.containsMouse || deviceRow.menuOpen ? theme.popupHoverBackground : theme.popupSectionBackground
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
            anchors.right: trailingIcons.left
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: deviceRow.deviceTitle()
                color: deviceRow.connected ? theme.popupAccent : theme.popupText
                elide: Text.ElideRight
                font.family: deviceRow.connected ? theme.fontFamilyEmphasis : theme.fontFamily
                font.pixelSize: theme.fontSize
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

        Row {
            id: trailingIcons

            anchors.right: parent.right
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap * 0.7

            Spinner {
                visible: deviceRow.loading
                theme: deviceRow.theme
                size: theme.fontSize
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: menuButton

                visible: deviceRow.showMenu
                width: Math.round(theme.em * 1.25)
                height: width
                radius: width / 2
                color: menuButtonHover.containsMouse || deviceRow.menuOpen ? theme.chipHoverBackground : theme.transparentColor
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "ⓘ"
                    color: menuButtonHover.containsMouse || deviceRow.menuOpen ? theme.popupText : theme.iconMutedColor
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeMedium
                }

                MouseArea {
                    id: menuButtonHover

                    anchors.fill: parent
                    anchors.margins: -theme.gap * 0.45
                    cursorShape: Qt.ArrowCursor
                    hoverEnabled: true
                    enabled: !deviceRow.loading
                    onClicked: mouse => {
                        mouse.accepted = true;
                        deviceRow.menuOpen = !deviceRow.menuOpen;
                    }
                }
            }
        }

        MouseArea {
            id: deviceHover

            anchors.fill: parent
            anchors.rightMargin: deviceRow.showMenu ? theme.popupElementSize : 0
            cursorShape: Qt.ArrowCursor
            hoverEnabled: !deviceRow.loading
            enabled: !deviceRow.loading
            onClicked: {
                deviceRow.menuOpen = false;
                if (deviceRow.connected) {
                    return;
                }
                if (deviceRow.paired) {
                    deviceRow.deviceSource.connectDevice(deviceRow.device);
                } else {
                    deviceRow.requestPair(deviceRow.device);
                }
            }
        }

        Rectangle {
            id: actionMenu

            visible: deviceRow.menuOpen
            z: 20
            width: theme.popupElementSize * 3.4
            height: actionColumn.implicitHeight + theme.gap * 0.8
            radius: theme.popupSectionRadius
            color: theme.popupElevatedBackground
            border.width: theme.popupBorderWidth
            border.color: theme.popupBorder
            anchors.right: parent.right
            anchors.top: parent.bottom
            anchors.topMargin: theme.gap * 0.35

            Column {
                id: actionColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.gap * 0.4
                spacing: 0

                ActionMenuRow {
                    theme: deviceRow.theme
                    width: parent.width
                    visible: deviceRow.connected
                    text: "Disconnect"
                    activate: () => {
                        deviceRow.menuOpen = false;
                        deviceRow.deviceSource.disconnectDevice(deviceRow.device);
                    }
                }

                ActionMenuRow {
                    theme: deviceRow.theme
                    width: parent.width
                    visible: deviceRow.paired
                    text: "Forget"
                    destructive: true
                    activate: () => {
                        deviceRow.menuOpen = false;
                        deviceRow.deviceSource.forgetDevice(deviceRow.device);
                    }
                }
            }
        }

        function statusText() {
            if (deviceRow.loading) return "Working";
            if (deviceRow.connected && deviceRow.device.batteryAvailable) return `Connected • ${Math.round(deviceRow.device.battery * 100)}%`;
            if (deviceRow.connected) return "Connected";
            if (deviceRow.paired) return "Paired";
            if (deviceRow.device.signalStrength > 0) return `Available • ${deviceRow.device.signalStrength}%`;
            return "Available";
        }

        function deviceTitle() {
            const direct = String(deviceRow.device?.displayName || deviceRow.device?.name || deviceRow.device?.deviceName || "").trim();
            return direct.length > 0 ? direct : deviceRow.deviceSource.displayName(deviceRow.device);
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

    component ActionMenuRow: Rectangle {
        id: actionRow

        required property var theme
        property string text: ""
        property bool destructive: false
        property var activate: () => {}

        height: visible ? theme.compactRowHeight * 0.82 : 0
        radius: theme.popupSectionRadius * 0.7
        color: actionHover.containsMouse ? theme.popupHoverBackground : theme.transparentColor

        Text {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap * 0.7
            anchors.verticalCenter: parent.verticalCenter
            text: actionRow.text
            color: actionRow.destructive ? theme.popupDanger : theme.popupText
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
        }

        MouseArea {
            id: actionHover

            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            hoverEnabled: true
            onClicked: actionRow.activate()
        }
    }

}
