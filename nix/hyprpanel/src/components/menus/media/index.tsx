import { bind, Binding, Variable } from 'astal';
import DropdownMenu from '../shared/dropdown/index.js';
import options from 'src/configuration';
import { MediaContainer } from './components/MediaContainer.js';
import { MediaInfo } from './components/title/index.js';
import { MediaControls } from './components/controls/index.js';
import { MediaSlider } from './components/timebar/index.js';
import { MediaTimeStamp } from './components/timelabel/index.js';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import { App, Gtk } from 'astal/gtk3';
import { mediaArtist, mediaTitle } from 'src/services/media';
import { isPrimaryClick } from 'src/lib/events/mouse';

const { transition } = options.menus;

type MediaPage = 'main' | 'playback';

const page: Variable<MediaPage> = Variable('main');

const goToPage = (target: MediaPage) => page.set(target);

const resetPageWhenClosed = (): void => {
    App.connect('window-toggled', (_, window) => {
        if (window.name === 'mediamenu' && !window.visible) {
            goToPage('main');
        }
    });
};

const MediaHeader = ({ title }: { title: string }): JSX.Element => (
    <box className="mac-popover-header media-drilldown-header" halign={Gtk.Align.FILL}>
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

const DrilldownRow = ({ title, subtitle, target }: DrilldownRowProps): JSX.Element => (
    <button
        className="mac-popover-row media-drilldown-row"
        onClick={(_, event) => {
            if (isPrimaryClick(event)) {
                goToPage(target);
            }
        }}
    >
        <box className="mac-popover-row-content" halign={Gtk.Align.FILL} hexpand>
            <label className="mac-popover-row-icon txt-icon" label="󰎆" />
            <box className="mac-popover-row-copy" vertical hexpand>
                <label className="mac-popover-row-title" halign={Gtk.Align.START} label={title} />
                <label className="mac-popover-row-subtitle" halign={Gtk.Align.START} truncate label={subtitle} />
            </box>
            <label className="mac-popover-row-chevron txt-icon" label="›" />
        </box>
    </button>
);

const MediaMainPage = (): JSX.Element => (
    <box name="main" className="mac-popover-page media-main" vertical>
        <MediaInfo />
        <MediaControls />
        <DrilldownRow
            title="Playback"
            subtitle={bind(mediaArtist).as((artist) => (artist && artist !== '-----' ? artist : 'Controls and timeline'))}
            target="playback"
        />
    </box>
);

const MediaPlaybackPage = (): JSX.Element => (
    <box name="playback" className="mac-popover-page mac-popover-child-page media-playback-page" vertical>
        <MediaHeader title="Playback" />
        <box className="mac-popover-child-content media-playback-content" vertical>
            <label
                className="mac-popover-title media-playback-title"
                halign={Gtk.Align.START}
                truncate
                label={bind(mediaTitle).as((title) => (title && title !== '-----' ? title : 'Not Playing'))}
            />
            <MediaControls />
            <MediaSlider />
            <MediaTimeStamp />
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
            name="mediamenu"
            transition={bind(transition).as((transition) => RevealerTransitionMap[transition])}
        >
            <MediaContainer className="mac-popover-container">
                <stack
                    className="mac-popover-stack"
                    setup={resetPageWhenClosed}
                    visibleChildName={bind(page)}
                    transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
                    transitionDuration={bind(options.menus.transitionTime)}
                >
                    <MediaMainPage />
                    <MediaPlaybackPage />
                </stack>
            </MediaContainer>
        </DropdownMenu>
    );
};

interface DrilldownRowProps {
    title: string;
    subtitle: string | Binding<string>;
    target: MediaPage;
}
