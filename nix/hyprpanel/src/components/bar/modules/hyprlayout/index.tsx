import { Module } from '../../shared/module';
import { bind, Variable } from 'astal';
import { Astal } from 'astal/gtk3';
import AstalHyprland from 'gi://AstalHyprland?version=0.1';
import options from 'src/configuration';
import { BarBoxChild } from 'src/components/bar/types';
import { InputHandlerService } from '../../utils/input/inputHandler';

const inputHandler = InputHandlerService.getInstance();
const hyprlandService = AstalHyprland.get_default();
const { label, icon, leftClick, rightClick, middleClick, scrollUp, scrollDown } =
    options.bar.customModules.hyprlayout;

const normalizeLayoutName = (layout: string): string => layout.replace(/^lua:/, '');

const getActiveLayout = (): string => {
    try {
        const activeWorkspace = JSON.parse(hyprlandService.message('j/activeworkspace')) as {
            tiledLayout?: string;
        };
        return normalizeLayoutName(activeWorkspace.tiledLayout ?? 'unknown');
    } catch (error) {
        console.error(`Failed to query Hyprland layout: ${error}`);
        return 'unknown';
    }
};

export const HyprLayout = (): BarBoxChild => {
    let inputHandlerBindings: Variable<void>;
    const layoutLabel = Variable.derive(
        [bind(hyprlandService, 'focusedWorkspace'), bind(hyprlandService, 'workspaces')],
        () => getActiveLayout(),
    );

    const layoutModule = Module({
        textIcon: bind(icon),
        label: layoutLabel(),
        showLabelBinding: bind(label),
        boxClass: 'hyprlayout',
        props: {
            setup: (self: Astal.Button) => {
                inputHandlerBindings = inputHandler.attachHandlers(self, {
                    onPrimaryClick: {
                        cmd: leftClick,
                    },
                    onSecondaryClick: {
                        cmd: rightClick,
                    },
                    onMiddleClick: {
                        cmd: middleClick,
                    },
                    onScrollUp: {
                        cmd: scrollUp,
                    },
                    onScrollDown: {
                        cmd: scrollDown,
                    },
                });
            },
            onDestroy: () => {
                inputHandlerBindings.drop();
                layoutLabel.drop();
            },
        },
    });

    return layoutModule;
};
