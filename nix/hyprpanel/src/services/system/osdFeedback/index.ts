import { bind, timeout, Variable } from 'astal';
import AstalWp from 'gi://AstalWp?version=0.1';
import BrightnessService from 'src/services/system/brightness';
import { pulseBarLauncherIcon, setOsdContext } from 'src/components/osd/state';

const FEEDBACK_MS = 500;

class OsdFeedbackService {
    private static _instance: OsdFeedbackService;
    private readonly _brightnessService = BrightnessService.getInstance();
    private readonly _audioService = (AstalWp.get_default() as AstalWp.Wp).audio;
    private _speakerBinding: Variable<void> | null = null;
    private _initialized = false;
    private _speakerFeedbackReady = false;
    private _lastSpeakerVolume: number | null = null;
    private _lastSpeakerMute: boolean | null = null;

    public static getInstance(): OsdFeedbackService {
        if (!OsdFeedbackService._instance) {
            OsdFeedbackService._instance = new OsdFeedbackService();
        }
        return OsdFeedbackService._instance;
    }

    public initialize(): void {
        if (this._initialized) {
            return;
        }

        this._initialized = true;
        timeout(1200, () => {
            this._speakerFeedbackReady = true;
        });

        this._brightnessService.connect('notify::screen', () => {
            setOsdContext('brightness');
            pulseBarLauncherIcon(FEEDBACK_MS);
        });

        this._brightnessService.connect('notify::kbd', () => {
            setOsdContext('keyboard-brightness');
            pulseBarLauncherIcon(FEEDBACK_MS);
        });

        this._speakerBinding = Variable.derive(
            [bind(this._audioService.defaultSpeaker, 'volume'), bind(this._audioService.defaultSpeaker, 'mute')],
            () => {
                const speaker = this._audioService.defaultSpeaker;
                const volume = speaker?.volume ?? 0;
                const mute = speaker?.mute ?? false;

                const hadPrevious = this._lastSpeakerVolume !== null && this._lastSpeakerMute !== null;
                const changed =
                    !hadPrevious ||
                    Math.abs((this._lastSpeakerVolume as number) - volume) > 0.0001 ||
                    (this._lastSpeakerMute as boolean) !== mute;

                this._lastSpeakerVolume = volume;
                this._lastSpeakerMute = mute;

                if (!this._speakerFeedbackReady || !changed) {
                    return;
                }

                setOsdContext('volume');
                pulseBarLauncherIcon(FEEDBACK_MS);
            },
        );
    }
}

export default OsdFeedbackService.getInstance();
