import { opt } from 'src/lib/options';
import { primaryColors } from '../../../colors/primary';
import { sharedRadius } from '../../../shared';

export default {
    size: opt('0.13em'),
    radius: opt(sharedRadius),
    color: opt(primaryColors.surface0),
};
