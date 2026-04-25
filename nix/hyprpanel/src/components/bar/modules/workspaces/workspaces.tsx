import { initWorkspaceEvents } from './helpers/utils';
import { getAppIcon, getWsColor, getWsIcon, renderClassnames, renderLabel } from './helpers';
import { bind, execAsync, GLib, Variable } from 'astal';
import AstalHyprland from 'gi://AstalHyprland?version=0.1';
import { Gtk } from 'astal/gtk3';
import { WorkspaceService } from 'src/services/workspace';
import options from 'src/configuration';
import { isPrimaryClick } from 'src/lib/events/mouse';
import { WorkspaceIconMap, ApplicationIcons } from './types';

const workspaceService = WorkspaceService.getInstance();

const hyprlandService = AstalHyprland.get_default();
const {
    workspaces,
    monitorSpecific,
    workspaceMask,
    spacing,
    ignored,
    showAllActive,
    show_icons,
    show_numbered,
    numbered_active_indicator,
    workspaceIconMap,
    showWsIcons,
    showApplicationIcons,
    applicationIconOncePerWorkspace,
    applicationIconMap,
    applicationIconEmptyWorkspace,
    applicationIconFallback,
} = options.bar.workspaces;
const { available, active, occupied } = options.bar.workspaces.icons;
const { smartHighlight } = options.theme.bar.buttons.workspaces;

initWorkspaceEvents();

const ACTIVE_WORKSPACE_NAME_RE = /^(?<project>\d+)(?:\[(?<sub>[^\]]+)\])?$/;

const parseWorkspaceName = (
    workspaceName: string | null | undefined,
): { project: number; sub?: string } | undefined => {
    if (!workspaceName) {
        return undefined;
    }

    const match = ACTIVE_WORKSPACE_NAME_RE.exec(workspaceName.trim());

    if (!match?.groups?.project) {
        return undefined;
    }

    const project = Number(match.groups.project);

    if (!Number.isFinite(project)) {
        return undefined;
    }

    return {
        project,
        sub: match.groups.sub,
    };
};

const getRememberedStatePath = (): string => {
    const stateDir = GLib.getenv('XDG_STATE_HOME') ?? `${GLib.get_home_dir()}/.local/state`;
    return `${stateDir}/wsctl/last-sub.json`;
};

const loadRememberedWorkspaces = (): Record<string, string> => {
    const statePath = getRememberedStatePath();

    if (!GLib.file_test(statePath, GLib.FileTest.EXISTS)) {
        return {};
    }

    try {
        const [success, contents] = GLib.file_get_contents(statePath);

        if (!success) {
            return {};
        }

        const rememberedWorkspaces = JSON.parse(new TextDecoder().decode(contents));

        return typeof rememberedWorkspaces === 'object' && rememberedWorkspaces !== null
            ? rememberedWorkspaces
            : {};
    } catch (error) {
        console.error(`Failed to read remembered workspaces: ${error}`);
        return {};
    }
};

const saveRememberedWorkspaces = (rememberedWorkspaces: Record<string, string>): void => {
    const statePath = getRememberedStatePath();
    const stateDir = GLib.path_get_dirname(statePath);

    GLib.mkdir_with_parents(stateDir, 0o755);
    GLib.file_set_contents(statePath, JSON.stringify(rememberedWorkspaces));
};

const syncRememberedWorkspace = (
    focusedWorkspaceInfo: { project: number; sub?: string } | undefined,
    focusedWorkspaceName: string | null | undefined,
): Record<string, string> => {
    const rememberedWorkspaces = loadRememberedWorkspaces();

    if (focusedWorkspaceInfo === undefined || focusedWorkspaceName === undefined) {
        return rememberedWorkspaces;
    }

    const projectKey = `${focusedWorkspaceInfo.project}`;
    const rememberedWorkspaceName = rememberedWorkspaces[projectKey];

    if (focusedWorkspaceInfo.sub === undefined) {
        if (rememberedWorkspaceName !== undefined) {
            delete rememberedWorkspaces[projectKey];
            saveRememberedWorkspaces(rememberedWorkspaces);
        }

        return rememberedWorkspaces;
    }

    if (rememberedWorkspaceName !== focusedWorkspaceName) {
        rememberedWorkspaces[projectKey] = focusedWorkspaceName;
        saveRememberedWorkspaces(rememberedWorkspaces);
    }

    return rememberedWorkspaces;
};

const switchToProjectWorkspace = (workspaceId: number): void => {
    execAsync(['wsctl', 'project', `${workspaceId}`]).catch((error) => {
        console.error(`Failed to switch to remembered workspace ${workspaceId}: ${error}`);
        hyprlandService.dispatch('workspace', workspaceId.toString());
    });
};

