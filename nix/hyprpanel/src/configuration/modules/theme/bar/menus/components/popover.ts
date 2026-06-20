import { opt } from 'src/lib/options';
import { primaryColors } from '../../../colors/primary';
import { secondaryColors } from '../../../colors/secondary';
import { sharedRadius } from '../../../shared';

export default {
    scaling: opt(100),
    radius: opt(sharedRadius),
    text: opt(primaryColors.lavender),
    background: opt(secondaryColors.mantle),
    border: opt(secondaryColors.mantle),
};
