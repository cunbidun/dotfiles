import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Item {
    id: root

    width: 0
    height: 0
    visible: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var rawDevices: adapter?.devices?.values ?? []
    readonly property var devices: root.sortedDevices()
    readonly property var connectedDevices: root.devices.filter(device => device.connected)
    readonly property var pairedDevices: root.devices.filter(device => !device.connected && root.isPaired(device))
    readonly property var availableDevices: root.devices.filter(device => !device.connected && !root.isPaired(device) && !device.pairing && !device.blocked)
    property string status: ""
    property bool backendAvailable: false
    property bool backendWanted: false
    property int requestId: 0
    readonly property string adapterDisplayName: root.goodName(adapter?.name) ? adapter.name : "Bluetooth"
    readonly property string backendSocketPath: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/quickshell-cunbidun/bluez-agent.sock`

    signal pairingPrompt(var prompt)
    signal pairingCancelled()

    Component.onCompleted: {
        syncDiscovery();
        root.connectBackend();
    }
    onEnabledChanged: syncDiscovery()
    onAdapterChanged: syncDiscovery()

    function setEnabled(nextEnabled) {
        if (root.adapter) {
            root.adapter.enabled = nextEnabled;
            root.status = nextEnabled ? "Bluetooth enabled" : "Bluetooth disabled";
        }
        root.syncDiscovery();
    }

    function connectDevice(device) {
        if (!device) {
            root.status = "Bluetooth device not found";
            return;
        }
        root.status = `Connecting to ${root.displayName(device)}`;
        if (device.trusted !== undefined) {
            device.trusted = true;
        }
        if (device.connect) {
            device.connect();
        }
    }

    function disconnectDevice(device) {
        if (!device) {
            return;
        }
        root.status = `Disconnecting ${root.displayName(device)}`;
        if (device.disconnect) {
            device.disconnect();
        } else {
            root.status = "Bluetooth disconnect is not available for this device";
        }
    }

    function toggleDevice(device) {
        if (!device) {
            return;
        }
        if (device.connected) {
            root.disconnectDevice(device);
        } else {
            root.connectDevice(device);
        }
    }

    function pairDevice(device) {
        if (!device) {
            root.status = "Bluetooth device not found";
            return;
        }
        root.status = `Pairing ${root.displayName(device)}`;
        const path = root.devicePath(device);
        if (root.backendAvailable && path.length > 0) {
            root.sendRequest("bluetooth.pair", { devicePath: path });
            return;
        }
        root.status = "Bluetooth pairing service unavailable";
    }

    function forgetDevice(device) {
        if (!device) {
            return;
        }
        root.status = `Forgetting ${root.displayName(device)}`;
        const path = root.devicePath(device);
        if (root.backendAvailable && path.length > 0) {
            root.sendRequest("bluetooth.remove", { devicePath: path });
        } else if (device.forget) {
            device.forget();
        }
    }

    function submitPairingPrompt(token, accepted, secrets) {
        root.sendRequest("bluetooth.prompt.response", {
            token,
            accepted,
            secrets: secrets || {}
        });
    }

    function cancelPairingPrompt(prompt) {
        if (prompt?.token) {
            root.submitPairingPrompt(prompt.token, false, {});
        }
        if (prompt?.devicePath) {
            root.sendRequest("bluetooth.cancelPairing", { devicePath: prompt.devicePath });
        }
    }

    function syncDiscovery() {
        if (root.adapter) {
            root.adapter.discovering = root.enabled;
        }
    }

    function sortedDevices() {
        const byAddress = new Map();
        for (const device of root.rawDevices) {
            const key = root.deviceStableId(device);
            const current = byAddress.get(key);
            if (!current || root.preferDevice(device, current) > 0) {
                byAddress.set(key, device);
            }
        }

        return [...byAddress.values()].sort((a, b) => {
            const stateSort = Number(b.connected) - Number(a.connected) || Number(root.isPaired(b)) - Number(root.isPaired(a));
            if (stateSort !== 0) {
                return stateSort;
            }

            const aId = root.displayName(a);
            const bId = root.displayName(b);
            return aId.localeCompare(bId);
        });
    }

    function preferDevice(next, current) {
        return Number(next.connected) - Number(current.connected)
            || Number(root.isPaired(next)) - Number(root.isPaired(current))
            || Number(root.hasGoodName(next)) - Number(root.hasGoodName(current));
    }

    function isPaired(device) {
        return !!(device?.paired || device?.bonded || device?.trusted);
    }

    function deviceId(device) {
        return root.deviceStableId(device);
    }

    function displayName(device) {
        if (root.goodName(device?.name)) return String(device.name);
        if (root.goodName(device?.deviceName)) return String(device.deviceName);
        const address = root.deviceAddress(device);
        if (address.length > 0) return address;
        return "Bluetooth device";
    }

    function deviceStableId(device) {
        const path = root.devicePath(device);
        if (path.length > 0) return path;
        const address = root.deviceAddress(device);
        if (address.length > 0) return address;
        return root.displayName(device);
    }

    function devicePath(device) {
        return String(device?.dbusPath || "").trim();
    }

    function deviceAddress(device) {
        return String(device?.address || "").toUpperCase();
    }

    function hasGoodName(device) {
        return root.goodName(root.displayName(device));
    }

    function goodName(name) {
        const text = String(name || "").trim();
        if (text.length === 0) return false;
        if (text === "DP-3") return false;
        if (text.toLowerCase() === "bluetooth device") return false;
        return true;
    }

    function sendRequest(method, params) {
        if (!requestSocket.connected) {
            root.backendAvailable = false;
            root.status = "Bluetooth pairing service unavailable";
            root.scheduleBackendReconnect();
            return;
        }
        const request = {
            id: ++root.requestId,
            method,
            params: params || {}
        };
        requestSocket.write(JSON.stringify(request) + "\n");
        requestSocket.flush();
    }

    function handleResponse(message) {
        if (message.capabilities && message.capabilities.indexOf("bluetooth") !== -1) {
            root.backendAvailable = true;
        }
        if (message.ok === false && message.error) {
            root.status = message.error;
        }
    }

    function handleEvent(message) {
        if (message.event === "bluetooth.pairing.request") {
            root.pairingPrompt(message);
        } else if (message.event === "bluetooth.pairing.cancel") {
            root.pairingCancelled();
        } else if (message.event === "bluetooth.pair.result") {
            root.status = message.ok ? "Bluetooth pairing complete" : `Bluetooth pairing failed: ${message.error || "Unknown error"}`;
        }
    }

    function connectBackend() {
        root.backendWanted = true;
        backendReconnectTimer.stop();
        requestSocket.connected = true;
        subscribeSocket.connected = true;
    }

    function scheduleBackendReconnect() {
        if (!root.backendWanted || backendReconnectTimer.running) {
            return;
        }
        backendReconnectTimer.restart();
    }

    Timer {
        id: backendReconnectTimer

        interval: 1000
        repeat: false
        onTriggered: {
            requestSocket.connected = false;
            subscribeSocket.connected = false;
            Qt.callLater(root.connectBackend);
        }
    }

    Socket {
        id: requestSocket

        path: root.backendSocketPath

        connected: false

        onConnectionStateChanged: {
            root.backendAvailable = connected;
            if (connected) {
                root.sendRequest("ping", {});
            } else {
                root.scheduleBackendReconnect();
            }
        }

        onError: root.scheduleBackendReconnect()

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0) return;
                try {
                    root.handleResponse(JSON.parse(line));
                } catch (error) {
                    root.status = "Bluetooth service response parse failed";
                }
            }
        }
    }

    Socket {
        id: subscribeSocket

        path: root.backendSocketPath
        connected: false

        onConnectionStateChanged: {
            if (connected) {
                subscribeSocket.write(JSON.stringify({ method: "subscribe" }) + "\n");
                subscribeSocket.flush();
            } else {
                root.scheduleBackendReconnect();
            }
        }

        onError: root.scheduleBackendReconnect()

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0) return;
                try {
                    const message = JSON.parse(line);
                    if (message.event) root.handleEvent(message);
                    else root.handleResponse(message);
                } catch (error) {
                    root.status = "Bluetooth service event parse failed";
                }
            }
        }
    }
}
