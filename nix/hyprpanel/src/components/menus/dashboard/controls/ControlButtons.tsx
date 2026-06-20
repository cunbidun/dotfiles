import { bind, Variable } from 'astal';
import { App, Gdk, Gtk } from 'astal/gtk3';
import AstalBluetooth from 'gi://AstalBluetooth?version=0.1';
import AstalMpris from 'gi://AstalMpris?version=0.1';
import AstalNetwork from 'gi://AstalNetwork?version=0.1';
import AstalWp from 'gi://AstalWp?version=0.1';
import { openDashboardSubMenu } from 'src/components/bar/utils/menu';
import options from 'src/configuration';
import icons from 'src/lib/icons/icons';
import { isPrimaryClick } from 'src/lib/events/mouse';
import { activePlayer, canGoNext, canGoPrevious, mediaArtist, mediaTitle, playbackStatus } from 'src/services/media';
import BrightnessService from 'src/services/system/brightness';
import { BashPoller } from 'src/lib/poller/BashPoller';
import { executeCommand, getRecordingPath, isRecording, isWifiEnabled } from './helpers';
import { idleInhibit } from 'src/lib/window/visibility';

const wireplumber = AstalWp.get_default() as AstalWp.Wp;
const audioService = wireplumber.audio;
const networkService = AstalNetwork.get_default();
const bluetoothService = AstalBluetooth.get_default();
const brightnessService = BrightnessService.getInstance();
const { raiseMaximumVolume } = options.menus.volume;
const hyprsunsetPollingInterval = Variable(2000);
const colorPickerShortcut = options.menus.dashboard.shortcuts.right.shortcut1;
const isAudioOutputSelectorOpen = Variable(false);
export const CONTROL_CELL = 56;
export const CONTROL_GAP = 9;
export const CONTROL_TILE = (CONTROL_CELL * 2) + CONTROL_GAP;
const CONTROL_TITLE_MAX_CHARS = 12;
const CONTROL_SUBTITLE_MAX_CHARS = 14;

const wifiSubtitle = Variable.derive(
    [bind(isWifiEnabled), bind(networkService, 'state'), bind(networkService, 'connectivity')],
    (enabled) => {
        if (!enabled) {
            return 'Off';
        }

        const ssid = networkService.wifi?.ssid;
        if (ssid && ssid.trim().length > 0) {
            return ssid;
        }

        return 'Connected';
    },
);

const bluetoothSubtitle = Variable.derive(
    [bind(bluetoothService, 'isPowered'), bind(bluetoothService, 'devices'), bind(bluetoothService, 'isConnected')],
    (isPowered, devices) => {
        if (!isPowered) {
            return 'Off';
        }

        const connected = devices.filter((device) => device.connected).length;
        if (connected > 0) {
            return `Connected (${connected})`;
        }

        return 'On';
    },
);

export const WifiButton = (): JSX.Element => {
    return (
        <button
            className={bind(isWifiEnabled).as(
                (isEnabled) => `dashboard-control-tile wifi ${!isEnabled ? 'disabled' : ''}`,
            )}
            onButtonPressEvent={(_, event) => {
                if (event.get_button()[1] !== Gdk.BUTTON_PRIMARY) return;
                void openDashboardSubMenu('networkmenu');
            }}
            hexpand
        >
            <box className={'dashboard-control-tile-content'} valign={Gtk.Align.FILL} vexpand>
                <label
                    className={'txt-icon control-tile-icon'}
                    valign={Gtk.Align.CENTER}
                    label={bind(isWifiEnabled).as((isEnabled) => (isEnabled ? '󰤨' : '󰤭'))}
                />
                <box className={'control-tile-copy'} halign={Gtk.Align.FILL} hexpand vertical>
                    <label
                        className={'control-tile-title'}
                        halign={Gtk.Align.START}
                        label={'Wi-Fi'}
                        truncate
                        maxWidthChars={CONTROL_TITLE_MAX_CHARS}
                    />
                    <label
                        className={'control-tile-subtitle'}
                        halign={Gtk.Align.START}
                        label={bind(wifiSubtitle)}
                        truncate
                        maxWidthChars={CONTROL_SUBTITLE_MAX_CHARS}
                    />
                </box>
            </box>
        </button>
    );
};

