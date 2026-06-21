import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    property var openSettings: () => {}
    property bool wifiEnabled: false
    property bool scanning: false
    property string status: ""
    property var networks: []

    spacing: theme.gap

    Component.onCompleted: refresh(false)

    Process {
        id: networkQuery

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseNetworks(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.status = text.trim()
        }
        onExited: () => root.scanning = false
    }

    Process {
        id: networkAction

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.status = text.trim()
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.status = text.trim()
        }
        onExited: () => root.refresh(false)
    }

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
            text: "Network"
            activate: root.goBack
        }

        ToggleButton {
            theme: root.theme
            anchors.right: scanButton.left
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            checked: root.wifiEnabled
            text: root.wifiEnabled ? "On" : "Off"
            activate: () => root.setWifiEnabled(!root.wifiEnabled)
        }

        IconButton {
            id: scanButton

            theme: root.theme
            anchors.right: parent.right
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            icon: root.scanning ? "󰑓" : "󰑐"
            activate: () => root.refresh(true)
        }
    }

    Text {
        width: parent.width
        text: root.wifiEnabled ? `${root.networks.length} networks available` : "Wi-Fi disabled"
        color: root.theme.popupMutedText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize * 0.86
    }

    Column {
        width: parent.width
        spacing: root.theme.gap

        Repeater {
            model: root.networks.slice(0, 8)

            Rectangle {
                id: networkRow

                required property var modelData
                readonly property bool active: modelData.active

                width: parent.width
                height: root.theme.popupElementSize * 1.25
                radius: root.theme.popupSectionRadius
                color: active ? root.theme.popupSelectedBackground : networkHover.containsMouse ? root.theme.popupHoverBackground : root.theme.popupSectionBackground

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.networkIcon(networkRow.modelData.signal)
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.iconColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.popupElementSize
                    anchors.right: actionIcon.left
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkRow.modelData.ssid
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.popupText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                    font.bold: networkRow.active
                }

                Text {
                    visible: networkRow.modelData.secure
                    anchors.right: actionIcon.left
                    anchors.rightMargin: root.theme.popupElementSize * 0.8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌾"
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.iconMutedColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.82
                }

                Text {
                    id: actionIcon

                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkRow.active ? "󰌙" : "󰌘"
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.iconColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                MouseArea {
                    id: networkHover

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: networkRow.active ? root.disconnectWifi() : root.connectWifi(networkRow.modelData.ssid)
                }
            }
        }

        Item {
            width: parent.width
            height: root.networks.length === 0 ? root.theme.popupElementSize * 2 : 0
            visible: root.networks.length === 0

            Text {
                anchors.centerIn: parent
                text: root.wifiEnabled ? "No networks found" : "Enable Wi-Fi to scan"
                color: root.theme.popupMutedText
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize
            }
        }
    }

    Text {
        width: parent.width
        visible: root.status.length > 0
        text: root.status
        color: root.theme.popupMutedText
        elide: Text.ElideRight
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize * 0.78
    }

    SettingsRow {
        theme: root.theme
        width: parent.width
        icon: "󰒓"
        text: "Wi-Fi Settings"
        activate: root.openSettings
    }

    function refresh(rescan) {
        root.scanning = true;
        networkQuery.command = ["bash", "-lc", `printf 'enabled=%s\\n' "$(nmcli -t -f WIFI general 2>/dev/null | tail -1)"; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan ${rescan ? "yes" : "no"} 2>/dev/null | head -20`];
        networkQuery.running = true;
    }

    function parseNetworks(rawText) {
        const next = [];
        const lines = rawText.trim().split("\n").filter(line => line.length > 0);
        root.wifiEnabled = false;
        for (const line of lines) {
            if (line.startsWith("enabled=")) {
                root.wifiEnabled = line.slice(8).trim() === "enabled";
                continue;
            }

            const parts = root.splitNmcli(line);
            const ssid = parts[1] || "Hidden network";
            if (ssid.length === 0) {
                continue;
            }

            const existing = next.find(network => network.ssid === ssid);
            const network = {
                active: (parts[0] || "").trim() === "*",
                ssid,
                signal: Number(parts[2] || 0),
                secure: (parts[3] || "").trim().length > 0
            };
            if (!existing || network.signal > existing.signal || network.active) {
                if (existing) {
                    next.splice(next.indexOf(existing), 1);
                }
                next.push(network);
            }
        }
        root.networks = next.sort((a, b) => Number(b.active) - Number(a.active) || b.signal - a.signal);
    }

    function splitNmcli(line) {
        const parts = [];
        let current = "";
        let escaped = false;
        for (const char of line) {
            if (escaped) {
                current += char;
                escaped = false;
            } else if (char === "\\") {
                escaped = true;
            } else if (char === ":") {
                parts.push(current);
                current = "";
            } else {
                current += char;
            }
        }
        parts.push(current);
        return parts;
    }

    function setWifiEnabled(enabled) {
        networkAction.command = ["bash", "-lc", `nmcli radio wifi ${enabled ? "on" : "off"}`];
        networkAction.running = true;
    }

    function connectWifi(ssid) {
        root.status = `Connecting to ${ssid}`;
        networkAction.command = ["bash", "-lc", `nmcli device wifi connect ${root.shellQuote(ssid)}`];
        networkAction.running = true;
    }

    function disconnectWifi() {
        networkAction.command = ["bash", "-lc", "device=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"wifi\" && $3==\"connected\"{print $1; exit}'); [ -n \"$device\" ] && nmcli device disconnect \"$device\""];
        networkAction.running = true;
    }

    function shellQuote(value) {
        return `'${String(value).replace(/'/g, `'\\''`)}'`;
    }

    function networkIcon(signal) {
        if (signal >= 75) return "󰤨";
        if (signal >= 50) return "󰤥";
        if (signal >= 25) return "󰤢";
        return "󰤟";
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

        Text { id: label; anchors.centerIn: parent; text: parent.text; color: parent.checked ? theme.selectedForeground : theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.82; font.bold: true }
        MouseArea { id: hover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: parent.activate() }
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
}
