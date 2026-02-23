import options from 'src/configuration';
import { SystemUtilities } from 'src/core/system/SystemUtilities';
import { WallpaperService } from 'src/services/wallpaper';

const wallpaperService = WallpaperService.getInstance();

export const initializeTrackers = (resetCssFunc: () => void): void => {
    wallpaperService.connect('changed', () => {
        resetCssFunc();
    });

    options.wallpaper.image.subscribe(() => {
        if (!options.wallpaper.enable.get()) {
            resetCssFunc();
        }
        if (options.wallpaper.pywal.get() && SystemUtilities.checkDependencies('wal')) {
            const wallpaperPath = options.wallpaper.image.get();
            SystemUtilities.bash(`wal -i "${wallpaperPath}"`);
        }
    });
};
