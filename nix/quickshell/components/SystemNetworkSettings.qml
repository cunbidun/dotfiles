import QtQuick
import Quickshell.Io

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    property bool wifiEnabled: false
    property bool refreshing: false
    property string status: ""
    property var activeNetwork: ({})
    property var connectionInfo: ({})
    property var savedNetworks: []
    property var nearbyNetworks: []
    readonly property var knownNearbyNetworks: root.savedNetworks.map(saved => {
        const nearby = root.nearbyNetworks.find(wifi => wifi.ssid === saved.ssid) || {};
        return Object.assign({}, saved, nearby, { ssid: saved.ssid, uuid: saved.uuid, saved: true });
    })
    readonly property var otherNetworks: root.nearbyNetworks.filter(wifi => !root.savedNetworks.some(saved => saved.ssid === wifi.ssid))

    spacing: theme.gap

    Component.onCompleted: refresh()

    Process {
        id: detailQuery

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseDetails(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.status = text.trim()
        }
        onExited: () => root.refreshing = false
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
        onExited: () => root.refresh()
    }

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
                text: "Wi-Fi"
                activate: root.goBack
            }

            Column {
                width: parent.width - backButtonWidth() - refreshButton.width - powerSwitch.width - root.theme.gap * 3
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Set up Wi-Fi to wirelessly connect to the internet."
                    color: root.theme.popupText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.86
                }

                Text {
                    width: parent.width
                    text: root.wifiEnabled ? "Choose a network to join." : "Turn on Wi-Fi, then choose a network to join."
                    color: root.theme.popupMutedText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.76
                }
            }

            IconButton {
                id: refreshButton

                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                icon: root.refreshing ? "󰑓" : "󰑐"
                activate: () => root.refresh(true)
            }

            SettingsSwitch {
                id: powerSwitch

                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                checked: root.wifiEnabled
                activate: () => root.setWifiEnabled(!root.wifiEnabled)
            }
        }
    }

    Rectangle {
        width: parent.width
        height: detailsColumn.implicitHeight + root.theme.gap * 2
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground
        border.width: root.theme.popupBorderWidth
        border.color: root.theme.popupBorder

        Column {
            id: detailsColumn

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
                    text: root.wifiEnabled ? root.networkIcon(root.activeNetwork.signal || 0) : "󰤭"
                    color: root.activeNetwork.ssid ? root.theme.popupAccent : root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 1.25
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - root.theme.popupElementSize
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.activeNetwork.ssid || root.connectionInfo.connection || (root.wifiEnabled ? "Not Connected" : "Wi-Fi Off")
                        color: root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.connectionInfo.device ? `${root.connectionInfo.device}${root.activeNetwork.signal ? ` • ${root.activeNetwork.signal}%` : ""}` : "No active wireless device"
                        color: root.theme.popupMutedText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 0.78
                    }
                }
            }

            InfoRow { theme: root.theme; label: "Connection"; value: root.connectionInfo.connection || "--" }
            InfoRow { theme: root.theme; label: "Address"; value: root.connectionInfo.address || "--" }
            InfoRow { theme: root.theme; label: "Gateway"; value: root.connectionInfo.gateway || "--" }
            InfoRow { theme: root.theme; label: "Security"; value: root.activeNetwork.security || "--" }
        }
    }

    SectionLabel {
        theme: root.theme
        width: parent.width
        text: root.activeNetwork.ssid || root.connectionInfo.connection ? "Connected" : "Status"
    }

    NetworkRow {
        theme: root.theme
        width: parent.width
        visible: !!(root.activeNetwork.ssid || root.connectionInfo.connection)
        wifiNetwork: ({ ssid: root.activeNetwork.ssid || root.connectionInfo.connection, signal: root.activeNetwork.signal || 0, secure: (root.activeNetwork.security || "").length > 0, active: true, saved: true, uuid: "" })
        activate: root.disconnectWifi
        forget: () => {}
        showForget: false
    }

    SectionLabel {
        theme: root.theme
        width: parent.width
        text: "Known Networks"
    }

    Column {
        width: parent.width
        spacing: root.theme.gap * 0.2

        Repeater {
            model: root.knownNearbyNetworks.slice(0, 8)

            NetworkRow {
                theme: root.theme
                width: parent.width
                wifiNetwork: modelData
                activate: () => modelData.active ? root.disconnectWifi() : root.connectConnection(modelData.uuid)
                forget: () => root.forgetConnection(modelData.uuid)
                showForget: true
            }
        }

        EmptyText {
            theme: root.theme
            width: parent.width
            visible: root.knownNearbyNetworks.length === 0
            text: "No known Wi-Fi networks"
        }
    }

    SectionLabel {
        theme: root.theme
        width: parent.width
        text: "Other Networks"
    }

    Column {
        width: parent.width
        spacing: root.theme.gap * 0.2

        Repeater {
            model: root.otherNetworks.slice(0, 12)

            NetworkRow {
                theme: root.theme
                width: parent.width
                wifiNetwork: modelData
                activate: () => root.connectWifi(modelData.ssid)
                forget: () => {}
                showForget: false
            }
        }

        EmptyText {
            theme: root.theme
            width: parent.width
            visible: root.otherNetworks.length === 0
            text: root.wifiEnabled ? "No other networks found" : "Wi-Fi disabled"
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

    function refresh(rescan) {
        root.refreshing = true;
        detailQuery.command = ["bash", "-lc", `printf 'enabled=%s\\n' "$(nmcli -t -f WIFI general 2>/dev/null | tail -1)"; device=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2=="wifi" && $3=="connected" {print $1; exit}'); printf 'device=%s\\n' "$device"; nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY device wifi list --rescan ${rescan ? "yes" : "no"} 2>/dev/null | sed 's/^/wifi=/'; if [ -n "$device" ]; then nmcli -t -f GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY device show "$device" 2>/dev/null | awk -F: '$1=="GENERAL.CONNECTION" {printf "connection=%s\\n", $2} $1=="IP4.ADDRESS[1]" {printf "address=%s\\n", $2} $1=="IP4.GATEWAY" {printf "gateway=%s\\n", $2}'; fi; nmcli -t -f NAME,UUID,TYPE,AUTOCONNECT,ACTIVE connection show 2>/dev/null | awk -F: '$3=="802-11-wireless" {printf "saved=%s|%s|%s|%s\\n", $1, $2, $4, $5}'`];
        detailQuery.running = true;
    }

    function parseDetails(rawText) {
        const info = {};
        const saved = [];
        const nearby = [];
        root.activeNetwork = ({});
        root.wifiEnabled = false;
        for (const line of rawText.trim().split("\n")) {
            if (line.startsWith("enabled=")) {
                root.wifiEnabled = line.slice(8).trim() === "enabled";
            } else if (line.startsWith("device=")) {
                info.device = line.slice(7).trim();
            } else if (line.startsWith("connection=")) {
                info.connection = line.slice(11).trim();
            } else if (line.startsWith("address=")) {
                info.address = line.slice(8).trim();
            } else if (line.startsWith("gateway=")) {
                info.gateway = line.slice(8).trim();
            } else if (line.startsWith("wifi=")) {
                const parts = root.splitNmcli(line.slice(5));
                const ssid = parts[1] || "Hidden Network";
                if (ssid.length > 0) {
                    const network = { active: parts[0] === "yes", ssid, signal: Number(parts[2] || 0), security: parts[3] || "", secure: (parts[3] || "").trim().length > 0 };
                    const existing = nearby.find(wifi => wifi.ssid === ssid);
                    if (!existing || network.signal > existing.signal || network.active) {
                        if (existing) nearby.splice(nearby.indexOf(existing), 1);
                        nearby.push(network);
                    }
                    if (network.active) root.activeNetwork = network;
                }
            } else if (line.startsWith("saved=")) {
                const parts = line.slice(6).split("|");
                if ((parts[0] || "").length > 0 && (parts[1] || "").length > 0) {
                    saved.push({ ssid: parts[0], uuid: parts[1], autoconnect: parts[2] === "yes", active: parts[3] === "yes", saved: true });
                }
            }
        }
        root.connectionInfo = info;
        root.nearbyNetworks = nearby.sort((a, b) => Number(b.active) - Number(a.active) || b.signal - a.signal || a.ssid.localeCompare(b.ssid));
        root.savedNetworks = saved.sort((a, b) => Number(b.active || root.connectionInfo.connection === b.ssid) - Number(a.active || root.connectionInfo.connection === a.ssid) || a.ssid.localeCompare(b.ssid));
    }

    function run(command) {
        networkAction.command = ["bash", "-lc", command];
        networkAction.running = true;
    }

    function setWifiEnabled(enabled) {
        root.run(`nmcli radio wifi ${enabled ? "on" : "off"}`);
    }

    function connectConnection(uuid) {
        root.status = "Connecting";
        root.run(`nmcli connection up uuid ${root.shellQuote(uuid)}`);
    }

    function connectWifi(ssid) {
        root.status = `Connecting to ${ssid}`;
        root.run(`nmcli device wifi connect ${root.shellQuote(ssid)}`);
    }

    function forgetConnection(uuid) {
        root.run(`nmcli connection delete uuid ${root.shellQuote(uuid)}`);
    }

    function disconnectWifi() {
        root.run("device=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"wifi\" && $3==\"connected\"{print $1; exit}'); [ -n \"$device\" ] && nmcli device disconnect \"$device\"");
    }

    function shellQuote(value) {
        return `'${String(value).replace(/'/g, `'\\''`)}'`;
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

    function backButtonWidth() {
        return root.theme.popupElementSize * 2.9;
    }

    function networkIcon(signal) {
        if (signal >= 75) return "󰤨";
        if (signal >= 50) return "󰤥";
        if (signal >= 25) return "󰤢";
        return "󰤟";
    }

    component InfoRow: Item {
        required property var theme
        property string label: ""
        property string value: ""

        width: parent.width
        height: theme.statRowHeight

        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: label; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.86; font.bold: true }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: value; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.86; elide: Text.ElideRight; width: parent.width * 0.58; horizontalAlignment: Text.AlignRight }
    }

    component SectionLabel: Text {
        required property var theme
        color: theme.popupText
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize * 0.9
        font.bold: true
    }

    component EmptyText: Item {
        required property var theme
        property string text: ""

        height: visible ? theme.popupElementSize * 1.25 : 0

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: theme.popupMutedText
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize * 0.86
        }
    }

    component NetworkRow: Rectangle {
        id: networkRow

        required property var theme
        property var wifiNetwork: ({})
        property bool showForget: false
        property var activate: () => {}
        property var forget: () => {}

        height: theme.popupElementSize * 1.35
        radius: theme.popupSectionRadius * 0.55
        color: !!wifiNetwork.active ? theme.popupSelectedBackground : rowHover.containsMouse ? theme.popupHoverBackground : theme.popupSectionBackground
        border.width: !!wifiNetwork.active ? theme.popupBorderWidth : 0
        border.color: theme.popupBorder

        Text {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            text: wifiNetwork.active ? "✓" : wifiNetwork.saved ? "󰤢" : ""
            color: !!wifiNetwork.active ? theme.selectedForeground : theme.iconMutedColor
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: theme.popupElementSize
            anchors.right: detailIcon.left
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: wifiNetwork.ssid || "Hidden Network"
                color: !!wifiNetwork.active ? theme.selectedForeground : theme.popupText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize
                font.bold: !!wifiNetwork.active
            }

            Text {
                width: parent.width
                visible: !!(wifiNetwork.active || wifiNetwork.saved || wifiNetwork.security)
                text: wifiNetwork.active ? "Connected" : wifiNetwork.saved ? "Known Network" : wifiNetwork.security || ""
                color: !!wifiNetwork.active ? theme.selectedForeground : theme.popupMutedText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize * 0.75
            }
        }

        Row {
            id: detailIcon

            anchors.right: parent.right
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap * 0.7

            Text { visible: !!wifiNetwork.secure; text: "󰌾"; color: !!wifiNetwork.active ? theme.selectedForeground : theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.85; anchors.verticalCenter: parent.verticalCenter }
            Text { text: networkIcon(wifiNetwork.signal || 0); color: !!wifiNetwork.active ? theme.selectedForeground : theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: !!networkRow.showForget; text: "󰍉"; color: theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton && networkRow.showForget) {
                    networkRow.forget();
                } else {
                    networkRow.activate();
                }
            }
        }

        function networkIcon(signal) {
            if (signal >= 75) return "󰤨";
            if (signal >= 50) return "󰤥";
            if (signal >= 25) return "󰤢";
            return "󰤟";
        }
    }
}
