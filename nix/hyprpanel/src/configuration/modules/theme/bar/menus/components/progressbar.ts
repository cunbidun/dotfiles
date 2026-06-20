import { opt } from 'src/lib/options';
import { primaryColors } from '../../../colors/primary';
import { sharedRadius } from '../../../shared';

export default {
    foreground: opt(primaryColors.lavender),
    background: opt(primaryColors.surface1),
    radius: opt(sharedRadius),
};
