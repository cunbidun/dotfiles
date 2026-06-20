import { opt } from 'src/lib/options';
import { sharedRadius } from '../../../shared';

export default {
    radius: opt(sharedRadius),
    width: opt('0.25em'),
};
