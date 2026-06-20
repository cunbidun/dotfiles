import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    required property var theme
    required property var screen

    readonly property int workspaceCount: 9
    readonly property var workspaceIconMap: ({
        "1": "SYS",
        "2": "2",
        "3": "3",
        "4": "4",
        "5": "WEB",
        "6": "VN",
        "7": "Q&Q",
        "8": "GAME",
        "9": "VI"
    })
    readonly property string focusedWorkspaceName: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.name : ""
    readonly property var hyprlandWorkspaces: Hyprland.workspaces.values
    readonly property var rememberedWorkspaces: parseJson(rememberedFile.text())
    property int eventTick: 0

    implicitWidth: moduleFrame.implicitWidth
    implicitHeight: moduleFrame.implicitHeight

    Connections {
        target: Hyprland
        function onRawEvent() {
            root.eventTick += 1;
        }
    }

    FileView {
        id: rememberedFile

        path: `${Quickshell.env("HOME")}/.local/state/wsctl/last-sub.json`
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    Rectangle {
        id: moduleFrame

        width: workspaceRow.implicitWidth + root.theme.modulePaddingX * 2
        height: workspaceRow.implicitHeight + root.theme.modulePaddingY * 2
        radius: root.theme.workspaceRadius
        color: root.theme.moduleBackground

        Row {
            id: workspaceRow

            anchors.centerIn: parent
            spacing: root.theme.workspaceGap

            Repeater {
                model: root.workspaceButtons(root.hyprlandWorkspaces, root.focusedWorkspaceName, root.rememberedWorkspaces, root.eventTick)

                WorkspaceButton {
                    required property var modelData

                    theme: root.theme
                    label: modelData.label
                    active: modelData.active
                    occupied: modelData.occupied
                    virtualWorkspace: modelData.virtualWorkspace
                    activate: modelData.activate
                }
            }
        }
    }

    function parseJson(rawText) {
        if (!rawText || rawText.length === 0) {
            return {};
        }

        try {
            return JSON.parse(rawText);
        } catch (error) {
            console.warn(`Failed to parse remembered workspace state: ${error}`);
            return {};
        }
    }

    function parseWorkspaceName(workspaceName) {
        if (!workspaceName) {
            return null;
        }

        const match = String(workspaceName).trim().match(/^(\d+)(?:\[([^\]]+)\])?$/);
        if (!match) {
            return null;
        }

        return {
            project: Number(match[1]),
            sub: match[2] || "",
            name: String(workspaceName).trim()
        };
    }

    function labelForProject(project) {
        return workspaceIconMap[String(project)] || String(project);
    }

    function projectWorkspaces(workspaceValues, project) {
        return workspaceValues.map(workspace => ({
            workspace,
            parsed: parseWorkspaceName(workspace.name)
        })).filter(entry => entry.parsed && entry.parsed.project === project);
    }

    function hasProjectWorkspace(workspaceValues, project) {
        return projectWorkspaces(workspaceValues, project).length > 0;
    }

    function sortedSubWorkspaces(workspaceValues, project, focusedName) {
        return projectWorkspaces(workspaceValues, project).filter(entry => {
            if (entry.parsed.sub.length === 0) {
                return false;
            }

            return entry.workspace.name === focusedName || entry.workspace.active || entry.workspace.focused;
        }).sort((left, right) => left.parsed.sub.localeCompare(right.parsed.sub, undefined, { numeric: true }));
    }

    function focusWorkspace(workspaceName) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${JSON.stringify(workspaceName)} })`]);
    }

    function focusProject(project) {
        Quickshell.execDetached(["wsctl", "project", String(project)]);
    }

    function workspaceButtons(workspaceValues, focusedName, remembered, tick) {
        const focused = parseWorkspaceName(focusedName);
        const buttons = [];

        for (let project = 1; project <= workspaceCount; project += 1) {
            const baseLabel = labelForProject(project);
            const isFocusedProject = focused && focused.project === project;
            const subWorkspaces = isFocusedProject ? sortedSubWorkspaces(workspaceValues, project, focusedName) : [];
            const rememberedWorkspace = parseWorkspaceName(remembered[String(project)]);
            const rememberedSuffix = rememberedWorkspace && rememberedWorkspace.sub.length > 0 ? `[${rememberedWorkspace.sub}]` : "";

            buttons.push({
                label: isFocusedProject && focused.sub.length > 0 ? `${baseLabel}[${focused.sub}]` : `${baseLabel}${rememberedSuffix}`,
                active: !!isFocusedProject,
                occupied: hasProjectWorkspace(workspaceValues, project),
                virtualWorkspace: rememberedSuffix.length > 0,
                activate: () => focusProject(project)
            });

            for (const entry of subWorkspaces) {
                if (entry.workspace.name === focusedName) {
                    continue;
                }

                buttons.push({
                    label: `${baseLabel}[${entry.parsed.sub}]`,
                    active: false,
                    occupied: true,
                    virtualWorkspace: true,
                    activate: () => focusWorkspace(entry.workspace.name)
                });
            }
        }

        return buttons;
    }
}
