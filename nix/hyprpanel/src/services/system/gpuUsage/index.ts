import { bind, exec, Variable } from 'astal';
import { FunctionPoller } from 'src/lib/poller/FunctionPoller';
import { GpuServiceCtor } from './types';

const resolveRocmSmiCommand = (): string => {
    try {
        const detected = exec("bash -lc 'command -v rocm-smi || true'").trim();
        if (detected.length > 0) {
            return detected;
        }
    } catch {
        // Fall through to static guesses.
    }

    try {
        const user = exec("bash -lc 'printf %s \"${USER:-}\"'").trim();
        const guesses = [
            user ? `/etc/profiles/per-user/${user}/bin/rocm-smi` : '',
            '/run/current-system/sw/bin/rocm-smi',
        ].filter((path) => path.length > 0);

        for (const guess of guesses) {
            const exists = exec(`bash -lc 'test -x "${guess}" && echo yes || true'`).trim();
            if (exists === 'yes') {
                return guess;
            }
        }
    } catch {
        return '';
    }

    return '';
};

const rocmSmiCommand = resolveRocmSmiCommand();

/**
 * Service for monitoring GPU usage percentage using ROCm SMI.
 */
class GpuUsageService {
    private _updateFrequency: Variable<number>;
    private _gpuPoller: FunctionPoller<number, []>;
    private _isInitialized = false;

    public _gpu = Variable<number>(0);

    constructor({ frequency }: GpuServiceCtor = {}) {
        this._updateFrequency = frequency ?? Variable(2000);
        this._calculateUsage = this._calculateUsage.bind(this);

        this._gpuPoller = new FunctionPoller<number, []>(
            this._gpu,
            [],
            bind(this._updateFrequency),
            this._calculateUsage,
        );
    }

    /**
     * Manually refreshes the GPU usage reading
     */
    public refresh(): void {
        this._gpu.set(this._calculateUsage());
    }

    /**
     * Gets the GPU usage percentage variable
     *
     * @returns Variable containing GPU usage percentage (0-1)
     */
    public get gpu(): Variable<number> {
        return this._gpu;
    }

    /**
     * Calculates average GPU usage across all available GPUs.
     *
     * @returns GPU usage as a decimal between 0 and 1
     */
    private _calculateUsage(): number {
        try {
            if (!rocmSmiCommand) {
                return 0;
            }

            const output = exec(`"${rocmSmiCommand}" --showuse --json`);
            if (typeof output !== 'string') {
                return 0;
            }

            const jsonLine = output
                .split('\n')
                .map((line) => line.trim())
                .find((line) => line.startsWith('{') && line.endsWith('}'));
            if (!jsonLine) {
                return 0;
            }

            const data = JSON.parse(jsonLine) as Record<string, Record<string, string | number>>;
            const cards = Object.values(data);
            if (!cards.length) {
                return 0;
            }

            const usageValues = cards
                .map((card) => Number(card['GPU use (%)']))
                .filter((value) => Number.isFinite(value));
            if (!usageValues.length) {
                return 0;
            }

            const usedGpu = usageValues.reduce((acc, value) => acc + value, 0) / usageValues.length;

            return this._percentToDecimal(usedGpu);
        } catch (error) {
            if (error instanceof Error) {
                console.error('Error getting GPU stats:', error.message);
            } else {
                console.error('Unknown error getting GPU stats');
            }
            return 0;
        }
    }

    /**
     * Converts usage percentage [0..100] to decimal [0..1].
     */
    private _percentToDecimal(percent: number): number {
        const clamped = Math.max(0, Math.min(100, percent));
        return clamped / 100;
    }

    /**
     * Updates the polling frequency
     *
     * @param timerInMs - New polling interval in milliseconds
     */
    public updateTimer(timerInMs: number): void {
        this._updateFrequency.set(timerInMs);
    }

    /**
     * Initializes the GPU usage monitoring poller
     */
    public initialize(): void {
        if (!this._isInitialized) {
            this._gpuPoller.initialize();
            this._isInitialized = true;
        }
    }

    /**
     * Stops the GPU usage polling
     */
    public stopPoller(): void {
        this._gpuPoller.stop();
    }

    /**
     * Starts the GPU usage polling
     */
    public startPoller(): void {
        this._gpuPoller.start();
    }

    /**
     * Cleans up resources and stops monitoring
     */
    public destroy(): void {
        this._gpuPoller.stop();
        this._gpu.drop();
        this._updateFrequency.drop();
    }
}

export default GpuUsageService;
