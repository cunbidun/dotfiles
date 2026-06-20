import { opt } from 'src/lib/options';
import { primaryColors } from '../../../colors/primary';
import { tertiaryColors } from '../../../colors/tertiary';
import { sharedRadius } from '../../../shared';

export default {
    primary: opt(primaryColors.lavender),
    background: opt(tertiaryColors.surface2),
    backgroundhover: opt(primaryColors.surface1),
    puck: opt(primaryColors.overlay0),
    slider_radius: opt(sharedRadius),
    progress_radius: opt(sharedRadius),
};
