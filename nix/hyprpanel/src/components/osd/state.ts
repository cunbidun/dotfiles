import { timeout, Variable } from 'astal';
export type OsdContext = 'volume' | 'brightness' | 'keyboard-brightness';

export const osdContext = Variable<OsdContext>('volume');
export const barLauncherDynamicActive = Variable<boolean>(false);

const BAR_LAUNCHER_ICON_HOLD_MS = 1400;
let clearBarLauncherOverrideTimeout: ReturnType<typeof timeout> | undefined;

export const setOsdContext = (nextContext: OsdContext): void => {
    osdContext.set(nextContext);
};

export const pulseBarLauncherIcon = (holdMs?: number): void => {
    const effectiveHoldMs = holdMs ?? BAR_LAUNCHER_ICON_HOLD_MS;
    console.log(`[hyprpanel-osd] pulse launcher icon: hold=${effectiveHoldMs}ms context=${osdContext.get()}`);
    barLauncherDynamicActive.set(true);

    if (clearBarLauncherOverrideTimeout) {
        clearBarLauncherOverrideTimeout.cancel();
        clearBarLauncherOverrideTimeout = undefined;
    }

    clearBarLauncherOverrideTimeout = timeout(effectiveHoldMs, () => {
        barLauncherDynamicActive.set(false);
        clearBarLauncherOverrideTimeout = undefined;
    });
};
