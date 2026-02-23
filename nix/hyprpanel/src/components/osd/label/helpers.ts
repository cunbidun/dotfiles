import { bind, Variable } from 'astal';
import { Widget } from 'astal/gtk3';
import AstalWp from 'gi://AstalWp?version=0.1';
import options from 'src/configuration';
import BrightnessService from 'src/services/system/brightness';
import { osdContext } from '../state';

const wireplumber = AstalWp.get_default() as AstalWp.Wp;
const audioService = wireplumber.audio;
const brightnessService = BrightnessService.getInstance();

/**
 * Sets up the OSD label for a given widget.
 *
 * This function hooks various services and settings to the widget to update its label based on the brightness and audio services.
 * It handles screen brightness, keyboard brightness, microphone volume, microphone mute status, speaker volume, and speaker mute status.
 *
 * @param self The Widget.Label instance to set up.
 */
export const setupOsdLabel = (self: Widget.Label): void => {
    const labelBinding = Variable.derive(
        [
            bind(osdContext),
            bind(brightnessService, 'screen'),
            bind(brightnessService, 'kbd'),
            bind(audioService.defaultSpeaker, 'volume'),
            bind(audioService.defaultSpeaker, 'mute'),
        ],
        (context) => {
            if (context === 'brightness') {
                self.className = self.className.replace(/\boverflow\b/, '').trim();
                self.label = `${Math.round(brightnessService.screen * 100)}`;
                return;
            }

            if (context === 'keyboard-brightness') {
                self.className = self.className.replace(/\boverflow\b/, '').trim();
                self.label = `${Math.round(brightnessService.kbd * 100)}`;
                return;
            }

            self.toggleClassName(
                'overflow',
                audioService.defaultSpeaker.volume > 1 &&
                    (!options.theme.osd.muted_zero.value || audioService.defaultSpeaker.mute === false),
            );
            const speakerVolume =
                options.theme.osd.muted_zero.value && audioService.defaultSpeaker.mute !== false
                    ? 0
                    : Math.round(audioService.defaultSpeaker.volume * 100);
            self.label = `${speakerVolume}`;
        },
    );

    self.connect('destroy', () => {
        labelBinding.drop();
    });
};
