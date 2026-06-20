import { bind, Variable } from 'astal';
import { App, Gtk } from 'astal/gtk3';
import AstalBluetooth from 'gi://AstalBluetooth?version=0.1';
import PopupWindow from 'src/components/menus/shared/popup/index.js';
import { DiscoverButton } from 'src/components/menus/bluetooth/header/Controls/DiscoverButton.js';
import { getAvailableBluetoothDevices } from 'src/components/menus/bluetooth/devices/helpers.js';
import { getBluetoothIcon } from 'src/components/menus/bluetooth/utils.js';
import { isPrimaryClick } from 'src/lib/events/mouse';
import { PairButton } from 'src/components/menus/bluetooth/devices/controls/PairButton.js';
import { ConnectButton } from 'src/components/menus/bluetooth/devices/controls/ConnectButton.js';
import { TrustButton } from 'src/components/menus/bluetooth/devices/controls/TrustButton.js';
import { ForgetButton } from 'src/components/menus/bluetooth/devices/controls/ForgetButton.js';
import { WifiSettingsContent } from './wifi.js';
import { activePane, SystemConfigPane } from './state.js';

const bluetoothService = AstalBluetooth.get_default();
const expandedDeviceAddress = Variable('');

const sidebarItems: [string, SystemConfigPane, string][] = [
    ['󰖩', 'wifi', 'Wi-Fi'],
    ['󰂯', 'bluetooth', 'Bluetooth'],
];

const paneTitle = (pane: SystemConfigPane): string => (pane === 'wifi' ? 'Wi-Fi' : 'Bluetooth');

const deviceStatus = (device: AstalBluetooth.Device): string => {
    if (device.connected) {
        return 'Connected';
    }

    return 'Not Connected';
};

const Sidebar = (): JSX.Element => (
    <box className="system-config-sidebar" vertical>
        <box className="system-config-search">
            <label className="system-config-search-icon txt-icon" label="󰍉" />
            <label className="system-config-search-placeholder" label="Search" />
        </box>
        <box className="system-config-sidebar-list" vertical>
            {sidebarItems.map(([icon, pane, label]) => (
                <button
                    className={bind(activePane).as(
                        (active) => `system-config-sidebar-item ${active === pane ? 'active' : ''}`,
                    )}
                    onClick={(_, event) => {
                        if (isPrimaryClick(event)) {
                            activePane.set(pane);
                        }
                    }}
                >
                    <box className="system-config-sidebar-item-content" halign={Gtk.Align.FILL}>
                        <label className="system-config-sidebar-icon txt-icon" label={icon} />
                        <label className="system-config-sidebar-label" halign={Gtk.Align.START} label={label} />
                    </box>
                </button>
            ))}
        </box>
    </box>
);

const SystemConfigBluetoothSwitch = (): JSX.Element => (
    <switch
        className="system-config-switch"
        valign={Gtk.Align.CENTER}
        active={bind(bluetoothService, 'isPowered')}
        setup={(self) => {
            self.connect('notify::active', () => {
                bluetoothService.adapter?.set_powered(self.active);
            });
        }}
    />
);

const BluetoothHero = (): JSX.Element => (
    <box className="system-config-hero-card" vertical>
        <box className="system-config-hero-row" halign={Gtk.Align.FILL}>
            <label
                className="system-config-hero-title"
                halign={Gtk.Align.START}
                valign={Gtk.Align.CENTER}
                hexpand
                label="Bluetooth"
            />
            <SystemConfigBluetoothSwitch />
        </box>
    </box>
);

