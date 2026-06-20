import DropdownMenu from '../shared/dropdown/index.js';
import { VolumeSliders } from './active/index.js';
import { bind, Binding, Variable } from 'astal';
import { App, Gtk } from 'astal/gtk3';
import { PlaybackDevices } from './available/PlaybackDevices.js';
import { InputDevices } from './available/InputDevices.js';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import options from 'src/configuration';
import AstalWp from 'gi://AstalWp?version=0.1';
import { isPrimaryClick } from 'src/lib/events/mouse';

const wireplumber = AstalWp.get_default() as AstalWp.Wp;
const audioService = wireplumber.audio;

type AudioPage = 'main' | 'output' | 'input';

const page: Variable<AudioPage> = Variable('main');

const goToPage = (target: AudioPage) => page.set(target);

const resetPageWhenClosed = (): void => {
    App.connect('window-toggled', (_, window) => {
        if (window.name === 'audiomenu' && !window.visible) {
            goToPage('main');
        }
    });
};

const PageHeader = ({ title }: { title: string }): JSX.Element => (
    <box className="mac-popover-header" halign={Gtk.Align.FILL}>
        <button
            className="mac-popover-back-button"
            onClick={(_, event) => {
                if (isPrimaryClick(event)) {
                    goToPage('main');
                }
            }}
        >
            <label className="txt-icon" label="‹" />
        </button>
        <label className="mac-popover-title" hexpand halign={Gtk.Align.START} label={title} />
    </box>
);

const DrilldownRow = ({ icon, title, subtitle, target }: DrilldownRowProps): JSX.Element => (
    <button
        className="mac-popover-row"
        onClick={(_, event) => {
            if (isPrimaryClick(event)) {
                goToPage(target);
            }
        }}
    >
        <box className="mac-popover-row-content" halign={Gtk.Align.FILL} hexpand>
            <label className="mac-popover-row-icon txt-icon" label={icon} />
            <box className="mac-popover-row-copy" vertical hexpand>
                <label className="mac-popover-row-title" halign={Gtk.Align.START} label={title} />
                <label className="mac-popover-row-subtitle" halign={Gtk.Align.START} truncate label={subtitle} />
            </box>
            <label className="mac-popover-row-chevron txt-icon" label="›" />
        </box>
    </button>
);

const AudioMainPage = (): JSX.Element => (
    <box name="main" className="mac-popover-page audio-main" vertical>
        <label className="mac-popover-title audio-title" halign={Gtk.Align.START} label="Sound" />
        <VolumeSliders />
        <box className="mac-popover-row-group" vertical>
            <DrilldownRow
                icon="󰓃"
                title="Output"
                subtitle={bind(audioService.defaultSpeaker, 'description').as(
                    (description) => description || 'Choose an output device',
                )}
                target="output"
            />
            <DrilldownRow
                icon="󰍬"
                title="Input"
                subtitle={bind(audioService.defaultMicrophone, 'description').as(
                    (description) => description || 'Choose an input device',
                )}
                target="input"
            />
        </box>
    </box>
);

const AudioChildPage = ({ name, title, children }: AudioChildPageProps): JSX.Element => (
    <box name={name} className="mac-popover-page mac-popover-child-page" vertical>
        <PageHeader title={title} />
        <box className="mac-popover-child-content" vertical>
            {children}
        </box>
        <button
            className="mac-popover-body-back-zone"
            vexpand
            onClick={(_, event) => {
                if (isPrimaryClick(event)) {
                    goToPage('main');
                }
            }}
        />
    </box>
);

export default (): JSX.Element => {
    return (
        <DropdownMenu
            name="audiomenu"
            transition={bind(options.menus.transition).as((transition) => RevealerTransitionMap[transition])}
        >
            <box className={'menu-items audio'} halign={Gtk.Align.FILL} hexpand>
                <box
                    className={'menu-items-container audio mac-popover-container'}
                    halign={Gtk.Align.FILL}
                    vertical
                    hexpand
                >
                    <stack
                        className="mac-popover-stack"
                        setup={resetPageWhenClosed}
                        visibleChildName={bind(page)}
                        transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
                        transitionDuration={bind(options.menus.transitionTime)}
                    >
                        <AudioMainPage />
                        <AudioChildPage name="output" title="Output">
                            <PlaybackDevices />
                        </AudioChildPage>
                        <AudioChildPage name="input" title="Input">
                            <InputDevices />
                        </AudioChildPage>
                    </stack>
                </box>
            </box>
        </DropdownMenu>
    );
};

interface DrilldownRowProps {
    icon: string;
    title: string;
    subtitle: string | Binding<string>;
    target: AudioPage;
}

interface AudioChildPageProps {
    name: AudioPage;
    title: string;
    children: JSX.Element;
}
