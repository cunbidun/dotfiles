import { bind, Variable } from 'astal';
import { Widget } from 'astal/gtk3';
import AstalWp from 'gi://AstalWp?version=0.1';
import BrightnessService from 'src/services/system/brightness';
import { resolveOsdIcon } from '../iconResolver';
import { osdContext } from '../state';

const wireplumber = AstalWp.get_default() as AstalWp.Wp;
const audioService = wireplumber.audio;
const brightnessService = BrightnessService.getInstance();

/**
 * Sets up the OSD icon for a given widget.
 *
 * This function hooks various services and settings to the widget to update its label based on the brightness and audio services.
 * It handles screen brightness, keyboard brightness, microphone mute status, and speaker mute status.
 *
 * @param self The Widget.Label instance to set up.
 *
 * @returns An object containing the micVariable and speakerVariable, which are derived variables for microphone and speaker status.
 */
export const setupOsdIcon = (self: Widget.Label): void => {
    const iconBinding = Variable.derive(
        [
            bind(osdContext),
            bind(brightnessService, 'screen'),
            bind(brightnessService, 'kbd'),
            bind(audioService.defaultSpeaker, 'volume'),
            bind(audioService.defaultSpeaker, 'mute'),
        ],
        (context) => {
            self.label = resolveOsdIcon({
                context,
                screenBrightness: brightnessService.screen,
                keyboardBrightness: brightnessService.kbd,
                speakerVolume: audioService.defaultSpeaker.volume,
                speakerMuted: audioService.defaultSpeaker.mute,
            });
        },
    );

    self.connect('destroy', () => {
        iconBinding.drop();
    });
};
