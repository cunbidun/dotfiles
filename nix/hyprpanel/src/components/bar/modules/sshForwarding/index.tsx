import { bind, Variable } from 'astal';
import { Astal } from 'astal/gtk3';
import { Module } from '../../shared/module';
import { BarBoxChild } from 'src/components/bar/types';
import { InputHandlerService } from '../../utils/input/inputHandler';
import sshForwardingService from 'src/services/sshForwarding';
import options from 'src/configuration';

const inputHandler = InputHandlerService.getInstance();

const {
    icon,
    leftClick,
    rightClick,
    middleClick,
    scrollUp,
    scrollDown,
} = options.bar.customModules.sshForwarding;

export const SshForwarding = (): BarBoxChild => {
    void sshForwardingService.initialize();

    const tooltipBinding = Variable.derive([bind(sshForwardingService.state)], (state) => {
        if (!state.active) {
            return state.error || 'SSH forwarding is off';
        }

        return `Forwarding ${state.localPort}:${state.remotePort} on ${state.host}`;
    });

    let inputHandlerBindings: Variable<void>;

    const module = Module({
        textIcon: bind(icon),
        tooltipText: tooltipBinding(),
        boxClass: 'sshforwarding',
        showLabelBinding: bind(Variable(false)),
        showLabel: false,
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
                tooltipBinding.drop();
            },
        },
    });

    return module;
};
