import { FontStyle } from 'src/components/settings/shared/inputs/font/utils';
import { opt } from 'src/lib/options';
import { defaultRadius } from '../shared';

export default {
    shared: {
        radius: opt(defaultRadius),
    },
    tooltip: {
        scaling: opt(100),
    },
    font: {
        size: opt('1rem'),
        name: opt('SFMono Nerd Font'),
        style: opt<FontStyle>('normal'),
        label: opt('SFMono Nerd Font'),
        weight: opt(400),
    },
};
