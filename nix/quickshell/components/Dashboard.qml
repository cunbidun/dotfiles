import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

ModuleChip {
    id: root

    required property var panelWindow
    required property var wifiSource
    required property var bluetoothSource
    property var openSettings: tab => {}
    property bool popupOpen: false
    property bool launcherPulseActive: false
    property string launcherPulseContext: "volume"
    property int launcherPulsePercent: 0
    property bool audioMonitorReady: false
    property bool brightnessMonitorReady: false
    property int lastVolumePercent: -1
    property int lastBrightnessPercent: -1
    readonly property var audioSink: Pipewire.defaultAudioSink

    icon: launcherPulseActive ? pulseIcon() : ""
    iconColor: launcherPulseActive ? theme.iconActiveColor : theme.iconColor
    label: launcherPulseActive ? `${launcherPulsePercent}%` : ""
    maxLabelWidth: launcherPulseActive ? theme.clockMaxWidth : 0
    activate: () => root.popupOpen = true

    Timer {
        id: launcherPulseTimer

        interval: 1400
        repeat: false
        onTriggered: root.launcherPulseActive = false
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => node.audio && !node.isStream)
    }

    Connections {
        target: root.audioSink?.audio ?? null

        function onVolumeChanged() {
            root.syncAudioPulse();
        }

        function onMutedChanged() {
            root.syncAudioPulse();
        }
    }

    onAudioSinkChanged: {
        audioMonitorReady = false;
        audioInitTimer.restart();
    }

    Timer {
        id: audioInitTimer

        interval: 150
        repeat: false
        running: true
        onTriggered: root.syncAudioPulse()
    }

    Process {
        id: brightnessProbe

        command: ["bash", "-lc", "brightnessctl -m 2>/dev/null | awk -F, '{ gsub(/%/, \"\", $4); print int($4) }'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.syncBrightnessPulse(text)
        }
    }

    Timer {
        interval: 450
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!brightnessProbe.running) brightnessProbe.running = true
    }

    PanelWindow {
        id: dashboardPopup

        visible: root.popupOpen
        screen: root.panelWindow.screen
        color: root.theme.transparentColor

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: root.popupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-dashboard-popup"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: root.popupOpen = false
        }

        FocusScope {
            anchors.fill: parent
            focus: root.popupOpen
            Keys.onEscapePressed: root.popupOpen = false
        }

        Item {
            id: popupFrame

            width: popupContent.width
            height: popupContent.height
            x: root.popupX(width, dashboardPopup.width)
            y: root.theme.barOuterSpacing + root.theme.barHeight + root.theme.gap

            MouseArea { anchors.fill: parent }

            DashboardPopup {
                id: popupContent

                theme: root.theme
                dashboardPopupOpen: root.popupOpen
                wifiSource: root.wifiSource
                bluetoothSource: root.bluetoothSource
                pulseLauncher: (context, percent) => root.pulseLauncher(context, percent)
                openSettings: tab => {
                    root.popupOpen = false;
                    root.openSettings(tab);
                }
            }
        }
    }

    function pulseLauncher(context, percent) {
        root.launcherPulseContext = context;
        root.launcherPulsePercent = Math.round(Math.max(0, Math.min(150, percent)));
        root.launcherPulseActive = true;
        launcherPulseTimer.restart();
    }

    function syncAudioPulse() {
        if (!root.audioSink?.audio)
            return;

        const percent = root.audioSink.audio.muted ? 0 : Math.round(root.audioSink.audio.volume * 100);
        if (!root.audioMonitorReady) {
            root.lastVolumePercent = percent;
            root.audioMonitorReady = true;
            return;
        }

        if (percent === root.lastVolumePercent)
            return;

        root.lastVolumePercent = percent;
        root.pulseLauncher("volume", percent);
    }

    function syncBrightnessPulse(text) {
        const percent = parseInt(text.trim(), 10);
        if (isNaN(percent))
            return;

        if (!root.brightnessMonitorReady) {
            root.lastBrightnessPercent = percent;
            root.brightnessMonitorReady = true;
            return;
        }

        if (percent === root.lastBrightnessPercent)
            return;

        root.lastBrightnessPercent = percent;
        root.pulseLauncher("brightness", percent);
    }

    function pulseIcon() {
        if (launcherPulseContext === "brightness") {
            if (launcherPulsePercent <= 1) return "󰃞";
            if (launcherPulsePercent <= 33) return "󰃟";
            if (launcherPulsePercent <= 66) return "󰃠";
            return "󰃡";
        }

        if (launcherPulsePercent <= 1) return "󰝟";
        if (launcherPulsePercent <= 33) return "󰕿";
        if (launcherPulsePercent <= 66) return "󰖀";
        return "󰕾";
    }
}
