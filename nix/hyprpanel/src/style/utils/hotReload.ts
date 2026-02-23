import { monitorFile } from 'astal';
import { GLib } from 'astal/gobject';
import { themeManager } from '..';

export const initializeHotReload = async (): Promise<void> => {
    const stylixStateDir = `${GLib.get_home_dir()}/.local/state/stylix`;
    const monitorList = [
        `${SRC_DIR}/src/style/main.scss`,
        `${SRC_DIR}/src/style/scss/bar`,
        `${SRC_DIR}/src/style/scss/common`,
        `${SRC_DIR}/src/style/scss/menus`,
        `${SRC_DIR}/src/style/scss/notifications`,
        `${SRC_DIR}/src/style/scss/osd`,
        `${SRC_DIR}/src/style/scss/settings`,
        `${SRC_DIR}/src/style/scss/colors.scss`,
        `${SRC_DIR}/src/style/scss/highlights.scss`,
        `${CONFIG_DIR}/modules.scss`,
        stylixStateDir,
        `${stylixStateDir}/current-theme-name.txt`,
        `${stylixStateDir}/theme-config.json`,
    ];

    const applyCss = themeManager.applyCss.bind(themeManager);
    monitorList.forEach((target) => {
        if (!GLib.file_test(target, GLib.FileTest.EXISTS)) {
            return;
        }

        monitorFile(target, applyCss);
    });
};
