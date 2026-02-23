import { FontStyle } from 'src/components/settings/shared/inputs/font/utils';
import { opt } from 'src/lib/options';

export default {
    tooltip: {
        scaling: opt(100),
    },
    font: {
        size: opt('1.2rem'),
        name: opt('Ubuntu Nerd Font'),
        style: opt<FontStyle>('normal'),
        label: opt('Ubuntu Nerd Font'),
        weight: opt(600),
    },
};
