import { Gtk } from 'astal/gtk3';
import { SystemUtilities } from 'src/core/system/SystemUtilities';
import { BrightnessHeader } from './Header';
import { BrightnessIcon } from './Icon';
import { BrightnessPercentage } from './Percentage';
import { BrightnessSlider } from './Slider';

const canAdjustBrightness =
    SystemUtilities.runCommand(
        'bash -lc \'[ -n "$HYPRPANEL_BRIGHTNESS_CONTROL" ] && [ -x "$HYPRPANEL_BRIGHTNESS_CONTROL" ] || command -v brightness-control >/dev/null 2>&1\'',
    ).exitCode === 0;

const Brightness = (): JSX.Element => {
    if (!canAdjustBrightness) {
        return (
            <box className={'menu-section-container brightness unavailable'} vertical>
                <BrightnessHeader />
                <box className={'menu-items-section'} valign={Gtk.Align.FILL} vexpand vertical>
                    <label className={'dim'} hexpand label={'brightness-control is missing'} />
                </box>
            </box>
        );
    }

    return (
        <box className={'menu-section-container brightness'} vertical>
            <BrightnessHeader />
            <box className={'menu-items-section'} valign={Gtk.Align.FILL} vexpand vertical>
                <box className={'brightness-container'}>
                    <BrightnessIcon />
                    <BrightnessSlider />
                    <BrightnessPercentage />
                </box>
            </box>
        </box>
    );
};

export { Brightness };
