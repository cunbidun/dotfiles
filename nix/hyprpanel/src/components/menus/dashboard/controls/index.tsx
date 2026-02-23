import { Gtk } from 'astal/gtk3';
import {
    AudioControllerCard,
    BrightnessSliderCard,
    BluetoothButton,
    RecordingButton,
    VolumeSliderCard,
    WifiButton,
} from './ControlButtons';
import { recordingPoller } from '../shortcuts/helpers';
import { JSXElement } from 'src/core/types';

export const Controls = ({ isEnabled }: ControlsProps): JSXElement => {
    if (!isEnabled) {
        recordingPoller.stop();
        return null;
    }

    recordingPoller.initialize();

    return (
        <box
            className={'dashboard-card controls-container'}
            halign={Gtk.Align.FILL}
            valign={Gtk.Align.FILL}
            hexpand
            expand
            vertical
        >
            <box className={'dashboard-control-main-row'} hexpand>
                <box className={'dashboard-control-left-column'} vertical>
                    <WifiButton />
                    <BluetoothButton />
                </box>
                <AudioControllerCard />
            </box>
            <box className={'dashboard-control-quick-row'}>
                <RecordingButton />
            </box>
            <BrightnessSliderCard />
            <VolumeSliderCard />
        </box>
    );
};

interface ControlsProps {
    isEnabled: boolean;
}
