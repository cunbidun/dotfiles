import { Variable } from 'astal';
import { App } from 'astal/gtk3';

export type SystemConfigPane = 'wifi' | 'bluetooth';

/**
 * Currently selected pane in the System Settings window. Mirrors the macOS
 * sidebar selection so entry points (the Wi-Fi / Bluetooth quick menus) can
 * deep-link straight to the matching pane.
 */
export const activePane = Variable<SystemConfigPane>('bluetooth');

/**
 * Opens the System Settings window on a specific pane.
 *
 * @param pane - The pane to reveal.
 */
export const openSystemConfig = (pane: SystemConfigPane): void => {
    activePane.set(pane);
    App.get_window('systemconfig')?.set_visible(true);
};
