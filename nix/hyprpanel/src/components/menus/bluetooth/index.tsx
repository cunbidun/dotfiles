import { bind, Variable } from 'astal';
import { App, Gtk } from 'astal/gtk3';
import AstalBluetooth from 'gi://AstalBluetooth?version=0.1';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import options from 'src/configuration';
import { SystemUtilities } from 'src/core/system/SystemUtilities.js';
import { isPrimaryClick } from 'src/lib/events/mouse';
import DropdownMenu from '../shared/dropdown/index.js';
import { getAvailableBluetoothDevices } from './devices/helpers.js';
import { ToggleSwitch } from './header/Controls/ToggleSwitch.js';
import { getBluetoothIcon } from './utils.js';
import { openSystemConfig } from 'src/components/systemConfig/state.js';

const bluetoothService = AstalBluetooth.get_default();
const btStatus = SystemUtilities.checkServiceStatus(['bluetooth.service']);

const BluetoothQuickHeader = (): JSX.Element => (
    <box className="bluetooth-quick-header" halign={Gtk.Align.FILL}>
        <label className="mac-popover-title bluetooth-quick-title" hexpand halign={Gtk.Align.START} label="Bluetooth" />
        <ToggleSwitch />
    </box>
);

const BluetoothQuickDeviceRow = ({ device }: BluetoothQuickDeviceRowProps): JSX.Element => {
    const status = Variable.derive([bind(device, 'connected'), bind(device, 'paired')], (connected, paired) => {
        if (connected) {
            return 'Connected';
        }

        if (paired) {
            return 'Paired';
        }

        return 'Not Connected';
    });

    return (
        <button
            className={bind(device, 'connected').as(
                (connected) => `bluetooth-quick-device-row ${connected ? 'connected' : ''}`,
            )}
            onClick={(_, event) => {
                if (!isPrimaryClick(event) || device.connected) {
                    return;
                }

                device.connect_device((result) => {
                    console.info(result);
                });
            }}
            onDestroy={() => {
                status.drop();
            }}
            hexpand
        >
            <box className="bluetooth-quick-device-content" halign={Gtk.Align.FILL} hexpand>
                <label
                    className={bind(device, 'connected').as(
                        (connected) => `bluetooth-quick-device-icon txt-icon ${connected ? 'active' : ''}`,
                    )}
                    label={bind(device, 'icon').as((icon) => getBluetoothIcon(`${icon}-symbolic`))}
                />
                <box className="bluetooth-quick-device-copy" vertical hexpand>
                    <label
                        className="bluetooth-quick-device-name"
                        halign={Gtk.Align.START}
                        label={bind(device, 'alias')}
                        truncate
                        maxWidthChars={28}
                    />
                    <label
                        className="bluetooth-quick-device-status"
                        halign={Gtk.Align.START}
                        label={status()}
                        truncate
                    />
                </box>
            </box>
        </button>
    );
};

const BluetoothQuickDevices = (): JSX.Element => {
    const devices = Variable.derive([bind(bluetoothService, 'devices'), bind(bluetoothService, 'isPowered')], () => {
        if (btStatus === 'MISSING') {
            return <label className="bluetooth-quick-empty" label="Bluetooth service unavailable" />;
        }

        if (!bluetoothService.adapter?.powered) {
            return <label className="bluetooth-quick-empty" label="Bluetooth is off" />;
        }

        const availableDevices = getAvailableBluetoothDevices().slice(0, 6);

        if (availableDevices.length === 0) {
            return <label className="bluetooth-quick-empty" label="No devices found" />;
        }

        return availableDevices.map((device) => <BluetoothQuickDeviceRow device={device} />);
    });

    return (
        <box
            className="bluetooth-quick-list"
            vertical
            onDestroy={() => {
                devices.drop();
            }}
        >
            {devices()}
        </box>
    );
};

const BluetoothSettingsRow = (): JSX.Element => (
    <button
        className="bluetooth-settings-link mac-popover-row"
        onClick={(_, event) => {
            if (isPrimaryClick(event)) {
                App.get_window('bluetoothmenu')?.set_visible(false);
                openSystemConfig('bluetooth');
            }
        }}
    >
        <box className="mac-popover-row-content" halign={Gtk.Align.FILL} hexpand>
            <label className="mac-popover-row-title" halign={Gtk.Align.START} hexpand label="Bluetooth Settings..." />
            <label className="mac-popover-row-chevron txt-icon" label="›" />
        </box>
    </button>
);

const BluetoothMainPage = (): JSX.Element => (
    <box className="mac-popover-page bluetooth-quick-page" vertical>
        <BluetoothQuickHeader />
        <BluetoothQuickDevices />
        <BluetoothSettingsRow />
    </box>
);

export default (): JSX.Element => {
    return (
        <DropdownMenu
            name={'bluetoothmenu'}
            transition={bind(options.menus.transition).as((transition) => RevealerTransitionMap[transition])}
        >
            <box className={'menu-items bluetooth'} halign={Gtk.Align.FILL} hexpand>
                <box
                    className={'menu-items-container bluetooth mac-popover-container'}
                    halign={Gtk.Align.FILL}
                    vertical
                    hexpand
                >
                    <BluetoothMainPage />
                </box>
            </box>
        </DropdownMenu>
    );
};

interface BluetoothQuickDeviceRowProps {
    device: AstalBluetooth.Device;
}
