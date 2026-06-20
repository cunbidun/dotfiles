import { opt } from 'src/lib/options';
import { primaryColors } from '../../../colors/primary';
import { tertiaryColors } from '../../../colors/tertiary';
import { sharedRadius } from '../../../shared';

export default {
    radius: opt(sharedRadius),
    background: opt(primaryColors.crust),
    text: opt(tertiaryColors.lavender),
};
