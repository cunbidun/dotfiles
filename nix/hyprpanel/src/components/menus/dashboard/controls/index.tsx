import { Gtk } from 'astal/gtk3';
import {
    AudioControllerCard,
    BluetoothButton,
    BrightnessSliderCard,
    CONTROL_GAP,
    CONTROL_TILE,
    CONTROL_TOTAL,
    ColorPickerButton,
    GammaStepButton,
    InhibitorButton,
    RecordingButton,
    VolumeSliderCard,
    WifiButton,
    gammaStepPoller,
} from './ControlButtons';
import { recordingPoller } from './helpers';
import { JSXElement } from 'src/core/types';

const applyControlColumnWidth = (widget: Gtk.Widget): void => {
    widget.set_size_request(CONTROL_TILE, -1);
};

const applyControlGapWidth = (widget: Gtk.Widget): void => {
    widget.set_size_request(CONTROL_GAP, -1);
};

const applyControlRowGapHeight = (widget: Gtk.Widget): void => {
    widget.set_size_request(-1, CONTROL_GAP);
};

const applyControlsRowWidth = (widget: Gtk.Widget): void => {
    widget.set_size_request(CONTROL_TOTAL, -1);
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
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.FILL}
            hexpand={false}
            expand
            vertical
        >
            <box className={'dashboard-control-main-row'} hexpand={false} setup={applyControlsRowWidth}>
                <box
                    className={'dashboard-control-left-column'}
                    vertical
                    hexpand={false}
                    setup={applyControlColumnWidth}
                >
                    <WifiButton />
                    <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
                    <BluetoothButton />
                </box>
                <box className={'dashboard-control-gap'} setup={applyControlGapWidth} />
                <AudioControllerCard />
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-quick-row'} hexpand={false} setup={applyControlsRowWidth}>
                <RecordingButton />
                <box className={'dashboard-control-gap'} setup={applyControlGapWidth} />
                <ColorPickerButton />
                <box className={'dashboard-control-gap'} setup={applyControlGapWidth} />
                <InhibitorButton />
                <box className={'dashboard-control-gap'} setup={applyControlGapWidth} />
                <GammaStepButton />
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-slider-row volume'} hexpand={false} setup={applyControlsRowWidth}>
                <VolumeSliderCard />
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-slider-row brightness'} hexpand={false} setup={applyControlsRowWidth}>
                <BrightnessSliderCard />
            </box>
        </box>
    );
};

interface ControlsProps {
    isEnabled: boolean;
}
