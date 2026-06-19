import { Gtk } from 'astal/gtk3';
import {
    AudioControllerCard,
    BluetoothButton,
    BrightnessSliderCard,
    CONTROL_GAP,
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

const applyControlRowGapHeight = (widget: Gtk.Widget): void => {
    widget.set_size_request(-1, CONTROL_GAP);
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
            <box className={'dashboard-control-main-row'} hexpand homogeneous spacing={CONTROL_GAP}>
                <box className={'dashboard-control-left-column'} vertical hexpand>
                    <WifiButton />
                    <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
                    <BluetoothButton />
                </box>
                <AudioControllerCard />
            </box>
            <box className={'dashboard-control-row-gap'} setup={applyControlRowGapHeight} />
            <box className={'dashboard-control-quick-row'} hexpand homogeneous spacing={CONTROL_GAP}>
                <RecordingButton />
                <ColorPickerButton />
                <InhibitorButton />
                <GammaStepButton />
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
