import { bind, Variable } from 'astal';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import { Gtk } from 'astal/gtk3';
import DropdownMenu from '../shared/dropdown/index.js';
import options from 'src/configuration';
import sshForwardingService, { type DetectedTunnel } from 'src/services/sshForwarding';
import { isPrimaryClick } from 'src/lib/events/mouse';

const formatMapping = (localPort: string, remotePort: string): string =>
    localPort === remotePort ? `${remotePort}` : `${localPort} -> ${remotePort}`;

const getDraftMapping = (): string => {
    const remotePort = sshForwardingService.remotePort.get().trim();
    const localPort = sshForwardingService.localPort.get().trim() || remotePort;
    if (!remotePort) {
        return 'Set ports';
    }

    return formatMapping(localPort, remotePort);
};

const cycleHost = (direction: 1 | -1): void => {
    const hosts = sshForwardingService.hosts.get();
    if (hosts.length === 0) {
        return;
    }

    const currentHost = sshForwardingService.selectedHost.get();
    const currentIndex = Math.max(hosts.indexOf(currentHost), 0);
    const nextIndex = (currentIndex + direction + hosts.length) % hosts.length;
    sshForwardingService.selectedHost.set(hosts[nextIndex] ?? '');
};

export default (): JSX.Element => {
    void sshForwardingService.initialize();

    const createSubtitle = Variable.derive(
        [
            bind(sshForwardingService.selectedHost),
            bind(sshForwardingService.localPort),
            bind(sshForwardingService.remotePort),
        ],
        (host) => (host ? `${getDraftMapping()} @ ${host}` : 'Select a host and ports'),
    );

    return (
        <DropdownMenu
            name="sshforwardingmenu"
            transition={bind(options.menus.transition).as((transition) => RevealerTransitionMap[transition])}
        >
            <box className="menu-items ssh-forwarding">
                <box className="menu-items-container ssh-forwarding" vertical hexpand>
                    <box className="ssh-forwarding-panel create" vertical>
                        <box className="ssh-forwarding-panel-header">
                            <label className="ssh-forwarding-panel-icon txt-icon" label="󰱠" />
                            <box vertical hexpand>
                                <label className="ssh-forwarding-panel-title" label="Create Tunnel" />
                                <label
                                    className="ssh-forwarding-panel-subtitle"
                                    label={createSubtitle()}
                                />
                            </box>
                        </box>

                        <box className="ssh-forwarding-row">
                            <label className="menu-label" label="Host" hexpand halign={Gtk.Align.START} />
                            <box className="ssh-forwarding-host-picker">
                                <button
                                    className="ssh-forwarding-cycle"
                                    onClick={(_, event) => {
                                        if (isPrimaryClick(event)) {
                                            console.log('[ssh-forwarding] host cycle backward click');
                                            cycleHost(-1);
                                        }
                                    }}
                                >
                                    <label label="‹" />
                                </button>
                                <label
                                    className="ssh-forwarding-host"
                                    hexpand
                                    label={bind(sshForwardingService.selectedHost).as((host) => host || 'No hosts')}
                                />
                                <button
                                    className="ssh-forwarding-cycle"
                                    onClick={(_, event) => {
                                        if (isPrimaryClick(event)) {
                                            console.log('[ssh-forwarding] host cycle forward click');
                                            cycleHost(1);
                                        }
                                    }}
                                >
                                    <label label="›" />
                                </button>
                            </box>
                        </box>

                        <box className="ssh-forwarding-row">
                            <label className="menu-label" label="Local Port" hexpand halign={Gtk.Align.START} />
                            <entry
                                className="ssh-forwarding-input"
                                hexpand
                                placeholderText="Defaults to remote"
                                onChanged={(self) => sshForwardingService.localPort.set(self.text)}
                                setup={(self) => {
                                    self.text = sshForwardingService.localPort.get();
                                    self.hook(sshForwardingService.localPort, () => {
                                        if (self.text !== sshForwardingService.localPort.get()) {
                                            self.text = sshForwardingService.localPort.get();
                                        }
                                    });
                                }}
                            />
                        </box>

                        <box className="ssh-forwarding-row">
                            <label className="menu-label" label="Remote Port" hexpand halign={Gtk.Align.START} />
                            <entry
                                className="ssh-forwarding-input"
                                hexpand
                                onChanged={(self) => sshForwardingService.remotePort.set(self.text)}
                                setup={(self) => {
                                    self.text = sshForwardingService.remotePort.get();
                                    self.hook(sshForwardingService.remotePort, () => {
                                        if (self.text !== sshForwardingService.remotePort.get()) {
                                            self.text = sshForwardingService.remotePort.get();
                                        }
                                    });
                                }}
                            />
                        </box>

                        {bind(sshForwardingService.state).as((state) =>
                            state.error ? (
                                <label className="ssh-forwarding-error visible" wrap xalign={0} label={state.error} />
                            ) : (
                                <box />
                            ),
                        )}

                        <button
                            className="ssh-forwarding-main-action"
                            sensitive={bind(sshForwardingService.hosts).as((hosts) => hosts.length > 0)}
                            onClick={async (_, event) => {
                                if (!isPrimaryClick(event)) {
                                    console.log('[ssh-forwarding] start click ignored: non-primary button');
                                    return;
                                }

                                console.log('[ssh-forwarding] start click received');
                                await sshForwardingService.start();
                            }}
                        >
                            <box>
                                <label
                                    className="ssh-forwarding-action-label"
                                    label="Start Connection"
                                />
                            </box>
                        </button>
                    </box>

                    {bind(sshForwardingService.connections).as((connections) => {
                        if (connections.length === 0) {
                            return <box />;
                        }

                        return (
                            <box className="ssh-forwarding-panel current" vertical>
                                <box className="ssh-forwarding-panel-header">
                                    <label className="ssh-forwarding-panel-icon txt-icon" label="󰌘" />
                                    <box vertical hexpand>
                                        <label className="ssh-forwarding-panel-title" label="Current Connection" />
                                        <label
                                            className="ssh-forwarding-panel-subtitle"
                                            label={`${connections.length} active tunnel${connections.length > 1 ? 's' : ''}`}
                                        />
                                    </box>
                                </box>

                                <box className="ssh-forwarding-current-list" vertical>
                                    {connections.map((connection) => renderConnectionRow(connection))}
                                </box>
                            </box>
                        );
                    })}
                </box>
            </box>
        </DropdownMenu>
    );
};

const renderConnectionRow = (connection: DetectedTunnel): JSX.Element => (
    <box className="ssh-forwarding-connection-row">
        <box vertical hexpand>
            <label
                className="ssh-forwarding-connection-title"
                xalign={0}
                label={`${connection.host}:${connection.localPort}`}
            />
            <label
                className="ssh-forwarding-connection-subtitle"
                xalign={0}
                label={`Remote ${connection.remotePort}  PID ${connection.pid}`}
            />
        </box>
        <button
            className="menu-icon-button ssh-forwarding close"
            valign={Gtk.Align.CENTER}
            onClick={async (_, event) => {
                if (!isPrimaryClick(event)) {
                    console.log(`[ssh-forwarding] close click ignored: non-primary button for ${connection.id}`);
                    return;
                }

                console.log(`[ssh-forwarding] close click received for ${connection.id}`);
                await sshForwardingService.stop(true, connection.id);
            }}
        >
            <label className="ssh-forwarding-close-label txt-icon" label="󰅖" />
        </button>
    </box>
);