const SystemConfigDeviceRow = ({ device }: SystemConfigDeviceRowProps): JSX.Element => {
    const status = Variable.derive([bind(device, 'connected')], () => deviceStatus(device));
    const controlsVisible = bind(expandedDeviceAddress).as((address) => address === device.address);

    const toggleDeviceControls = (): void => {
        expandedDeviceAddress.set(expandedDeviceAddress.get() === device.address ? '' : device.address);
    };

    return (
        <box
            className={bind(device, 'connected').as(
                (connected) => `system-config-device-row ${connected ? 'connected' : ''}`,
            )}
            vertical
            onDestroy={() => {
                status.drop();
            }}
        >
            <box className="system-config-device-content" halign={Gtk.Align.FILL} valign={Gtk.Align.CENTER} hexpand>
                <label
                    className="system-config-device-icon txt-icon"
                    label={bind(device, 'icon').as((icon) => getBluetoothIcon(`${icon}-symbolic`))}
                />
                <box className="system-config-device-copy" valign={Gtk.Align.CENTER} vertical hexpand>
                    <label
                        className="system-config-device-name"
                        halign={Gtk.Align.START}
                        label={bind(device, 'alias')}
                        truncate
                        maxWidthChars={34}
                    />
                    <label className="system-config-device-status" halign={Gtk.Align.START} label={status()} />
                </box>
                <button
                    className="system-config-device-connect"
                    onClick={(_, event) => {
                        if (!isPrimaryClick(event)) {
                            return;
                        }

                        if (device.connected) {
                            device.disconnect_device((result) => {
                                console.info(result);
                            });
                        } else {
                            device.connect_device((result) => {
                                console.info(result);
                            });
                        }
                    }}
                >
                    <label label={bind(device, 'connected').as((connected) => (connected ? 'Disconnect' : 'Connect'))} />
                </button>
                <button
                    className={controlsVisible.as((visible) => `system-config-device-info ${visible ? 'active' : ''}`)}
                    valign={Gtk.Align.CENTER}
                    onClick={(_, event) => {
                        if (isPrimaryClick(event)) {
                            toggleDeviceControls();
                        }
                    }}
                >
                    <label label="i" />
                </button>
            </box>
            <revealer revealChild={controlsVisible} transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}>
                <box className="system-config-device-actions" halign={Gtk.Align.END}>
                    <PairButton device={device} />
                    <ConnectButton device={device} />
                    <TrustButton device={device} />
                    <ForgetButton device={device} />
                </box>
            </revealer>
        </box>
    );
};

const DeviceSection = ({ title, kind, showSpinner = false }: DeviceSectionProps): JSX.Element => {
    const sectionDevices = Variable.derive([bind(bluetoothService, 'devices')], () => {
        const devices = getAvailableBluetoothDevices();
        const sectionItems =
            kind === 'known'
                ? devices.filter((device) => device.paired || device.connected).slice(0, 8)
                : devices.filter((device) => !device.paired && !device.connected).slice(0, 8);

        if (sectionItems.length === 0) {
            return <label className="system-config-empty-row" halign={Gtk.Align.START} label="No devices found" />;
        }

        return sectionItems.map((device) => <SystemConfigDeviceRow device={device} />);
    });

    return (
        <box
            className="system-config-section"
            vertical
            onDestroy={() => {
                sectionDevices.drop();
            }}
        >
            <box className="system-config-section-heading" halign={Gtk.Align.FILL}>
                <label className="system-config-section-title" halign={Gtk.Align.START} hexpand label={title} />
                {showSpinner && <DiscoverButton />}
            </box>
            <box className="system-config-device-card" vertical>
                {sectionDevices()}
            </box>
        </box>
    );
};

const BluetoothSettingsContent = (): JSX.Element => (
    <box className="system-config-scroll-content" vertical>
        <BluetoothHero />
        <DeviceSection title="My Devices" kind="known" />
        <DeviceSection title="Nearby Devices" kind="nearby" showSpinner />
    </box>
);

const SystemConfigPage = (): JSX.Element => {
    return (
        <box className="system-config-page">
            <Sidebar />
            <box className="system-config-main" vertical hexpand>
                <box className="system-config-titlebar" halign={Gtk.Align.FILL}>
                    <label
                        className="system-config-title"
                        halign={Gtk.Align.START}
                        hexpand
                        label={bind(activePane).as(paneTitle)}
                    />
                    <button
                        className="system-config-close"
                        onClick={() => App.get_window('systemconfig')?.set_visible(false)}
                    >
                        <label label="×" />
                    </button>
                </box>
                <scrollable className="system-config-scroll" vexpand>
                    {bind(activePane).as((pane) =>
                        pane === 'wifi' ? <WifiSettingsContent /> : <BluetoothSettingsContent />,
                    )}
                </scrollable>
            </box>
        </box>
    );
};

export default (): JSX.Element => (
    <PopupWindow name="systemconfig" transition={Gtk.RevealerTransitionType.CROSSFADE} layout="center">
        <SystemConfigPage />
    </PopupWindow>
);

interface SystemConfigDeviceRowProps {
    device: AstalBluetooth.Device;
}

interface DeviceSectionProps {
    title: string;
    kind: 'known' | 'nearby';
    showSpinner?: boolean;
}
