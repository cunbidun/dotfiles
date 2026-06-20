import DropdownMenu from '../shared/dropdown/index.js';
import { WifiQuickPage } from './wifi/WifiQuickPage.js';
import { bind } from 'astal';
import { Gtk } from 'astal/gtk3';
import { NoWifi } from './wifi/WirelessAPs/NoWifi.js';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import AstalNetwork from 'gi://AstalNetwork?version=0.1';
import options from 'src/configuration';

const networkService = AstalNetwork.get_default();

export default (): JSX.Element => {
    return (
        <DropdownMenu
            name={'networkmenu'}
            transition={bind(options.menus.transition).as((transition) => RevealerTransitionMap[transition])}
        >
            <box className={'menu-items network'} halign={Gtk.Align.FILL} hexpand>
                <box
                    className={'menu-items-container network mac-popover-container'}
                    halign={Gtk.Align.FILL}
                    vertical
                    hexpand
                >
                    {bind(networkService, 'wifi').as((wifi) => {
                        if (wifi === null) {
                            return <NoWifi />;
                        }
                        return <WifiQuickPage />;
                    })}
                </box>
            </box>
        </DropdownMenu>
    );
};
