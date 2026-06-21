import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

ModuleChip {
    id: root

    property string layoutName: "unknown"

    icon: "󰙀"
    label: normalizeLayoutName(layoutName)

    Process {
        id: layoutQuery

        command: ["hyprctl", "-j", "activeworkspace"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateLayout(text)
        }
    }

    Component.onCompleted: layoutQuery.running = true

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = event.name;

            if (["workspace", "workspacev2", "focusedmon", "configreloaded"].includes(name) || name.includes("layout") || name.includes("window")) {
                layoutQuery.running = true;
            }
        }
    }

    function updateLayout(rawText) {
        if (!rawText || rawText.length === 0) {
            return;
        }

        try {
            const activeWorkspace = JSON.parse(rawText);
            root.layoutName = activeWorkspace.tiledLayout || "unknown";
        } catch (error) {
            console.warn(`Failed to parse Hyprland active workspace: ${error}`);
            root.layoutName = "unknown";
        }
    }

    function normalizeLayoutName(layout) {
        return String(layout || "unknown").replace(/^lua:/, "");
    }
}
