import QtQuick
import Quickshell.Networking

Item {
    id: root

    width: 0
    height: 0
    visible: false

    property string status: ""
    readonly property var devices: Networking.devices?.values ?? []
    readonly property var wifiDevice: devices.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(device => device.type === DeviceType.Wired) ?? null
    readonly property string wifiDeviceName: wifiDevice?.name ?? ""
    readonly property string wifiDeviceState: wifiDevice?.connected ? "connected" : "disconnected"
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var networks: root.visibleNetworks()
    readonly property var activeNetwork: root.networks.find(wifi => wifi.active) ?? ({})
    readonly property var knownNetworks: root.networks.filter(wifi => wifi.saved && !wifi.active)
    readonly property var otherNetworks: root.networks.filter(wifi => !wifi.saved && !wifi.active)
    readonly property string address: ""
    readonly property string gateway: ""
    readonly property string dns: ""
    property var pendingNetwork: null
    property string pendingSsid: ""
    property bool pendingWithPsk: false

    Component.onCompleted: syncScanner()
    onWifiEnabledChanged: syncScanner()
    onWifiDeviceChanged: syncScanner()

    Connections {
        target: root.pendingNetwork
        enabled: root.pendingNetwork !== null

        function onConnectionFailed(reason) {
            const reasonText = ConnectionFailReason.toString(reason);
            const invalidPassword = root.pendingWithPsk && (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout);
            root.status = invalidPassword ? `Invalid password for ${root.pendingSsid}` : `Failed to connect to ${root.pendingSsid}: ${reasonText}`;
            root.clearPendingConnection();
        }

        function onConnectedChanged() {
            if (root.pendingNetwork?.connected) {
                root.status = `Connected to ${root.pendingSsid}`;
                root.clearPendingConnection();
            }
        }
    }

    function refresh(rescan) {
        root.status = "";
        root.syncScanner();
    }

    function setWifiEnabled(enabled) {
        Networking.wifiEnabled = enabled;
        root.status = enabled ? "Wi-Fi enabled" : "Wi-Fi disabled";
        root.syncScanner();
    }

    function syncScanner() {
        if (root.wifiDevice) {
            root.wifiDevice.scannerEnabled = root.wifiEnabled;
        }
    }

    function connectNetwork(network, password) {
        if (!network?.network) {
            root.status = "Network not found";
            return;
        }
        if (network.secure && !network.saved && (!password || password.length === 0)) {
            root.status = `Password required for ${network.ssid}`;
            return;
        }
        root.status = `Connecting to ${network.ssid}`;
        root.pendingNetwork = network.network;
        root.pendingSsid = network.ssid;
        if (password && password.length > 0 && root.supportsPsk(network.network.security) && network.network.connectWithPsk) {
            root.pendingWithPsk = true;
            network.network.connectWithPsk(password);
        } else {
            root.pendingWithPsk = false;
            network.network.connect();
        }
    }

    function connectSsid(ssid) {
        root.connectNetwork(root.networks.find(item => item.ssid === ssid), "");
    }

    function forgetNetwork(network) {
        if (network?.network) {
            network.network.forget();
            root.status = `Forgot ${network.ssid}`;
        }
    }

    function disconnectWifi() {
        root.wifiDevice?.disconnect();
        root.status = "Wi-Fi disconnected";
        root.clearPendingConnection();
    }

    function clearPendingConnection() {
        root.pendingNetwork = null;
        root.pendingSsid = "";
        root.pendingWithPsk = false;
    }

    function visibleNetworks() {
        const bySsid = new Map();
        const device = root.wifiDevice;
        if (!device) {
            return [];
        }

        for (const wifi of device.networks?.values ?? []) {
            const ssid = String(wifi.name || "").trim();
            if (ssid.length === 0) {
                continue;
            }

            const next = {
                stableId: ssid,
                active: !!wifi.connected,
                ssid,
                signal: Math.round((wifi.signalStrength || 0) * 100),
                security: root.securityLabel(wifi.security),
                secure: wifi.security !== WifiSecurityType.Open,
                saved: !!wifi.known,
                network: wifi
            };
            const current = bySsid.get(ssid);
            if (!current || root.preferNetwork(next, current) > 0) {
                bySsid.set(ssid, next);
            }
        }

        return [...bySsid.values()].sort((a, b) => Number(b.active) - Number(a.active) || a.ssid.localeCompare(b.ssid));
    }

    function preferNetwork(next, current) {
        return Number(next.active) - Number(current.active)
            || Number(next.saved) - Number(current.saved)
            || next.signal - current.signal;
    }

    function securityLabel(security) {
        if (security === WifiSecurityType.Open) {
            return "Open";
        }
        return WifiSecurityType.toString(security);
    }

    function supportsPsk(security) {
        return security === WifiSecurityType.WpaPsk || security === WifiSecurityType.Wpa2Psk || security === WifiSecurityType.Sae;
    }
}
