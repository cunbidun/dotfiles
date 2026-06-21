import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
    id: root

    required property var theme
    property var openSettings: tab => {}
    property var pulseLauncher: (context, percent) => {}

    property var stats: ({})
    property string activeView: "dashboard"
    property bool recording: false
    property bool inhibited: false
    property bool nightLight: false
    property bool audioSelectorOpen: false
    property bool wifiEnabled: false
    property string wifiSsid: ""
    property int volumePercent: 43
    property int brightnessPercent: 58
    property bool adjustingVolume: false
    property bool adjustingBrightness: false
    property var audioOutputs: []
    readonly property int cell: theme.dashboardControlCell
    readonly property int gap: theme.gap
    readonly property int tileWidth: cell * 2 + gap
    readonly property int mediaWidth: cell * 4 + gap * 3
    readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying) || Mpris.players.values[0] || null
    readonly property int connectedBluetoothDevices: Bluetooth.devices.values.filter(device => device.connected).length

    width: theme.dashboardPopupWidth
    height: activeContent.implicitHeight + theme.gap * 2
    implicitWidth: width
    implicitHeight: height
    radius: theme.popupSectionRadius
    color: theme.popupBackground
    border.width: theme.popupBorderWidth
    border.color: theme.popupBorder

    Process {
        id: statsQuery

        command: [
            "bash",
            "-lc",
            "read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; total1=$((user+nice+system+idle+iowait+irq+softirq+steal)); idle1=$((idle+iowait)); sleep 0.12; read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; total2=$((user+nice+system+idle+iowait+irq+softirq+steal)); idle2=$((idle+iowait)); awk -v t1=$total1 -v t2=$total2 -v i1=$idle1 -v i2=$idle2 'BEGIN { printf \"cpu=%d\\n\", (t2>t1 ? (100 * ((t2-t1)-(i2-i1)) / (t2-t1)) : 0) }'; awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END { printf \"ram=%d/%d GiB\\n\", (t-a)/1048576, t/1048576 }' /proc/meminfo; df -h --output=used,size / | tail -1 | awk '{ printf \"disk=%s/%s\\n\", $1, $2 }'; awk '{ printf \"load=%s %s %s\\n\", $1, $2, $3 }' /proc/loadavg; awk '{s=int($1); printf \"uptime=%dh %02dm\\n\", s/3600, (s%3600)/60}' /proc/uptime; awk -F'[: ]+' '/:/ && $2 !~ /^lo$/ {rx+=$3; tx+=$11} END {printf \"net=↓ %.0f K/s    ↑ %.0f K/s\\n\", rx/1024%1000, tx/1024%1000}' /proc/net/dev; temp=$(for f in /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] && awk '{ if ($1 > 1000 && $1 < 110000) { printf \"%d\\n\", $1/1000; exit } }' \"$f\"; done | head -1); printf \"cpu_temp=%sC\\n\" \"${temp:---}\"; if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | head -1 | awk -F, '{gsub(/ /,\"\",$1); gsub(/ /,\"\",$2); printf \"gpu=%s%%\\ngpu_temp=%sC\\n\", $1, $2}'; else printf \"gpu=0%%\\ngpu_temp=--\\n\"; fi; if command -v wpctl >/dev/null 2>&1; then wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{ printf \"volume=%d\\n\", $2*100 }'; wpctl status | awk '/Sinks:/{in_sinks=1; next} /Sources:/{if(in_sinks) exit} in_sinks && /^[[:space:]│├└─*]*[0-9]+\\./ {line=$0; active=(line ~ /\\*/ ? 1 : 0); gsub(/^[^0-9]*/, \"\", line); id=line; sub(/\\..*/, \"\", id); name=line; sub(/^[0-9]+\\. /, \"\", name); sub(/[[:space:]]*\\[vol:.*/, \"\", name); printf \"audio_output=%s|%s|%s\\n\", id, active, name }'; else printf \"volume=43\\n\"; fi; if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -m | awk -F, '{ gsub(/%/,\"\",$4); printf \"brightness=%s\\n\", $4 }'; else printf \"brightness=58\\n\"; fi; printf \"recording=%s\\n\" \"$($HOME/dotfiles/nix/quickshell/scripts/screen_record.sh status 2>/dev/null || echo 'not recording')\"; printf \"nightlight=%s\\n\" \"$(systemctl --user is-active hyprsunset.service 2>/dev/null || true)\""
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateStats(text)
        }
    }

    Process {
        id: actionRunner

        command: ["true"]
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) console.warn(text.trim())
        }
    }

    Process {
        id: networkSummaryQuery

        command: ["bash", "-lc", "printf 'wifi_enabled=%s\\n' \"$(nmcli -t -f WIFI general 2>/dev/null | tail -1)\"; printf 'wifi_ssid=%s\\n' \"$(nmcli -t -f ACTIVE,SSID device wifi list --rescan no 2>/dev/null | awk -F: '$1==\"yes\" {print $2; exit}')\""]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateNetworkSummary(text)
        }
    }

    Timer {
        id: volumeCommitTimer

        interval: 80
        repeat: false
        onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${Math.max(0, Math.min(150, root.volumePercent))}%`])
    }

    Timer {
        id: brightnessCommitTimer

        interval: 80
        repeat: false
        onTriggered: Quickshell.execDetached(["brightnessctl", "set", `${Math.max(1, Math.min(100, root.brightnessPercent))}%`])
    }

    Timer {
        interval: 2500
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statsQuery.running = true;
            networkSummaryQuery.running = true;
        }
    }

    Loader {
        id: activeContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.theme.gap
        sourceComponent: root.activeView === "network" ? networkSubmenu : root.activeView === "bluetooth" ? bluetoothSubmenu : dashboardContent
    }

    Component {
        id: dashboardContent

        Column {
        id: content

        width: root.width - root.theme.gap * 2
        spacing: root.gap

        Row {
            width: parent.width
            height: root.theme.dashboardTileHeight * 2 + root.gap
            spacing: root.gap

            Column {
                width: root.tileWidth
                height: parent.height
                spacing: root.gap

                ControlTile { theme: root.theme; width: root.tileWidth; height: root.theme.dashboardTileHeight; icon: "󰤨"; title: "Wi-Fi"; value: root.wifiTileValue(); active: root.wifiEnabled; activate: () => root.activeView = "network" }
                ControlTile { theme: root.theme; width: root.tileWidth; height: root.theme.dashboardTileHeight; icon: "󰂯"; title: "Bluetooth"; value: root.bluetoothTileValue(); active: root.connectedBluetoothDevices > 0; activate: () => root.activeView = "bluetooth" }
            }

            Rectangle {
                id: mediaCard

                width: root.mediaWidth
                height: parent.height
                radius: root.theme.popupSectionRadius
                color: mediaHoverArea.containsMouse ? root.theme.chipHoverBackground : root.theme.popupSectionBackground

                MouseArea {
                    id: mediaHoverArea

                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: root.gap
                    spacing: root.gap * 0.7

                    Text {
                        width: parent.width
                        text: root.activePlayer ? root.activePlayer.trackTitle || root.activePlayer.identity : "Not Playing"
                        color: root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: true
                    }

                    Item {
                        width: parent.width
                        height: parent.height - mediaControls.height - root.gap - root.theme.fontSize * 1.4

                        Text {
                            anchors.centerIn: parent
                            text: root.activePlayer ? "" : "󰝚"
                            color: root.theme.popupMutedText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize * 1.7
                        }
                    }

                    Row {
                        id: mediaControls

                        width: parent.width
                        height: root.theme.popupElementSize
                        spacing: root.gap

                        MediaButton { theme: root.theme; width: (parent.width - root.gap * 2) / 3; icon: "󰒮"; enabled: root.activePlayer && root.activePlayer.canGoPrevious; activate: () => root.activePlayer.previous() }
                        MediaButton { theme: root.theme; width: (parent.width - root.gap * 2) / 3; icon: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"; emphasized: true; enabled: root.activePlayer && root.activePlayer.canTogglePlaying; activate: () => root.activePlayer.togglePlaying() }
                        MediaButton { theme: root.theme; width: (parent.width - root.gap * 2) / 3; icon: "󰒭"; enabled: root.activePlayer && root.activePlayer.canGoNext; activate: () => root.activePlayer.next() }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: root.theme.dashboardTileHeight
            spacing: root.gap

            Repeater {
                model: root.quickActions()

                Rectangle {
                    id: quickButton

                    required property var modelData

                    width: root.cell
                    height: root.theme.dashboardTileHeight
                    radius: root.theme.popupSectionRadius
                    color: quickHoverArea.containsMouse && modelData.enabled ? root.theme.chipHoverBackground : modelData.active ? root.theme.popupAccent : modelData.enabled ? root.theme.popupSectionBackground : root.theme.chipBackground

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: modelData.active ? root.theme.iconOnAccentColor : root.theme.iconColor
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 1.1
                    }

                    MouseArea {
                        id: quickHoverArea

                        anchors.fill: parent
                        cursorShape: quickButton.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        hoverEnabled: quickButton.modelData.enabled
                        onClicked: if (quickButton.modelData.enabled) root.runQuickAction(quickButton.modelData.action)
                    }
                }
            }
        }

        SliderTile { theme: root.theme; width: parent.width; icon: "󰕾"; title: "Sound"; percent: root.volumePercent; expandable: true; expanded: root.audioSelectorOpen; setPercent: (value, dragging) => root.setVolume(value, dragging); toggleExpanded: () => root.audioSelectorOpen = !root.audioSelectorOpen }

        Rectangle {
            width: parent.width
            height: root.audioSelectorOpen ? audioOutputColumn.implicitHeight + root.theme.gap * 2 : 0
            visible: root.audioSelectorOpen
            radius: root.theme.popupSectionRadius
            color: root.theme.popupSectionBackground

            Column {
                id: audioOutputColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.theme.gap
                spacing: root.theme.gap

                Text {
                    width: parent.width
                    text: "Output"
                    color: root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.78
                    font.bold: true
                }

                Repeater {
                    model: root.audioOutputs

                    Rectangle {
                        id: outputRow

                        required property var modelData

                        width: parent.width
                        height: root.theme.popupElementSize * 1.05
                        radius: root.theme.popupSectionRadius
                        color: outputHover.containsMouse || modelData.active ? root.theme.chipHoverBackground : root.theme.transparentColor

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.gap
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: outputRow.modelData.active ? root.theme.popupAccent : root.theme.popupMutedText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.popupElementSize
                            anchors.right: checkIcon.left
                            anchors.rightMargin: root.theme.gap
                            anchors.verticalCenter: parent.verticalCenter
                            text: outputRow.modelData.name
                            color: outputRow.modelData.active ? root.theme.popupAccent : root.theme.popupText
                            elide: Text.ElideRight
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize * 0.85
                            font.bold: outputRow.modelData.active
                        }

                        Text {
                            id: checkIcon

                            anchors.right: parent.right
                            anchors.rightMargin: root.theme.gap
                            anchors.verticalCenter: parent.verticalCenter
                            text: outputRow.modelData.active ? "" : ""
                            color: root.theme.popupAccent
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize
                        }

                        MouseArea {
                            id: outputHover

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.setAudioOutput(outputRow.modelData.id)
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: root.audioOutputs.length === 0
                    text: "No output devices"
                    color: root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.85
                }
            }
        }

        SliderTile { theme: root.theme; width: parent.width; icon: "󰍹"; title: "Display"; percent: root.brightnessPercent; setPercent: (value, dragging) => root.setBrightness(value, dragging) }

        Rectangle {
            width: parent.width
            height: statsColumn.implicitHeight + root.theme.gap * 2
            radius: root.theme.popupSectionRadius
            color: root.theme.popupSectionBackground

            Column {
                id: statsColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.theme.gap
                spacing: 0

                StatRow { theme: root.theme; icon: "󰻠"; label: "CPU"; value: `${root.stats.cpu || "0"}%`; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰍛"; label: "CPU Temp"; value: root.stats.cpu_temp || "--"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰍹"; label: "RAM"; value: root.stats.ram || "--"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰢮"; label: "GPU"; value: root.stats.gpu || "0%"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰍛"; label: "GPU Temp"; value: root.stats.gpu_temp || "--"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰋊"; label: "Disk"; value: root.stats.disk || "--"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰈀"; label: "Net"; value: root.stats.net || "--"; accent: root.theme.iconMutedColor }
                StatRow { theme: root.theme; icon: "󰅐"; label: "Uptime"; value: root.stats.uptime || "--"; accent: root.theme.iconMutedColor }
                StatRow { theme: root.theme; icon: "󱑃"; label: "Load"; value: root.stats.load || "--"; accent: root.theme.iconMutedColor }
            }
        }
    }

    }

    Component {
        id: networkSubmenu

        DashboardNetworkSubmenu {
            theme: root.theme
            width: root.width - root.theme.gap * 2
            goBack: () => root.activeView = "dashboard"
            openSettings: () => root.openSettings("network")
        }
    }

    Component {
        id: bluetoothSubmenu

        DashboardBluetoothSubmenu {
            theme: root.theme
            width: root.width - root.theme.gap * 2
            goBack: () => root.activeView = "dashboard"
            openSettings: () => root.openSettings("bluetooth")
        }
    }

    function updateStats(rawText) {
        const next = {};
        const outputs = [];
        for (const line of rawText.trim().split("\n")) {
            const index = line.indexOf("=");
            if (index > 0) {
                const key = line.slice(0, index);
                const value = line.slice(index + 1);
                if (key === "audio_output") {
                    const parts = value.split("|");
                    outputs.push({ id: parts[0], active: parts[1] === "1", name: parts.slice(2).join("|") });
                } else {
                    next[key] = value;
                }
            }
        }
        root.stats = next;
        root.audioOutputs = outputs;
        root.recording = next.recording === "recording";
        root.nightLight = next.nightlight === "active";
        if (!root.adjustingVolume) {
            root.volumePercent = Number(next.volume || root.volumePercent);
        }
        if (!root.adjustingBrightness) {
            root.brightnessPercent = Number(next.brightness || root.brightnessPercent);
        }
    }

    function updateNetworkSummary(rawText) {
        for (const line of rawText.trim().split("\n")) {
            const index = line.indexOf("=");
            if (index <= 0) {
                continue;
            }

            const key = line.slice(0, index);
            const value = line.slice(index + 1).trim();
            if (key === "wifi_enabled") {
                root.wifiEnabled = value === "enabled";
            } else if (key === "wifi_ssid") {
                root.wifiSsid = value;
            }
        }
    }

    function wifiTileValue() {
        if (!root.wifiEnabled) {
            return "Off";
        }
        return root.wifiSsid.length > 0 ? root.wifiSsid : "On";
    }

    function bluetoothTileValue() {
        if (root.connectedBluetoothDevices > 0) {
            return `${root.connectedBluetoothDevices} connected`;
        }
        return Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "On" : "Off";
    }

    function quickActions() {
        return [
            { icon: "󰑊", action: "record", enabled: true, active: root.recording },
            { icon: "", action: "color", enabled: true, active: false },
            { icon: root.inhibited ? "󰅶" : "󰾪", action: "inhibit", enabled: true, active: root.inhibited },
            { icon: root.nightLight ? "󰖔" : "󰖨", action: "nightlight", enabled: true, active: root.nightLight },
            { icon: "󰔎", action: "theme", enabled: true, active: false },
            { icon: "", action: "", enabled: false, active: false }
        ];
    }

    function runCommand(command) {
        actionRunner.command = ["bash", "-lc", command];
        actionRunner.running = true;
    }

    function runQuickAction(action) {
        if (action === "record") {
            runCommand(`${Quickshell.env("HOME")}/dotfiles/nix/quickshell/scripts/screen_record.sh ${root.recording ? "stop" : "start region \"$HOME/Videos\""}`);
        } else if (action === "color") {
            runCommand("hyprpicker -a");
        } else if (action === "inhibit") {
            if (root.inhibited) {
                runCommand("pid=$(cat /tmp/quickshell-dashboard-inhibit.pid 2>/dev/null || true); [ -n \"$pid\" ] && kill \"$pid\" 2>/dev/null; rm -f /tmp/quickshell-dashboard-inhibit.pid");
                root.inhibited = false;
            } else {
                runCommand("systemd-inhibit --what=idle:sleep --who=quickshell-dashboard --why='dashboard inhibit' sleep infinity & echo $! >/tmp/quickshell-dashboard-inhibit.pid");
                root.inhibited = true;
            }
        } else if (action === "nightlight") {
            runCommand(`systemctl --user ${root.nightLight ? "stop" : "start"} hyprsunset.service`);
        } else if (action === "theme") {
            runCommand('current="$(darkman get 2>/dev/null || echo dark)"; if [ "$current" = dark ]; then themectl set-polarity light; else themectl set-polarity dark; fi');
        }
    }

    function setVolume(value, dragging) {
        root.adjustingVolume = !!dragging;
        root.volumePercent = Math.max(0, Math.min(150, value));
        root.pulseLauncher("volume", root.volumePercent);
        volumeCommitTimer.restart();
    }

    function setAudioOutput(id) {
        runCommand(`wpctl set-default ${id}`);
    }

    function setBrightness(value, dragging) {
        root.adjustingBrightness = !!dragging;
        root.brightnessPercent = Math.max(1, Math.min(100, value));
        root.pulseLauncher("brightness", root.brightnessPercent);
        brightnessCommitTimer.restart();
    }

    component ControlTile: Rectangle {
        id: controlTile

        required property var theme
        property string icon: ""
        property string title: ""
        property string value: ""
        property bool active: false
        property var activate: () => {}

        radius: theme.popupSectionRadius
        color: controlHoverArea.containsMouse ? theme.chipHoverBackground : theme.popupSectionBackground

        Row {
            anchors.fill: parent
            anchors.margins: theme.gap
            spacing: theme.gap

            Text { text: icon; color: controlTile.active ? theme.iconActiveColor : theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 1.05; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - parent.spacing - theme.popupElementSize * 0.8
                spacing: 1
                Text { text: title; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.9; font.bold: true }
                Text { text: value; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.76; elide: Text.ElideRight; width: parent.width }
            }
        }

        MouseArea {
            id: controlHoverArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: controlTile.activate()
        }
    }

    component MediaButton: Rectangle {
        id: mediaButton

        required property var theme
        property string icon: ""
        property bool enabled: true
        property bool emphasized: false
        property var activate: () => {}

        height: theme.popupElementSize
        radius: theme.popupSectionRadius * 0.75
        color: mediaButtonHoverArea.containsMouse && enabled ? theme.popupSectionBackground : emphasized ? theme.chipHoverBackground : theme.chipBackground
        opacity: enabled ? 1 : 0.45

        Text { anchors.centerIn: parent; text: icon; color: theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize }
        MouseArea { id: mediaButtonHoverArea; anchors.fill: parent; enabled: parent.enabled; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: parent.activate() }
    }

    component SliderTile: Rectangle {
        id: sliderTile

        required property var theme
        property string icon: ""
        property string title: ""
        property int percent: 0
        property bool expandable: false
        property bool expanded: false
        property var setPercent: value => {}
        property var toggleExpanded: () => {}

        height: theme.dashboardSliderHeight
        radius: theme.popupSectionRadius
        color: sliderHoverArea.containsMouse ? theme.chipHoverBackground : theme.popupSectionBackground

        readonly property int trackWidth: width - theme.gap * 2
        readonly property int trackY: height - theme.gap - 5
        readonly property int clampedPercent: Math.max(0, Math.min(100, percent))

        function valueFromMouse(mouseX) {
            return Math.round(Math.max(0, Math.min(1, (mouseX - theme.gap) / trackWidth)) * 100);
        }

        function updateFromMouse(mouseX, dragging) {
            setPercent(valueFromMouse(mouseX), dragging);
        }

        Text { x: theme.gap; y: theme.gap; text: icon; color: theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: theme.gap; text: title; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; font.bold: true }
        Text { anchors.right: parent.right; anchors.rightMargin: theme.gap; y: theme.gap; text: `${percent}%`; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.85 }
        Text { visible: sliderTile.expandable; anchors.right: parent.right; anchors.rightMargin: theme.gap; y: theme.gap + theme.fontSize; text: sliderTile.expanded ? "󰅀" : "󰅂"; color: theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.75 }
        Rectangle { x: theme.gap; y: parent.trackY; width: parent.trackWidth; height: 5; radius: 3; color: theme.popupBorder }
        Rectangle { x: theme.gap; y: parent.trackY; width: parent.trackWidth * parent.clampedPercent / 100; height: 5; radius: 3; color: theme.popupAccent }
        Rectangle { x: theme.gap + parent.trackWidth * parent.clampedPercent / 100 - width / 2; y: parent.trackY + 2.5 - height / 2; width: theme.dashboardSliderThumbSize; height: width; radius: width / 2; color: theme.popupText }

        MouseArea {
            id: sliderHoverArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: mouse => {
                if (sliderTile.expandable && mouse.y < sliderTile.trackY - theme.gap * 0.4) {
                    sliderTile.toggleExpanded();
                } else {
                    sliderTile.updateFromMouse(mouse.x, false);
                }
            }
            onPressed: mouse => {
                if (!(sliderTile.expandable && mouse.y < sliderTile.trackY - theme.gap * 0.4)) {
                    sliderTile.updateFromMouse(mouse.x, true);
                }
            }
            onPositionChanged: mouse => {
                if (pressed) {
                    sliderTile.updateFromMouse(mouse.x, true);
                }
            }
            onReleased: mouse => {
                if (!(sliderTile.expandable && mouse.y < sliderTile.trackY - theme.gap * 0.4)) {
                    sliderTile.updateFromMouse(mouse.x, false);
                }
            }
        }
    }

    component StatRow: Item {
        id: statRow

        required property var theme
        property string icon: ""
        property string label: ""
        property string value: ""
        property color accent: theme.popupAccent

        width: parent.width
        height: theme.statRowHeight

        Rectangle {
            anchors.fill: parent
            radius: theme.popupSectionRadius * 0.6
            color: statHoverArea.containsMouse ? theme.chipHoverBackground : theme.transparentColor
        }

        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: icon; color: accent; font.family: theme.fontFamily; font.pixelSize: theme.fontSize }
        Text { anchors.left: parent.left; anchors.leftMargin: theme.popupElementSize; anchors.verticalCenter: parent.verticalCenter; text: label; color: theme.popupText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; font.bold: true }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: value; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSize * 0.9 }

        MouseArea {
            id: statHoverArea

            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }
}
