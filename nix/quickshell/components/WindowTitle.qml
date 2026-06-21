import QtQuick
import Quickshell.Hyprland

ModuleChip {
    id: root

    required property var screen

    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var activeToplevel: effectiveToplevel()
    readonly property string clientClass: activeToplevel?.lastIpcObject?.class ?? ""
    readonly property string clientTitle: activeToplevel?.title ?? ""

    icon: iconForClass(clientClass)
    label: titleForClient(clientClass, clientTitle)
    maxLabelWidth: theme.windowTitleMaxWidth

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = event.name;

            if (["activewindow", "activewindowv2", "openwindow", "closewindow", "movewindow", "workspace", "workspacev2", "focusedmon"].includes(name) || name.includes("window")) {
                Hyprland.refreshToplevels();
            }
        }
    }

    function effectiveToplevel() {
        const active = Hyprland.activeToplevel;
        const workspace = Hyprland.focusedWorkspace;
        const workspaceWindows = workspace?.toplevels?.values ?? [];

        if (!active || !workspace) {
            return null;
        }

        if (active.workspace?.name?.startsWith("special:")) {
            return active;
        }

        if (workspaceWindows.length === 0) {
            return null;
        }

        if (active.workspace?.id !== undefined && workspace.id !== undefined && active.workspace.id !== workspace.id) {
            return null;
        }

        return active;
    }

    function titleForClient(clientClass, clientTitle) {
        if (clientClass.length === 0 && clientTitle.length === 0) {
            return "Desktop";
        }

        if (clientClass.length > 0) {
            return prettyClass(clientClass);
        }

        return clientTitle;
    }

    function prettyClass(clientClass) {
        const normalized = String(clientClass).toLowerCase();

        if (normalized.includes("kitty")) {
            return "Kitty Terminal";
        }

        if (normalized.includes("chrome")) {
            return "Google Chrome";
        }

        if (normalized.includes("code") || normalized.includes("cursor") || normalized.includes("codium")) {
            return "editor_side_tree";
        }

        return clientClass.replace(/[-_.]+/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
    }

    function iconForClass(clientClass) {
        const normalized = String(clientClass).toLowerCase();

        if (normalized.includes("kitty")) {
            return "󰄛";
        }

        if (normalized.includes("chrome")) {
            return "";
        }

        if (normalized.includes("code") || normalized.includes("cursor") || normalized.includes("codium")) {
            return "󰈮";
        }

        return clientClass.length === 0 ? "󰇄" : "󰣆";
    }
}
