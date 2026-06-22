import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets

Rectangle {
    id: root

    required property var theme
    required property var wifiSource
    required property var bluetoothSource
    property var openSettings: tab => {}
    property var pulseLauncher: (context, percent) => {}
    property bool dashboardPopupOpen: false

    property var stats: ({})
    property string activeView: "dashboard"
    property bool recording: false
    property bool inhibited: false
    property bool nightLight: false
    property bool audioSelectorOpen: false
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
    readonly property int connectedBluetoothDevices: root.bluetoothSource.connectedDevices.length
    readonly property bool wifiEnabled: root.wifiSource.wifiEnabled
    readonly property string wifiSsid: root.wifiSource.activeNetwork?.ssid ?? ""

    width: theme.popupWidth
    height: activeContent.implicitHeight + theme.gap * 2
    implicitWidth: width
    implicitHeight: height
    radius: theme.popupSectionRadius
    color: theme.popupBackground
    border.width: theme.popupBorderWidth
    border.color: theme.popupBorder

    onDashboardPopupOpenChanged: if (!dashboardPopupOpen) {
        activeView = "dashboard";
        audioSelectorOpen = false;
    }

    Process {
        id: statsQuery

        command: [
            "bash",
            "-lc",
            "cat \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-cunbidun/dashboard-state.json\" 2>/dev/null || printf '{}'"
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
        onTriggered: statsQuery.running = true
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

                    Row {
                        id: mediaInfo

                        width: parent.width
                        height: parent.height - mediaControls.height - parent.spacing
                        spacing: root.gap

                        ClippingRectangle {
                            id: artwork

                            height: parent.height
                            width: height
                            radius: root.theme.popupSectionRadius * 0.8
                            color: root.theme.popupBackground

                            Image {
                                id: artImage

                                anchors.fill: parent
                                source: root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: width * 2
                                sourceSize.height: height * 2
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: artImage.status !== Image.Ready
                                text: "󰝚"
                                color: root.theme.popupMutedText
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSize * 1.4
                            }
                        }

                        Column {
                            width: parent.width - artwork.width - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: root.activePlayer ? (root.activePlayer.trackTitle || root.activePlayer.identity) : "Not Playing"
                                color: root.theme.popupText
                                elide: Text.ElideRight
                                font.family: root.theme.fontFamilyEmphasis
                                font.pixelSize: root.theme.fontSize
                            }

                            Text {
                                width: parent.width
                                visible: text.length > 0
                                text: root.activePlayer ? (root.activePlayer.trackArtist || "") : ""
                                color: root.theme.popupMutedText
                                elide: Text.ElideRight
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeSmall
                            }
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
                        font.pixelSize: root.theme.fontSizeMedium
                    }

                    MouseArea {
                        id: quickHoverArea

                        anchors.fill: parent
                        cursorShape: Qt.ArrowCursor
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
                    font.family: root.theme.fontFamilyEmphasis
                    font.pixelSize: root.theme.fontSizeSmall
                }

                Repeater {
                    model: root.audioOutputs

                    Rectangle {
                        id: outputRow

                        required property var modelData

                        width: parent.width
                        height: root.theme.compactRowHeight
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
                            font.family: outputRow.modelData.active ? root.theme.fontFamilyEmphasis : root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeSmall
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
                            cursorShape: Qt.ArrowCursor
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
                    font.pixelSize: root.theme.fontSizeSmall
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
                StatRow { theme: root.theme; icon: ""; label: "CPU Temp"; value: root.stats.cpu_temp || "--"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰍹"; label: "RAM"; value: root.stats.ram || "--"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: "󰢮"; label: "GPU"; value: root.stats.gpu || "0%"; accent: root.theme.iconActiveColor }
                StatRow { theme: root.theme; icon: ""; label: "GPU Temp"; value: root.stats.gpu_temp || "--"; accent: root.theme.iconActiveColor }
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
            wifiSource: root.wifiSource
            goBack: () => root.activeView = "dashboard"
            openSettings: () => root.openSettings("network")
        }
    }

    Component {
        id: bluetoothSubmenu

        DashboardBluetoothSubmenu {
            theme: root.theme
            width: root.width - root.theme.gap * 2
            bluetoothSource: root.bluetoothSource
            goBack: () => root.activeView = "dashboard"
            openSettings: () => root.openSettings("bluetooth")
        }
    }

    function updateStats(rawText) {
        let next = {};
        try {
            next = JSON.parse(rawText.trim() || "{}");
        } catch (error) {
            console.warn(`Invalid dashboard stats: ${error}`);
            return;
        }
        root.stats = next;
        root.audioOutputs = next.audio_outputs || [];
        root.recording = next.recording === "recording";
        root.nightLight = next.nightlight === "active";
        if (!root.adjustingVolume) {
            root.volumePercent = Number(next.volume || root.volumePercent);
        }
        if (!root.adjustingBrightness) {
            root.brightnessPercent = Number(next.brightness || root.brightnessPercent);
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
        return root.bluetoothSource.enabled ? "On" : "Off";
    }

    function quickActions() {
        return [
            { icon: "󰑊", action: "record", enabled: true, active: root.recording },
            { icon: "", action: "color", enabled: true, active: false },
            { icon: root.inhibited ? "󰅶" : "󰾪", action: "inhibit", enabled: true, active: root.inhibited },
            { icon: root.nightLight ? "󰖔" : "󰖨", action: "nightlight", enabled: true, active: root.nightLight },
            { icon: root.theme.isLightTheme ? "󰖨" : "󰖔", action: "theme", enabled: true, active: root.theme.isLightTheme },
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
            runCommand("themectl toggle");
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

            Text { text: icon; color: controlTile.active ? theme.iconActiveColor : theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSizeMedium; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - parent.spacing - theme.popupElementSize * 0.8
                spacing: 1
                Text { text: title; color: theme.popupText; font.family: theme.fontFamilyEmphasis; font.pixelSize: theme.fontSizeSmall }
                Text { text: value; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSizeSmall; elide: Text.ElideRight; width: parent.width }
            }
        }

        MouseArea {
            id: controlHoverArea

            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
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
        MouseArea { id: mediaButtonHoverArea; anchors.fill: parent; enabled: parent.enabled; cursorShape: Qt.ArrowCursor; hoverEnabled: true; onClicked: parent.activate() }
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
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: theme.gap; text: title; color: theme.popupText; font.family: theme.fontFamilyEmphasis; font.pixelSize: theme.fontSize }
        Text { anchors.right: parent.right; anchors.rightMargin: theme.gap; y: theme.gap; text: `${percent}%`; color: theme.popupMutedText; font.family: theme.fontFamily; font.pixelSize: theme.fontSizeSmall }
        Rectangle { x: theme.gap; y: parent.trackY; width: parent.trackWidth; height: 5; radius: 3; color: theme.popupBorder }
        Rectangle { x: theme.gap; y: parent.trackY; width: parent.trackWidth * parent.clampedPercent / 100; height: 5; radius: 3; color: theme.popupAccent }
        Rectangle { x: theme.gap + parent.trackWidth * parent.clampedPercent / 100 - width / 2; y: parent.trackY + 2.5 - height / 2; width: theme.dashboardSliderThumbSize; height: width; radius: width / 2; color: theme.popupText }

        MouseArea {
            id: sliderHoverArea

            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
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
        Text { anchors.left: parent.left; anchors.leftMargin: theme.popupElementSize; anchors.verticalCenter: parent.verticalCenter; text: label; color: theme.popupText; font.family: theme.fontFamilyMono; font.pixelSize: theme.fontSize; font.weight: Font.DemiBold }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: value; color: theme.popupMutedText; font.family: theme.fontFamilyMono; font.pixelSize: theme.fontSizeSmall }

        MouseArea {
            id: statHoverArea

            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }
}
