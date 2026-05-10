import { exec, GObject, property, register } from 'astal';
import { Gio, monitorFile } from 'astal/file';
import { SystemUtilities } from 'src/core/system/SystemUtilities';

const resolveBrightnessCommand = (): string => {
    try {
        return exec("bash -lc 'command -v brightnessctl || true'").trim();
    } catch {
        return '';
    }
};

const brightnessCommand = resolveBrightnessCommand();
const isBrightnessAvailable = brightnessCommand.length > 0;
const DEBUG_TAG = '[hyprpanel-brightness]';

type BrightnessState = {
    percent: number;
    path: string;
};

const readBrightnessState = (): BrightnessState => {
    if (!isBrightnessAvailable) {
        return { percent: 0, path: '' };
    }

    try {
        const out = exec(`bash -lc '"${brightnessCommand}" -m 2>/dev/null || true'`).trim();
        const fields = out.split(',');
        if (fields.length >= 4) {
            const device = fields[0]?.trim() ?? '';
            const deviceClass = fields[1]?.trim() ?? '';
            const percent = fields[3]?.replace('%', '').trim() ?? '';
            if (device.length > 0 && deviceClass === 'backlight' && /^\d+$/.test(percent)) {
                return {
                    percent: Number(percent),
                    path: `/sys/class/backlight/${device}/brightness`,
                };
            }
        }
    } catch {
        return { percent: 0, path: '' };
    }

    return { percent: 0, path: '' };
};

const readBrightnessPercent = (): number => {
    return readBrightnessState().percent;
};

/**
 * Service for managing brightness via brightnessctl.
 */
@register({ GTypeName: 'Brightness' })
export default class BrightnessService extends GObject.Object {
    public static instance: BrightnessService;

    constructor() {
        super();
        console.log(`${DEBUG_TAG} init: available=${isBrightnessAvailable} cmd="${brightnessCommand}"`);
        this.#syncScreen();
        setInterval(() => this.#syncScreen(), 1000);
    }

    /**
     * Gets the singleton instance of BrightnessService
     *
     * @returns The BrightnessService instance
     */
    public static getInstance(): BrightnessService {
        if (BrightnessService.instance === undefined) {
            BrightnessService.instance = new BrightnessService();
        }
        return BrightnessService.instance;
    }

    #kbdMax = 0;
    #kbd = 0;
    #screen = isBrightnessAvailable ? readBrightnessPercent() / 100 : 0;
    #screenPath = '';
    #screenMonitor: Gio.FileMonitor | null = null;

    #syncScreen(): void {
        if (!isBrightnessAvailable) {
            return;
        }

        const state = readBrightnessState();
        const next = Math.max(0, Math.min(100, state.percent)) / 100;
        if (state.path !== this.#screenPath) {
            this.#screenPath = state.path;
            this.#startScreenMonitor();
        }

        if (Math.abs(next - this.#screen) >= 0.001) {
            console.log(
                `${DEBUG_TAG} screen change: ${Math.round(this.#screen * 100)} -> ${Math.round(next * 100)}`,
            );
            this.#screen = next;
            this.notify('screen');
        }
    }

    #startScreenMonitor(): void {
        this.#screenMonitor?.cancel();
        this.#screenMonitor = null;

        if (this.#screenPath.length === 0) {
            return;
        }

        try {
            this.#screenMonitor = monitorFile(this.#screenPath, () => {
                setTimeout(() => this.#syncScreen(), 25);
            });
            console.log(`${DEBUG_TAG} monitoring ${this.#screenPath}`);
        } catch (error) {
            console.error(`${DEBUG_TAG} failed to monitor ${this.#screenPath}: ${error}`);
        }
    }

    /**
     * Gets the keyboard backlight brightness level
     *
     * @returns The keyboard brightness as a number between 0 and the maximum value
     */
    @property(Number)
    public get kbd(): number {
        return this.#kbd;
    }

    /**
     * Gets the screen brightness level
     *
     * @returns The screen brightness as a percentage (0-1)
     */
    @property(Number)
    public get screen(): number {
        return this.#screen;
    }

    /**
     * Sets the keyboard backlight brightness level
     *
     * @param value - The brightness value to set (0 to maximum)
     */
    public set kbd(value: number) {
        if (value < 0 || value > this.#kbdMax) return;
    }

    /**
     * Sets the screen brightness level
     *
     * @param percent - The brightness percentage to set (0-1)
     */
    public set screen(percent: number) {
        if (!isBrightnessAvailable) return;

        let brightnessPct = percent;

        if (percent < 0) brightnessPct = 0;

        if (percent > 1) brightnessPct = 1;

        const target = Math.round(brightnessPct * 100);
        const current = Math.round(this.#screen * 100);
        const delta = target - current;
        if (delta === 0) return;

        this.#screen = brightnessPct;
        this.notify('screen');

        const amount = Math.abs(delta);
        const adjustArg = delta > 0 ? `+${amount}%` : `${amount}%-`;
        console.log(
            `${DEBUG_TAG} set screen: current=${current} target=${target} arg=${adjustArg}`,
        );
        SystemUtilities.bash`"${brightnessCommand}" set ${adjustArg}`.then(() => {
            this.#syncScreen();
        });
    }
}
