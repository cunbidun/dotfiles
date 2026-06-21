import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ModuleChip {
    id: root

    property string submapName: "default"
    readonly property bool submapActive: submapName !== "default"

    visible: submapActive
    active: submapActive
    icon: "󰌌"
    label: submapName

    Process {
        id: initialSubmap

        command: ["hyprctl", "submap"]
        stdout: SplitParser {
            onRead: data => root.setSubmapName(data)
        }
    }

    Component.onCompleted: initialSubmap.running = true

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "submap") {
                return;
            }

            root.setSubmapName(event.data);
        }
    }

    function setSubmapName(value) {
        const cleanName = String(value ?? "").trim();
        root.submapName = cleanName.length > 0 && cleanName !== "unknown request" ? cleanName : "default";
    }
}