export const WorkspaceModule = ({ monitor }: WorkspaceModuleProps): JSX.Element => {
    const boxChildren = Variable.derive(
        [
            bind(monitorSpecific),
            bind(hyprlandService, 'workspaces'),
            bind(workspaceMask),
            bind(workspaces),
            bind(show_icons),
            bind(available),
            bind(active),
            bind(occupied),
            bind(show_numbered),
            bind(numbered_active_indicator),
            bind(spacing),
            bind(workspaceIconMap),
            bind(showWsIcons),
            bind(showApplicationIcons),
            bind(applicationIconOncePerWorkspace),
            bind(applicationIconMap),
            bind(applicationIconEmptyWorkspace),
            bind(applicationIconFallback),
            bind(smartHighlight),
            bind(hyprlandService, 'clients'),
            bind(hyprlandService, 'monitors'),

            bind(ignored),
            bind(showAllActive),
            bind(hyprlandService, 'focusedWorkspace'),
            bind(workspaceService.workspaceRules),
            bind(workspaceService.forceUpdater),
        ],
        (
            isMonitorSpecific: boolean,
            workspaceList: AstalHyprland.Workspace[],
            workspaceMaskFlag: boolean,
            totalWorkspaces: number,
            displayIcons: boolean,
            availableStatus: string,
            activeStatus: string,
            occupiedStatus: string,
            displayNumbered: boolean,
            numberedActiveIndicator: string,
            spacingValue: number,
            workspaceIconMapping: WorkspaceIconMap,
            displayWorkspaceIcons: boolean,
            displayApplicationIcons: boolean,
            appIconOncePerWorkspace: boolean,
            applicationIconMapping: ApplicationIcons,
            applicationIconEmptyWorkspace: string,
            applicationIconFallback: string,
            smartHighlightEnabled: boolean,
            clients: AstalHyprland.Client[],
            monitorList: AstalHyprland.Monitor[],
        ) => {
            const wsRules = workspaceService.workspaceRules.get();
            const workspacesToRender = workspaceService.getWorkspaces(
                totalWorkspaces,
                workspaceList,
                wsRules,
                monitor,
                isMonitorSpecific,
                monitorList,
            );
            const focusedWorkspaceInfo = parseWorkspaceName(hyprlandService.focusedWorkspace?.name);
            const rememberedWorkspaces = syncRememberedWorkspace(
                focusedWorkspaceInfo,
                hyprlandService.focusedWorkspace?.name,
            );
            const normalizedWorkspaceIds = Array.from(
                new Set(
                    workspacesToRender.map((workspaceId) => {
                        const workspace = workspaceList.find((workspaceCandidate) => {
                            return workspaceCandidate.id === workspaceId;
                        });

                        return parseWorkspaceName(workspace?.name)?.project ?? workspaceId;
                    }),
                ),
            ).sort((left, right) => left - right);

            return normalizedWorkspaceIds.flatMap((wsId, index) => {
                const appIcons = displayApplicationIcons
                    ? getAppIcon(wsId, appIconOncePerWorkspace, {
                          iconMap: applicationIconMapping,
                          defaultIcon: applicationIconFallback,
                          emptyIcon: applicationIconEmptyWorkspace,
                      })
                    : '';
                const workspaceBaseLabel = displayWorkspaceIcons ? getWsIcon(workspaceIconMapping, wsId) : '';
                const activeWorkspaceName =
                    focusedWorkspaceInfo?.sub !== undefined && focusedWorkspaceInfo.project === wsId
                        ? hyprlandService.focusedWorkspace?.name
                        : undefined;
                const rememberedWorkspaceName =
                    activeWorkspaceName === undefined ? rememberedWorkspaces[`${wsId}`] : undefined;
                const rememberedWorkspaceInfo = parseWorkspaceName(rememberedWorkspaceName);
                const activeSubLabel =
                    activeWorkspaceName !== undefined && workspaceBaseLabel.length > 0
                        ? `${workspaceBaseLabel}[${focusedWorkspaceInfo?.sub}]`
                        : undefined;
                const rememberedSubLabel =
                    activeSubLabel === undefined &&
                    rememberedWorkspaceInfo?.sub !== undefined &&
                    workspaceBaseLabel.length > 0
                        ? `${workspaceBaseLabel}[${rememberedWorkspaceInfo.sub}]`
                        : undefined;

                return (
                    <button
                        className={'workspace-button'}
                        onClick={(_, event) => {
                            if (isPrimaryClick(event)) {
                                switchToProjectWorkspace(wsId);
                            }
                        }}
                    >
                        <label
                            valign={Gtk.Align.CENTER}
                            css={
                                `margin: 0rem ${0.375 * spacingValue}rem;` +
                                `${displayWorkspaceIcons ? getWsColor(workspaceIconMapping, wsId, smartHighlightEnabled, monitor, activeWorkspaceName) : ''}`
                            }
                            className={renderClassnames(
                                displayIcons,
                                displayNumbered,
                                numberedActiveIndicator,
                                displayWorkspaceIcons,
                                smartHighlightEnabled,
                                monitor,
                                wsId,
                                activeWorkspaceName,
                            )}
                            label={
                                activeSubLabel ??
                                rememberedSubLabel ??
                                renderLabel(
                                    displayIcons,
                                    availableStatus,
                                    activeStatus,
                                    occupiedStatus,
                                    displayApplicationIcons,
                                    appIcons,
                                    workspaceMaskFlag,
                                    displayWorkspaceIcons,
                                    workspaceIconMapping,
                                    wsId,
                                    index,
                                    monitor,
                                )
                            }
                            setup={(self) => {
                                const currentWsClients = clients.filter(
                                    (client) => client?.workspace?.id === wsId,
                                );
                                self.toggleClassName('occupied', currentWsClients.length > 0);
                            }}
                        />
                    </button>
                );
            });
        },
    );

    return (
        <box
            onDestroy={() => {
                boxChildren.drop();
            }}
        >
            {boxChildren()}
        </box>
    );
};

interface WorkspaceModuleProps {
    monitor: number;
}
