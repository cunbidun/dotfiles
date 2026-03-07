import { opt } from 'src/lib/options';
import { primaryColors } from '../../colors/primary';

export default {
    enableBorder: opt(false),
    border: opt(primaryColors.overlay0),
    background: opt(primaryColors.base2),
    text: opt(primaryColors.text),
    icon: opt(primaryColors.text),
    icon_background: opt(primaryColors.base2),
    spacing: opt('0.5em'),
};
