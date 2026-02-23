import { Variable, bind } from 'astal';
import { onPrimaryClick, onSecondaryClick, onMiddleClick, onScroll } from 'src/lib/shared/eventHandlers';
import { Astal } from 'astal/gtk3';
import { BarBoxChild } from 'src/components/bar/types.js';
import { SystemUtilities } from 'src/core/system/SystemUtilities';
import options from 'src/configuration';
import AstalWp from 'gi://AstalWp?version=0.1';
import BrightnessService from 'src/services/system/brightness';
import { resolveOsdIcon } from 'src/components/osd/iconResolver';
import { barLauncherDynamicActive, osdContext, type OsdContext } from 'src/components/osd/state';
import { runAsyncCommand } from '../../utils/input/commandExecutor';
import { throttledScrollHandler } from '../../utils/input/throttle';
import { openDropdownMenu } from '../../utils/menu';

const { rightClick, middleClick, scrollUp, scrollDown, autoDetectIcon, icon } = options.bar.launcher;
const wireplumber = AstalWp.get_default() as AstalWp.Wp;
const audioService = wireplumber.audio;
const brightnessService = BrightnessService.getInstance();
const mutedZero = options.theme.osd.muted_zero;

const getContextPercent = (
    context: OsdContext,
    screenBrightness: number,
    keyboardBrightness: number,
    speakerVolume: number,
    speakerMuted: boolean,
    zeroWhenMuted: boolean,
): number => {
    if (context === 'brightness') {
        return Math.round(screenBrightness * 100);
    }

    if (context === 'keyboard-brightness') {
        return Math.round(keyboardBrightness * 100);
    }

    if (zeroWhenMuted && speakerMuted) {
        return 0;
    }

    return Math.round(speakerVolume * 100);
};

const Menu = (): BarBoxChild => {
    const iconBinding = Variable.derive(
        [
            autoDetectIcon,
            icon,
            bind(barLauncherDynamicActive),
            bind(osdContext),
            bind(brightnessService, 'screen'),
            bind(brightnessService, 'kbd'),
            bind(audioService.defaultSpeaker, 'volume'),
            bind(audioService.defaultSpeaker, 'mute'),
        ],
        (
            autoDetect: boolean,
            iconValue: string,
            dynamicActive: boolean,
            context: OsdContext,
            screenBrightness: number,
            keyboardBrightness: number,
            speakerVolume: number,
            speakerMuted: boolean,
        ): string => {
            if (dynamicActive) {
                return resolveOsdIcon({
                    context,
                    screenBrightness,
                    keyboardBrightness,
                    speakerVolume,
                    speakerMuted,
                });
            }

            return autoDetect ? SystemUtilities.getDistroIcon() : iconValue;
        },
    );

    const percentBinding = Variable.derive(
        [
            bind(barLauncherDynamicActive),
            bind(osdContext),
            bind(brightnessService, 'screen'),
            bind(brightnessService, 'kbd'),
            bind(audioService.defaultSpeaker, 'volume'),
            bind(audioService.defaultSpeaker, 'mute'),
            bind(mutedZero),
        ],
        (
            dynamicActive: boolean,
            context: OsdContext,
            screenBrightness: number,
            keyboardBrightness: number,
            speakerVolume: number,
            speakerMuted: boolean,
            zeroWhenMuted: boolean,
        ): string => {
            if (!dynamicActive) {
                return '';
            }

            return `${getContextPercent(
                context,
                screenBrightness,
                keyboardBrightness,
                speakerVolume,
                speakerMuted,
                zeroWhenMuted,
            )}%`;
        },
    );

    const componentClassName = bind(options.theme.bar.buttons.style).as((style: string) => {
        const styleMap: Record<string, string> = {
            default: 'style1',
            split: 'style2',
            wave: 'style3',
            wave2: 'style3',
        };
        return `dashboard ${styleMap[style]}`;
    });

    const component = (
        <box
            className={componentClassName}
            onDestroy={() => {
                iconBinding.drop();
                percentBinding.drop();
            }}
        >
            <label className={'bar-menu_label bar-button_icon txt-icon bar'} label={iconBinding()} />
            <label
                className={bind(barLauncherDynamicActive).as((active) =>
                    active ? 'bar-menu_pct bar-menu_pct-active' : 'bar-menu_pct',
                )}
                label={percentBinding()}
            />
        </box>
    );

    return {
        component,
        isVisible: true,
        boxClass: 'dashboard',
        props: {
            setup: (self: Astal.Button): void => {
                let disconnectFunctions: (() => void)[] = [];

                Variable.derive(
                    [
                        bind(rightClick),
                        bind(middleClick),
                        bind(scrollUp),
                        bind(scrollDown),
                        bind(options.bar.scrollSpeed),
                    ],
                    () => {
                        disconnectFunctions.forEach((disconnect) => disconnect());
                        disconnectFunctions = [];

                        const throttledHandler = throttledScrollHandler(options.bar.scrollSpeed.get());

                        disconnectFunctions.push(
                            onPrimaryClick(self, (clicked, event) => {
                                openDropdownMenu(clicked, event, 'dashboardmenu');
                            }),
                        );

                        disconnectFunctions.push(
                            onSecondaryClick(self, (clicked, event) => {
                                runAsyncCommand(rightClick.get(), { clicked, event });
                            }),
                        );

                        disconnectFunctions.push(
                            onMiddleClick(self, (clicked, event) => {
                                runAsyncCommand(middleClick.get(), { clicked, event });
                            }),
                        );

                        disconnectFunctions.push(
                            onScroll(self, throttledHandler, scrollUp.get(), scrollDown.get()),
                        );
                    },
                );
            },
        },
    };
};

export { Menu };
