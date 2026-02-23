import { opt } from 'src/lib/options';

export default {
    label: opt(true),
    rightClick: opt(''),
    middleClick: opt(''),
    scrollUp: opt('astal -i hyprpanel "vol +5"'),
    scrollDown: opt('astal -i hyprpanel "vol -5"'),
};