export const BluetoothButton = (): JSX.Element => {
    return (
        <button
            className={bind(bluetoothService, 'isPowered').as(
                (isEnabled) => `dashboard-control-tile bluetooth ${!isEnabled ? 'disabled' : ''}`,
            )}
            onButtonPressEvent={(_, event) => {
                if (event.get_button()[1] !== Gdk.BUTTON_PRIMARY) return;
                void openDashboardSubMenu('bluetoothmenu');
            }}
            hexpand
        >
            <box className={'dashboard-control-tile-content'} valign={Gtk.Align.FILL} vexpand>
                <label
                    className={'txt-icon control-tile-icon'}
                    valign={Gtk.Align.CENTER}
                    label={bind(bluetoothService, 'isPowered').as((isEnabled) => (isEnabled ? '󰂯' : '󰂲'))}
                />
                <box className={'control-tile-copy'} halign={Gtk.Align.FILL} hexpand vertical>
                    <label
                        className={'control-tile-title'}
                        halign={Gtk.Align.START}
                        label={'Bluetooth'}
                        truncate
                        maxWidthChars={CONTROL_TITLE_MAX_CHARS}
                    />
                    <label
                        className={'control-tile-subtitle'}
                        halign={Gtk.Align.START}
                        label={bind(bluetoothSubtitle)}
                        truncate
                        maxWidthChars={CONTROL_SUBTITLE_MAX_CHARS}
                    />
                </box>
            </box>
        </button>
    );
};

const audioPlaybackIcon = bind(playbackStatus).as((status) => {
    if (status === AstalMpris.PlaybackStatus.PLAYING) {
        return icons.mpris.playing;
    }

    return icons.mpris.paused;
});

const audioSubtitle = Variable.derive([bind(mediaArtist), bind(audioService.defaultSpeaker, 'volume')], (artist, volume) => {
    if (artist && artist.trim().length > 0 && artist !== '-----') {
        return artist;
    }

    return `Volume ${Math.round(volume * 100)}%`;
});

export const AudioControllerCard = (): JSX.Element => {
    return (
        <box className={'dashboard-control-audio-card'} hexpand vertical>
            <button
                className={'dashboard-control-audio-header'}
                onButtonPressEvent={(_, event) => {
                    if (event.get_button()[1] !== Gdk.BUTTON_PRIMARY) return;
                    void openDashboardSubMenu('mediamenu');
                }}
            >
                <box className={'dashboard-control-audio-header-content'} hexpand>
                    <label
                        className={'txt-icon dashboard-control-audio-icon'}
                        label={bind(audioService.defaultSpeaker, 'mute').as((isMuted) => (isMuted ? '󰖁' : '󰕾'))}
                    />
                    <box className={'dashboard-control-audio-copy'} hexpand vertical>
                        <label
                            className={'dashboard-control-audio-title'}
                            halign={Gtk.Align.START}
                            label={bind(mediaTitle).as((title) => (title && title.trim().length > 0 ? title : 'Audio'))}
                            truncate
                        />
                        <label
                            className={'dashboard-control-audio-subtitle'}
                            halign={Gtk.Align.START}
                            label={bind(audioSubtitle)}
                            truncate
                        />
                    </box>
                </box>
            </button>

            <box className={'dashboard-control-audio-controls'} homogeneous>
                <button
                    className={bind(canGoPrevious).as(
                        (enabled) => `dashboard-control-audio-control ${enabled ? 'enabled' : 'disabled'}`,
                    )}
                    onButtonPressEvent={(_, event) => {
                        if (event.get_button()[1] !== Gdk.BUTTON_PRIMARY) return;

                        const player = activePlayer.get();
                        if (player && player.can_go_previous) {
                            player.previous();
                        }
                    }}
                    hexpand
                >
                    <icon icon={icons.mpris.prev} />
                </button>

                <button
                    className={'dashboard-control-audio-control enabled playpause'}
                    onButtonPressEvent={(_, event) => {
                        if (event.get_button()[1] !== Gdk.BUTTON_PRIMARY) return;

                        const player = activePlayer.get();
                        if (player && player.can_play) {
                            player.play_pause();
                        }
                    }}
                    hexpand
                >
                    <icon icon={audioPlaybackIcon} />
                </button>

                <button
                    className={bind(canGoNext).as(
                        (enabled) => `dashboard-control-audio-control ${enabled ? 'enabled' : 'disabled'}`,
                    )}
                    onButtonPressEvent={(_, event) => {
                        if (event.get_button()[1] !== Gdk.BUTTON_PRIMARY) return;

                        const player = activePlayer.get();
                        if (player && player.can_go_next) {
                            player.next();
                        }
                    }}
                    hexpand
                >
                    <icon icon={icons.mpris.next} />
                </button>
            </box>
        </box>
    );
};

