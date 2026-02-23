import { exec, GObject, property, register } from 'astal';
import { SystemUtilities } from 'src/core/system/SystemUtilities';

const resolveBrightnessCommand = (): string => {
    try {
        return exec(
            "bash -lc 'if [ -n \"$HYPRPANEL_BRIGHTNESS_CONTROL\" ] && [ -x \"$HYPRPANEL_BRIGHTNESS_CONTROL\" ]; then printf \"%s\" \"$HYPRPANEL_BRIGHTNESS_CONTROL\"; elif command -v brightness-control >/dev/null 2>&1; then command -v brightness-control; fi'",
        ).trim();
    } catch {
        return '';
    }
};

const brightnessCommand = resolveBrightnessCommand();
const isBrightnessAvailable = brightnessCommand.length > 0;

const readBrightnessPercent = (): number => {
    if (!isBrightnessAvailable) {
        return 0;
    }

    try {
        const out = exec(
            `bash -lc '"${brightnessCommand}" get 2>/dev/null || "${brightnessCommand}" get json 2>/dev/null || true'`,
        ).trim();

        if (/^\d+$/.test(out)) {
            return Number(out);
        }

        const jsonMatch = out.match(/"percentage"\s*:\s*(\d+)/);
        if (jsonMatch?.[1] !== undefined) {
            return Number(jsonMatch[1]);
        }
    } catch {
        return 0;
    }

    return 0;
};

/**
 * Service for managing brightness via brightness-control.
 */
@register({ GTypeName: 'Brightness' })
export default class BrightnessService extends GObject.Object {
    public static instance: BrightnessService;

    constructor() {
        super();
        this.#syncScreen();
        setInterval(() => this.#syncScreen(), 1500);
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

    #syncScreen(): void {
        if (!isBrightnessAvailable) {
            return;
        }

        const next = Math.max(0, Math.min(100, readBrightnessPercent())) / 100;
        if (Math.abs(next - this.#screen) >= 0.001) {
            this.#screen = next;
            this.notify('screen');
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

        const cmd = delta > 0 ? 'increase' : 'decrease';
        const amount = Math.abs(delta);

        SystemUtilities.bash`"${brightnessCommand}" ${cmd} ${amount}`.then(() => {
            this.#syncScreen();
        });
    }
}
