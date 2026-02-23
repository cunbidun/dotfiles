import { bind, Variable } from 'astal';
import AstalWp from 'gi://AstalWp?version=0.1';
import LevelBar from 'src/components/shared/LevelBar';
import options from 'src/configuration';
import BrightnessService from 'src/services/system/brightness';
import { osdContext } from '../state';

const wireplumber = AstalWp.get_default() as AstalWp.Wp;
const audioService = wireplumber.audio;

const brightnessService = BrightnessService.getInstance();

/**
 * Sets up the OSD bar for a LevelBar instance.
 *
 * This function hooks various services and settings to the LevelBar instance to update its value and class name
 * based on the brightness and audio services. It handles screen brightness, keyboard brightness, microphone volume,
 * microphone mute status, speaker volume, and speaker mute status.
 *
 * @param self The LevelBar instance to set up.
 */
export const setupOsdBar = (self: LevelBar): void => {
    const barBinding = Variable.derive(
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
                self.value = brightnessService.screen;
                return;
            }

            if (context === 'keyboard-brightness') {
                self.className = self.className.replace(/\boverflow\b/, '').trim();
                self.value = brightnessService.kbd;
                return;
            }

            self.toggleClassName(
                'overflow',
                audioService.defaultSpeaker.volume > 1 &&
                    (!options.theme.osd.muted_zero.get() || audioService.defaultSpeaker.mute === false),
            );
            self.value =
                options.theme.osd.muted_zero.get() && audioService.defaultSpeaker.mute !== false
                    ? 0
                    : audioService.defaultSpeaker.volume <= 1
                      ? audioService.defaultSpeaker.volume
                      : audioService.defaultSpeaker.volume - 1;
        },
    );

    self.connect('destroy', () => {
        barBinding.drop();
    });
};
