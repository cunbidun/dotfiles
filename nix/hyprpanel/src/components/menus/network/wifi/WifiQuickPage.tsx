import { bind, Variable } from 'astal';
import { App, Astal, Gtk } from 'astal/gtk3';
import AstalNetwork from 'gi://AstalNetwork?version=0.1';
import { NetworkService } from 'src/services/network';
import { isPrimaryClick } from 'src/lib/events/mouse';
import { openSystemConfig } from 'src/components/systemConfig/state';
import Spinner from 'src/components/shared/Spinner';
import { WifiSwitch } from './Controls/WifiSwitch';
import { categorizeAPs, isSecured } from './helpers';

const networkService = NetworkService.getInstance();
const astalNetwork = AstalNetwork.get_default();

const WifiQuickHeader = (): JSX.Element => (
    <box className="wifi-quick-header" halign={Gtk.Align.FILL}>
        <label className="mac-popover-title wifi-quick-title" hexpand halign={Gtk.Align.START} label="Wi-Fi" />
        <WifiSwitch />
    </box>
);

const WifiQuickNetworkRow = ({ accessPoint }: { accessPoint: AstalNetwork.AccessPoint }): JSX.Element => {
    const isActive = Variable.derive(
        [bind(astalNetwork.wifi, 'activeAccessPoint')],
        (activeAp) => accessPoint.ssid === activeAp?.ssid,
    );
    const showSpinner = Variable.derive(
        [bind(networkService.wifi.connecting)],
        (conn) => accessPoint.bssid === conn,
    );

    return (
        <button
            className={bind(isActive).as((active) => `wifi-quick-network-row ${active ? 'connected' : ''}`)}
            onClick={(_: Astal.Button, event: Astal.ClickEvent) => {
                networkService.wifi.connectToAP(accessPoint, event);
            }}
            onDestroy={() => {
                isActive.drop();
                showSpinner.drop();
            }}
            hexpand
        >
            <box className="wifi-quick-network-content" halign={Gtk.Align.FILL} hexpand>
                <label
                    className={bind(isActive).as((active) => `wifi-quick-network-icon txt-icon ${active ? 'active' : ''}`)}
                    label={networkService.getWifiIcon(accessPoint.iconName)}
                />
                <label
                    className="wifi-quick-network-name"
                    halign={Gtk.Align.START}
                    hexpand
                    truncate
                    maxWidthChars={26}
                    label={accessPoint.ssid ?? ''}
                />
                <revealer revealChild={bind(showSpinner)} halign={Gtk.Align.END}>
                    <Spinner className="spinner wap" setup={(self: Gtk.Spinner) => self.start()} />
                </revealer>
                {isSecured(accessPoint) && (
                    <label className="wifi-quick-network-lock txt-icon" label="󰌾" />
                )}
            </box>
        </button>
    );
};

const WifiQuickKnownNetworks = (): JSX.Element => {
    const rows = Variable.derive(
        [
            bind(networkService.wifi.isWifiEnabled),
            bind(networkService.wifi.wifiAccessPoints),
            bind(networkService.wifi.connecting),
            bind(networkService.wifi.activeConnectionState),
            bind(networkService.wifi.savedNetworks),
        ],
        (enabled) => {
            if (!enabled) {
                return <label className="wifi-quick-empty" label="Wi-Fi is off" />;
            }

            const { active, known } = categorizeAPs();
            const networks = active ? [active, ...known] : known;

            if (networks.length === 0) {
                return <label className="wifi-quick-empty" label="No known networks" />;
            }

            return networks.map((accessPoint) => <WifiQuickNetworkRow accessPoint={accessPoint} />);
        },
    );

    return (
        <box className="wifi-quick-section" vertical>
            <label className="wifi-quick-section-title" halign={Gtk.Align.START} label="Known Networks" />
            <box className="wifi-quick-list" vertical onDestroy={() => rows.drop()}>
                {rows()}
            </box>
        </box>
    );
};

const openWifiSettings = (): void => {
    App.get_window('networkmenu')?.set_visible(false);
    openSystemConfig('wifi');
};

const WifiQuickLinkRow = ({ label }: { label: string }): JSX.Element => (
    <button
        className="wifi-settings-link mac-popover-row"
        onClick={(_, event) => {
            if (isPrimaryClick(event)) {
                openWifiSettings();
            }
        }}
    >
        <box className="mac-popover-row-content" halign={Gtk.Align.FILL} hexpand>
            <label className="mac-popover-row-title" halign={Gtk.Align.START} hexpand label={label} />
            <label className="mac-popover-row-chevron txt-icon" label="›" />
        </box>
    </button>
);

export const WifiQuickPage = (): JSX.Element => (
    <box className="mac-popover-page wifi-quick-page" vertical>
        <WifiQuickHeader />
        <WifiQuickKnownNetworks />
        <WifiQuickLinkRow label="Other Networks" />
        <WifiQuickLinkRow label="Wi-Fi Settings..." />
    </box>
);