export const RecordingButton = (): JSX.Element => {
    return (
        <button
            className={bind(isRecording).as(
                (recording) => `dashboard-control-chip recording ${recording ? 'active' : ''}`,
            )}
            onClick={(_, event) => {
                if (!isPrimaryClick(event)) return;

                const sanitizedPath = getRecordingPath().replace(/"/g, '\\"');

                App.get_window('dashboardmenu')?.set_visible(false);

                if (isRecording.get()) {
                    executeCommand(`${SRC_DIR}/scripts/screen_record.sh stop "${sanitizedPath}"`);
                    return;
                }

                executeCommand(`${SRC_DIR}/scripts/screen_record.sh start region "${sanitizedPath}"`);
            }}
            hexpand
        >
            <box className={'dashboard-control-chip-content'} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                <label className={'txt-icon'} label={'󰑊'} />
            </box>
        </button>
    );
};

export const isGammaStepEnabled = Variable(false);

export const gammaStepPoller = new BashPoller<boolean, []>(
    isGammaStepEnabled,
    [],
    bind(hyprsunsetPollingInterval),
    'systemctl --user is-active hyprsunset.service >/dev/null && echo active || echo inactive',
    (output) => output.trim() === 'active',
);

export const GammaStepButton = (): JSX.Element => {
    return (
        <button
            className={bind(isGammaStepEnabled).as((enabled) => `dashboard-control-chip gammastep ${enabled ? 'active' : ''}`)}
            onClick={(_, event) => {
                if (!isPrimaryClick(event)) return;

                const enabled = isGammaStepEnabled.get();
                const command = enabled
                    ? 'systemctl --user stop hyprsunset.service'
                    : 'systemctl --user start hyprsunset.service';
                executeCommand(command);
                isGammaStepEnabled.set(!enabled);
            }}
            hexpand
        >
            <box className={'dashboard-control-chip-content'} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                <label
                    className={'txt-icon'}
                    label={bind(isGammaStepEnabled).as((enabled) => (enabled ? '󰖔' : '󰖨'))}
                />
            </box>
        </button>
    );
};

export const InhibitorButton = (): JSX.Element => {
    return (
        <button
            className={bind(idleInhibit).as((enabled) => `dashboard-control-chip inhibitor ${enabled ? 'active' : ''}`)}
            onClick={(_, event) => {
                if (!isPrimaryClick(event)) return;
                idleInhibit.set(!idleInhibit.get());
            }}
            hexpand
        >
            <box className={'dashboard-control-chip-content'} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                <label className={'txt-icon'} label={bind(idleInhibit).as((enabled) => (enabled ? '󰅶' : '󰾪'))} />
            </box>
        </button>
    );
};

export const ColorPickerButton = (): JSX.Element => {
    return (
        <button
            className={'dashboard-control-chip colorpicker'}
            onClick={(_, event) => {
                if (!isPrimaryClick(event)) return;

                App.get_window('dashboardmenu')?.set_visible(false);
                executeCommand(colorPickerShortcut.command.get());
            }}
            hexpand
        >
            <box className={'dashboard-control-chip-content'} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                <label className={'txt-icon'} label={bind(colorPickerShortcut.icon)} />
            </box>
        </button>
    );
};

export const BrightnessSliderCard = (): JSX.Element => {
    return (
        <box className={'dashboard-control-slider brightness'} hexpand vertical>
            <box>
                <label className={'txt-icon dashboard-control-slider-icon'} label={'󰃠'} />
                <label className={'dashboard-control-slider-title'} hexpand label={'Display'} />
                <label
                    className={'dashboard-control-slider-value'}
                    label={bind(brightnessService, 'screen').as((screenBrightness) => {
                        return `${Math.round(screenBrightness * 100)}%`;
                    })}
                />
            </box>
            <slider
                className={'menu-slider dashboard-control-slider-track brightness'}
                value={bind(brightnessService, 'screen')}
                onDragged={({ value, dragging }) => {
                    if (dragging) {
                        brightnessService.screen = value;
                    }
                }}
                drawValue={false}
                hexpand
                min={0}
                max={1}
            />
        </box>
    );
};

const AudioOutputButton = ({ device }: AudioOutputButtonProps): JSX.Element => {
    return (
        <button
            className={bind(device, 'isDefault').as(
                (isDefault) => `dashboard-audio-output-button ${isDefault ? 'active' : ''}`,
            )}
            onClick={(_, event) => {
                if (!isPrimaryClick(event)) return;
                device.set_is_default(true);
            }}
            hexpand
        >
            <box className={'dashboard-audio-output-content'} hexpand>
                <label className={'txt-icon dashboard-audio-output-icon'} label={''} />
                <label
                    className={'dashboard-audio-output-name'}
                    halign={Gtk.Align.START}
                    hexpand
                    truncate
                    label={bind(device, 'description')}
                />
                <label
                    className={'txt-icon dashboard-audio-output-check'}
                    label={bind(device, 'isDefault').as((isDefault) => (isDefault ? '' : ''))}
                />
            </box>
        </button>
    );
};

const AudioOutputSelector = (): JSX.Element => {
    return (
        <box className={'dashboard-audio-output-selector'} vertical>
            <box className={'dashboard-audio-output-header'}>
                <label className={'dashboard-audio-output-title'} halign={Gtk.Align.START} hexpand label={'Output'} />
            </box>
            <box className={'dashboard-audio-output-list'} vertical>
                {bind(audioService, 'speakers').as((devices) => {
                    if (devices === null || devices.length === 0) {
                        return <label className={'dashboard-audio-output-empty'} label={'No output devices'} />;
                    }

                    return devices
                        .slice()
                        .sort((a, b) => a.description.localeCompare(b.description))
                        .map((device) => <AudioOutputButton device={device} />);
                })}
            </box>
        </box>
    );
};

export const VolumeSliderCard = (): JSX.Element => {
    return (
        <box className={'dashboard-control-slider volume'} hexpand vertical>
            <button
                className={bind(isAudioOutputSelectorOpen).as(
                    (isOpen) => `dashboard-control-slider-header volume ${isOpen ? 'active' : ''}`,
                )}
                onClick={(_, event) => {
                    if (!isPrimaryClick(event)) return;
                    isAudioOutputSelectorOpen.set(!isAudioOutputSelectorOpen.get());
                }}
            >
                <box hexpand>
                    <label
                        className={'txt-icon dashboard-control-slider-icon'}
                        label={bind(audioService.defaultSpeaker, 'mute').as((isMuted) => (isMuted ? '󰖁' : '󰕾'))}
                    />
                    <label className={'dashboard-control-slider-title'} hexpand label={'Sound'} />
                    <label
                        className={'dashboard-control-slider-value'}
                        label={bind(audioService.defaultSpeaker, 'volume').as((volume) => {
                            return `${Math.round(volume * 100)}%`;
                        })}
                    />
                    <label
                        className={'txt-icon dashboard-control-slider-disclosure'}
                        label={bind(isAudioOutputSelectorOpen).as((isOpen) => (isOpen ? '' : ''))}
                    />
                </box>
            </button>
            <slider
                value={bind(audioService.defaultSpeaker, 'volume')}
                className={'menu-slider dashboard-control-slider-track volume'}
                drawValue={false}
                hexpand
                min={0}
                max={bind(raiseMaximumVolume).as((raise) => (raise ? 1.5 : 1))}
                onDragged={({ value, dragging }) => {
                    if (dragging) {
                        audioService.defaultSpeaker.set_volume(value);
                        audioService.defaultSpeaker.set_mute(false);
                    }
                }}
            />
            <revealer revealChild={bind(isAudioOutputSelectorOpen)} transitionDuration={160}>
                <AudioOutputSelector />
            </revealer>
        </box>
    );
};

interface AudioOutputButtonProps {
    device: AstalWp.Endpoint;
}
