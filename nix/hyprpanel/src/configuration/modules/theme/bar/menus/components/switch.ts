import { opt } from 'src/lib/options';
import { primaryColors } from '../../../colors/primary';
import { secondaryColors } from '../../../colors/secondary';
import { tertiaryColors } from '../../../colors/tertiary';
import { sharedRadius } from '../../../shared';

export default {
    enabled: opt(primaryColors.lavender),
    disabled: opt(tertiaryColors.surface0),
    puck: opt(secondaryColors.surface1),
    radius: opt(sharedRadius),
    slider_radius: opt(sharedRadius),
};
