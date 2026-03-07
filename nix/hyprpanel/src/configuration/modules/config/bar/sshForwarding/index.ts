import { opt } from 'src/lib/options';

export default {
    icon: opt('󰱠'),
    showLabel: opt(true),
    configPath: opt('~/.ssh/config'),
    defaultHost: opt(''),
    defaultLocalPort: opt(''),
    defaultRemotePort: opt('3000'),
    sshCommand: opt('/run/current-system/sw/bin/ssh'),
    extraArgs: opt<string[]>([]),
    pollingInterval: opt(2000),
    leftClick: opt('menu:sshforwarding'),
    rightClick: opt(''),
    middleClick: opt(''),
    scrollUp: opt(''),
    scrollDown: opt(''),
};
