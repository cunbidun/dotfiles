import QtQuick
import Quickshell.Networking

// Pure Quickshell.Networking (NetworkManager over D-Bus). No external backend:
// scanning, connect, connectWithPsk, disconnect and forget are all native.
QtObject {
    id: root

    property string status: ""
    property var pendingNetwork: null
    property string pendingSsid: ""
    property int refreshTick: 0

    readonly property var devices: Networking.devices?.values ?? []
    readonly property var wifiDevice: devices.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property string wifiDeviceName: wifiDevice?.name ?? ""
    readonly property bool wifiEnabled: Networking.wifiEnabled

    // Bind to the live scan results + pendingSsid so the list re-evaluates
    // whenever NetworkManager finds/loses access points or a connect starts.
    readonly property var networks: {
        root.pendingSsid;
        root.refreshTick;
        return root.buildNetworks(root.wifiDevice?.networks?.values ?? []);
    }

    // Keep scanning while Wi-Fi is on and force the list to re-read periodically.
    property var rescanTimer: Timer {
        interval: 2000
        running: root.wifiEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.wifiDevice) {
                root.wifiDevice.scannerEnabled = true;
            }
            root.refreshTick += 1;
        }
    }
    readonly property var activeNetwork: root.networks.find(network => network.active) ?? ({})
    readonly property var knownNetworks: root.networks.filter(network => network.saved && !network.active)
    readonly property var otherNetworks: root.networks.filter(network => !network.saved && !network.active)
    readonly property string connectingSsid: root.pendingSsid

    // Surfaces native connect failures (e.g. wrong password) as status text.
    property var pendingConnections: Connections {
        target: root.pendingNetwork
        enabled: root.pendingNetwork !== null

        function onConnectionFailed(reason) {
            root.status = reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout
                ? `Wrong password for ${root.pendingSsid}`
                : `Failed to connect to ${root.pendingSsid}`;
            root.clearPending();
        }

        function onConnectedChanged() {
            if (root.pendingNetwork?.connected) {
                root.status = `Connected to ${root.pendingSsid}`;
                root.clearPending();
            }
        }
    }

    function buildNetworks(list) {
        const bySsid = new Map();
        for (const wifi of list ?? []) {
            const ssid = String(wifi.name || "").trim();
            if (ssid.length === 0) {
                continue;
            }
            const entry = {
                stableId: ssid,
                ssid,
                signal: Math.round((wifi.signalStrength || 0) * 100),
                security: root.securityLabel(wifi.security),
                secure: wifi.security !== WifiSecurityType.Open,
                enterprise: root.isEnterprise(wifi.security),
                saved: !!wifi.known,
                active: !!wifi.connected,
                connecting: wifi.state === ConnectionState.Connecting || (root.pendingSsid === ssid && !wifi.connected),
                outOfRange: false,
                network: wifi
            };
            const current = bySsid.get(ssid);
            if (!current || root.prefer(entry, current) > 0) {
                bySsid.set(ssid, entry);
            }
        }

        return [...bySsid.values()].sort((a, b) => Number(b.active) - Number(a.active)
            || Number(b.saved) - Number(a.saved)
            || Number(b.signal) - Number(a.signal)
            || a.ssid.localeCompare(b.ssid));
    }

    function prefer(next, current) {
        return Number(next.active) - Number(current.active)
            || Number(next.saved) - Number(current.saved)
            || next.signal - current.signal;
    }

    function connectNetwork(network, password) {
        const handle = network?.network ?? null;
        if (!handle) {
            root.status = "Network not found";
            return;
        }
        if (network.enterprise) {
            root.status = "Enterprise Wi-Fi is not supported here yet";
            return;
        }
        if (network.secure && !network.saved && (!password || password.length === 0)) {
            root.status = `Password required for ${network.ssid}`;
            return;
        }
        root.status = `Connecting to ${network.ssid}`;
        root.pendingNetwork = handle;
        root.pendingSsid = network.ssid;
        if (password && password.length > 0) {
            handle.connectWithPsk(password);
        } else {
            handle.connect();
        }
    }

    function connectSsid(ssid) {
        root.connectNetwork(root.networks.find(network => network.ssid === ssid), "");
    }

    function forgetNetwork(network) {
        network?.network?.forget();
        root.status = `Forgot ${network?.ssid ?? "network"}`;
    }

    function disconnectWifi() {
        const active = root.activeNetwork?.network ?? null;
        if (active) {
            active.disconnect();
        }
        root.clearPending();
        root.status = "Wi-Fi disconnected";
    }

    function setWifiEnabled(enabled) {
        Networking.wifiEnabled = enabled;
        root.status = enabled ? "Wi-Fi enabled" : "Wi-Fi disabled";
    }

    function refresh(rescan) {
        root.status = "";
        if (root.wifiDevice) {
            root.wifiDevice.scannerEnabled = true;
        }
    }

    function clearPending() {
        root.pendingNetwork = null;
        root.pendingSsid = "";
    }

    function securityLabel(security) {
        if (security === WifiSecurityType.Open) {
            return "Open";
        }
        return WifiSecurityType.toString(security);
    }

    function isEnterprise(security) {
        const label = String(WifiSecurityType.toString(security)).toLowerCase();
        return label.includes("enterprise") || label.includes("802");
    }

    Component.onCompleted: root.refresh(false)
}
