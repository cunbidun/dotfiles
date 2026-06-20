import { bind, Variable } from 'astal';
import { Astal, Gtk } from 'astal/gtk3';
import AstalNetwork from 'gi://AstalNetwork?version=0.1';
import { NetworkService } from 'src/services/network';
import { isPrimaryClick } from 'src/lib/events/mouse';
import Spinner from 'src/components/shared/Spinner';
import { categorizeAPs, isSecured } from 'src/components/menus/network/wifi/helpers';
import { APStaging } from 'src/components/menus/network/wifi/APStaging';

const networkService = NetworkService.getInstance();
const astalNetwork = AstalNetwork.get_default();

// Tracks which network row has its actions ("Details") expanded.
const expandedSsid = Variable('');

const toggleExpanded = (ssid: string): void => {
    expandedSsid.set(expandedSsid.get() === ssid ? '' : ssid);
};

const ActionButton = ({ label, onClick }: ActionButtonProps): JSX.Element => (
    <button
        className="system-config-action-button"
        onClick={(_, event) => {
            if (isPrimaryClick(event)) {
                onClick(event);
            }
        }}
    >
        <label label={label} />
    </button>
);

const NetworkActions = ({ accessPoint }: NetworkRowProps): JSX.Element => {
    const isActive = Variable.derive(
        [bind(astalNetwork.wifi, 'activeAccessPoint')],
        (activeAp) => accessPoint.ssid === activeAp?.ssid,
    );
    const isSaved = Variable.derive([bind(networkService.wifi.savedNetworks)], (saved) =>
        saved.includes(accessPoint.ssid || ''),
    );

    return (
        <box
            className="system-config-device-actions"
            halign={Gtk.Align.END}
            onDestroy={() => {
                isActive.drop();
                isSaved.drop();
            }}
        >
            {bind(isActive).as((active) =>
                active ? (
                    <ActionButton
                        label="Disconnect"
                        onClick={(event) => networkService.wifi.disconnectFromAP(accessPoint, event)}
                    />
                ) : (
                    <ActionButton
                        label="Connect"
                        onClick={(event) => networkService.wifi.connectToAP(accessPoint, event)}
                    />
                ),
            )}
            {bind(isSaved).as((saved) =>
                saved ? (
                    <ActionButton
                        label="Forget"
                        onClick={(event) => networkService.wifi.forgetAP(accessPoint, event)}
                    />
                ) : (
                    <box />
                ),
            )}
        </box>
    );
};

const WifiNetworkRow = ({ accessPoint, showStatus = false }: WifiNetworkRowProps): JSX.Element => {
    const ssid = accessPoint.ssid || '';

    const isActive = Variable.derive(
        [bind(astalNetwork.wifi, 'activeAccessPoint')],
        (activeAp) => accessPoint.ssid === activeAp?.ssid,
    );
    const showSpinner = Variable.derive(
        [bind(networkService.wifi.connecting)],
        (conn) => accessPoint.bssid === conn,
    );
    const controlsVisible = bind(expandedSsid).as((expanded) => expanded === ssid);

    return (
        <box
            className={bind(isActive).as((active) => `system-config-device-row ${active ? 'connected' : ''}`)}
            vertical
            onDestroy={() => {
                isActive.drop();
                showSpinner.drop();
            }}
        >
            <box className="system-config-device-content" halign={Gtk.Align.FILL} valign={Gtk.Align.CENTER} hexpand>
                <label
                    className={bind(isActive).as((active) => `system-config-device-icon txt-icon ${active ? 'active' : ''}`)}
                    label={networkService.getWifiIcon(accessPoint.iconName)}
                />
                <box className="system-config-device-copy" valign={Gtk.Align.CENTER} vertical hexpand>
                    <label
                        className="system-config-device-name"
                        halign={Gtk.Align.START}
                        label={ssid}
                        truncate
                        maxWidthChars={30}
                    />
                    {showStatus && (
                        <label
                            className="system-config-device-status"
                            halign={Gtk.Align.START}
                            label={bind(isActive).as((active) => (active ? 'Connected' : 'Not Connected'))}
                        />
                    )}
                </box>
                <revealer revealChild={bind(showSpinner)} halign={Gtk.Align.END} valign={Gtk.Align.CENTER}>
                    <Spinner className="spinner wap" setup={(self: Gtk.Spinner) => self.start()} />
                </revealer>
                {isSecured(accessPoint) && (
                    <label className="system-config-network-lock txt-icon" valign={Gtk.Align.CENTER} label="󰌾" />
                )}
                <button
                    className={controlsVisible.as((visible) => `system-config-device-info ${visible ? 'active' : ''}`)}
                    valign={Gtk.Align.CENTER}
                    onClick={(_, event) => {
                        if (isPrimaryClick(event)) {
                            toggleExpanded(ssid);
                        }
                    }}
                >
                    <label label="i" />
                </button>
            </box>
            <revealer revealChild={controlsVisible} transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}>
                <NetworkActions accessPoint={accessPoint} />
            </revealer>
        </box>
    );
};

const WifiHero = (): JSX.Element => (
    <box className="system-config-hero-card" vertical>
        <box className="system-config-hero-row" halign={Gtk.Align.FILL}>
            <label
                className="system-config-hero-title"
                halign={Gtk.Align.START}
                valign={Gtk.Align.CENTER}
                hexpand
                label="Wi-Fi"
            />
            <switch
                className="system-config-switch"
                valign={Gtk.Align.CENTER}
                active={bind(networkService.wifi.isWifiEnabled)}
                setup={(self) => {
                    self.connect('notify::active', () => {
                        astalNetwork.wifi?.set_enabled(self.active);
                    });
                }}
            />
        </box>
    </box>
);

const WifiSection = ({ title, kind }: WifiSectionProps): JSX.Element => {
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
                return <label className="system-config-empty-row" halign={Gtk.Align.START} label="Wi-Fi is off" />;
            }

            const { active, known, other } = categorizeAPs();
            const networks =
                kind === 'known' ? (active ? [active, ...known] : known) : other.slice(0, 12);

            if (networks.length === 0) {
                return (
                    <label className="system-config-empty-row" halign={Gtk.Align.START} label="No networks found" />
                );
            }

            return networks.map((accessPoint) => (
                <WifiNetworkRow accessPoint={accessPoint} showStatus={kind === 'known'} />
            ));
        },
    );

    return (
        <box className="system-config-section" vertical onDestroy={() => rows.drop()}>
            <box className="system-config-section-heading" halign={Gtk.Align.FILL}>
                <label className="system-config-section-title" halign={Gtk.Align.START} hexpand label={title} />
            </box>
            <box className="system-config-device-card" vertical>
                {rows()}
            </box>
        </box>
    );
};

export const WifiSettingsContent = (): JSX.Element => (
    <box className="system-config-scroll-content" vertical>
        <WifiHero />
        <APStaging />
        <WifiSection title="Known Networks" kind="known" />
        <WifiSection title="Other Networks" kind="other" />
    </box>
);

interface WifiNetworkRowProps {
    accessPoint: AstalNetwork.AccessPoint;
    showStatus?: boolean;
}

interface NetworkRowProps {
    accessPoint: AstalNetwork.AccessPoint;
}

interface WifiSectionProps {
    title: string;
    kind: 'known' | 'other';
}

interface ActionButtonProps {
    label: string;
    onClick: (event: Astal.ClickEvent) => void;
}
