import { Gtk } from 'astal/gtk3';
import {
    AudioControllerCard,
    BluetoothButton,
    BrightnessSliderCard,
    CONTROL_CELL,
    CONTROL_GAP,
    CONTROL_TILE,
    ColorPickerButton,
    EmptyPlaceholderButton,
    GammaStepButton,
    InhibitorButton,
    RecordingButton,
    ThemeToggleButton,
    VolumeSliderCard,
    WifiButton,
    gammaStepPoller,
} from './ControlButtons';
import { recordingPoller } from './helpers';
import { JSXElement } from 'src/core/types';

const applyControlRowGapHeight = (widget: Gtk.Widget): void => {
    widget.set_size_request(-1, CONTROL_GAP);
};

const applyLeftColumnSize = (widget: Gtk.Widget): void => {
    widget.set_size_request(CONTROL_TILE, -1);
};

const applyMediaCardSize = (widget: Gtk.Widget): void => {
    widget.set_size_request(CONTROL_CELL * 4 + CONTROL_GAP * 3, -1);
};

export const Controls = ({ isEnabled }: ControlsProps): JSXElement => {
    if (!isEnabled) {
        recordingPoller.stop();
        gammaStepPoller.stop();
        return null;
    }

    recordingPoller.initialize();
    gammaStepPoller.initialize();

    return (
        <box
            className={'dashboard-card controls-container'}
            halign={Gtk.Align.FILL}
            valign={Gtk.Align.FILL}
            hexpand
            expand
            vertical
        >
            <box className={'dashboard-control-main-row'} hexpand spacing={CONTROL_GAP}>
                <box className={'dashboard-control-left-column'} setup={applyLeftColumnSize} vertical>
                    <WifiButton />
                    <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
                    <BluetoothButton />
                </box>
                <box className={'dashboard-control-audio-frame'} setup={applyMediaCardSize}>
                    <AudioControllerCard />
                </box>
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-quick-row'} hexpand homogeneous spacing={CONTROL_GAP}>
                <RecordingButton />
                <ColorPickerButton />
                <InhibitorButton />
                <GammaStepButton />
                <ThemeToggleButton />
                <EmptyPlaceholderButton />
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-slider-row volume'} hexpand>
                <VolumeSliderCard />
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-slider-row brightness'} hexpand>
                <BrightnessSliderCard />
            </box>
        </box>
    );
};

interface ControlsProps {
    isEnabled: boolean;
}
