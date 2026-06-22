import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Devices, connect/disconnect/pair/forget and adapter state are all native
// (Quickshell.Bluetooth). The Unix socket is used ONLY to relay pairing prompts
// (passkey/confirm) to/from the external BlueZ agent, which exists because
// Quickshell 0.3 has no built-in agent mode.
QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property string adapterDisplayName: root.goodName(adapter?.name) ? adapter.name : "Bluetooth"

    readonly property var devices: root.sortedDevices()
    readonly property var connectedDevices: root.devices.filter(device => device.connected)
    readonly property var pairedDevices: root.devices.filter(device => !device.connected && root.isPaired(device))
    readonly property var availableDevices: root.devices.filter(device => !device.connected && !root.isPaired(device) && !device.pairing && !device.blocked && root.hasGoodName(device))

    property string status: ""
    readonly property string backendSocketPath: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/quickshell-cunbidun/bluez-agent.sock`

    signal pairingPrompt(var prompt)
    signal pairingCancelled()

    Component.onCompleted: root.syncDiscovery()
    onEnabledChanged: root.syncDiscovery()
    onAdapterChanged: root.syncDiscovery()

    function setEnabled(value) {
        if (root.adapter) {
            root.adapter.enabled = value;
            root.status = value ? "Bluetooth enabled" : "Bluetooth disabled";
        }
        root.syncDiscovery();
    }

    function connectDevice(device) {
        if (!device?.connect) {
            root.status = "Bluetooth device unavailable";
            return;
        }
        root.status = `Connecting to ${root.displayName(device)}`;
        if (device.trusted !== undefined) {
            device.trusted = true;
        }
        device.connect();
    }

    function disconnectDevice(device) {
        if (device?.disconnect) {
            root.status = `Disconnecting ${root.displayName(device)}`;
            device.disconnect();
        }
    }

    function toggleDevice(device) {
        if (!device) {
            return;
        }
        if (device.connected) {
            root.disconnectDevice(device);
        } else if (root.isPaired(device)) {
            root.connectDevice(device);
        } else {
            root.pairDevice(device);
        }
    }

    function pairDevice(device) {
        if (!device?.pair) {
            root.status = "Bluetooth device unavailable";
            return;
        }
        root.status = `Pairing ${root.displayName(device)}`;
        if (device.trusted !== undefined) {
            device.trusted = true;
        }
        device.pair();
    }

    function forgetDevice(device) {
        if (device?.forget) {
            root.status = `Forgetting ${root.displayName(device)}`;
            device.forget();
        }
    }

    function submitPairingPrompt(token, accepted, secrets) {
        promptSocket.write(JSON.stringify({
            method: "bluetooth.prompt.response",
            params: { token, accepted, secrets: secrets || {} }
        }) + "\n");
        promptSocket.flush();
    }

    function cancelPairingPrompt(prompt) {
        if (prompt?.token) {
            root.submitPairingPrompt(prompt.token, false, {});
        }
        if (prompt?.devicePath) {
            const device = root.devices.find(item => String(item.dbusPath || "") === String(prompt.devicePath));
            if (device?.cancelPair) {
                device.cancelPair();
            }
        }
    }

    function syncDiscovery() {
        if (root.adapter) {
            root.adapter.discovering = root.enabled;
        }
    }

    function sortedDevices() {
        const byId = new Map();
        for (const device of Bluetooth.devices?.values ?? []) {
            const key = String(device.address || device.dbusPath || root.displayName(device));
            if (!byId.has(key)) {
                byId.set(key, device);
            }
        }
        return [...byId.values()].sort((a, b) => Number(b.connected) - Number(a.connected)
            || Number(root.isPaired(b)) - Number(root.isPaired(a))
            || Number(root.hasGoodName(b)) - Number(root.hasGoodName(a))
            || root.displayName(a).localeCompare(root.displayName(b)));
    }

    function isPaired(device) {
        return !!(device?.paired || device?.bonded || device?.trusted);
    }

    // A device has a real name only if it advertises one that isn't just its
    // MAC address (BlueZ reports the address as the name for anonymous devices).
    function hasGoodName(device) {
        const name = String(device?.name || device?.deviceName || "").trim();
        if (name.length === 0) {
            return false;
        }
        const address = String(device?.address || "").replace(/[:\-\s]/g, "").toLowerCase();
        return address.length === 0 || name.replace(/[:\-\s]/g, "").toLowerCase() !== address;
    }

    function goodName(value) {
        return String(value || "").trim().length > 0;
    }

    function displayName(device) {
        if (root.goodName(device?.name)) return String(device.name);
        if (root.goodName(device?.deviceName)) return String(device.deviceName);
        return String(device?.address || "Bluetooth device");
    }

    property var promptSocket: Socket {
        id: promptSocket

        path: root.backendSocketPath
        connected: true

        onConnectionStateChanged: {
            if (connected) {
                promptSocket.write(JSON.stringify({ method: "subscribe" }) + "\n");
                promptSocket.flush();
            } else {
                reconnectTimer.restart();
            }
        }
        onError: reconnectTimer.restart()

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0) {
                    return;
                }
                try {
                    const message = JSON.parse(line);
                    if (message.event === "bluetooth.pairing.request") {
                        root.pairingPrompt(message);
                    } else if (message.event === "bluetooth.pairing.cancel") {
                        root.pairingCancelled();
                    }
                } catch (error) {
                    // ignore malformed lines
                }
            }
        }
    }

    property var reconnectTimer: Timer {
        id: reconnectTimer

        interval: 1000
        repeat: false
        onTriggered: {
            promptSocket.connected = false;
            Qt.callLater(() => promptSocket.connected = true);
        }
    }
}
