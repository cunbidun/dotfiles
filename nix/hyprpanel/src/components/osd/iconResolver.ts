import { OsdContext } from './state';

type IconResolverInput = {
    context: OsdContext;
    screenBrightness: number;
    keyboardBrightness: number;
    speakerVolume: number;
    speakerMuted: boolean;
};

export const resolveOsdIcon = ({
    context,
    screenBrightness,
    keyboardBrightness,
    speakerVolume,
    speakerMuted,
}: IconResolverInput): string => {
    if (context === 'brightness') {
        if (screenBrightness <= 0.01) {
            return '󰃞';
        }
        if (screenBrightness <= 0.33) {
            return '󰃟';
        }
        if (screenBrightness <= 0.66) {
            return '󰃠';
        }
        return '󰃡';
    }

    if (context === 'keyboard-brightness') {
        if (keyboardBrightness <= 0.01) {
            return '󰥻';
        }
        return '󰛨';
    }

    if (speakerMuted || speakerVolume <= 0.01) {
        return '󰝟';
    }
    if (speakerVolume <= 0.33) {
        return '󰕿';
    }
    if (speakerVolume <= 0.66) {
        return '󰖀';
    }
    return '󰕾';
};
