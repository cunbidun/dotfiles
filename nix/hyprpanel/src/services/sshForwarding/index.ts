import { GLib, Variable, bind, execAsync, readFileAsync } from 'astal';
import { Gio } from 'astal/file';
import options from 'src/configuration';
import { SystemUtilities } from 'src/core/system/SystemUtilities';

type TunnelState = {
    active: boolean;
    host: string;
    localPort: string;
    remotePort: string;
    pid: number | null;
    error: string;
};

export type DetectedTunnel = {
    id: string;
    host: string;
    localPort: string;
    remotePort: string;
    socketPath: string;
    unitName: string;
    pid: number | null;
};

class SshForwardingService {
    private static _instance: SshForwardingService;

    private _timer: ReturnType<typeof setInterval> | null = null;
    private _initialized = false;
    private _pollIntervalBinding?: Variable<void>;

    public hosts = Variable<string[]>([]);
    public selectedHost = Variable('');
    public localPort = Variable('');
    public remotePort = Variable('');
    public connections = Variable<DetectedTunnel[]>([]);
    public state = Variable<TunnelState>({
        active: false,
        host: '',
        localPort: '',
        remotePort: '',
        pid: null,
        error: '',
    });

    private constructor() {
        const { defaultHost, defaultLocalPort, defaultRemotePort, pollingInterval } =
            options.bar.customModules.sshForwarding;

        this.selectedHost.set(defaultHost.get());
        this.localPort.set(defaultLocalPort.get());
        this.remotePort.set(defaultRemotePort.get());

        this._pollIntervalBinding = Variable.derive([bind(pollingInterval)], (interval) => {
            this._restartPolling(interval);
        });
    }

    public static getInstance(): SshForwardingService {
        if (!this._instance) {
            this._instance = new SshForwardingService();
        }

        return this._instance;
    }

    public async initialize(): Promise<void> {
        if (this._initialized) {
            return;
        }

        this._ensureRuntimeDir();
        await this.reloadHosts();
        this.refresh();
        this._initialized = true;
    }

    public async reloadHosts(): Promise<void> {
        const { configPath, defaultHost } = options.bar.customModules.sshForwarding;
        const parsedHosts = await this._readHosts(configPath.get());

        this.hosts.set(parsedHosts);

        const preferredHost = this.selectedHost.get() || defaultHost.get();
        if (preferredHost && parsedHosts.includes(preferredHost)) {
            this.selectedHost.set(preferredHost);
            return;
        }

        this.selectedHost.set(parsedHosts[0] ?? '');
    }

    public async start(): Promise<void> {
        const host = this.selectedHost.get().trim();
        const remotePort = this.remotePort.get().trim();
        const localPort = this.localPort.get().trim() || remotePort;
        const validationError = this._validate(host, localPort, remotePort);

        console.log(
            `[ssh-forwarding] start requested host=${host || '<empty>'} local=${localPort || '<empty>'} remote=${remotePort || '<empty>'}`,
        );

        if (validationError) {
            console.log(`[ssh-forwarding] start validation failed: ${validationError}`);
            this._setError(validationError);
            return;
        }

        const existingTunnel = this._findExistingTunnel(host, localPort, remotePort);
        if (existingTunnel) {
            console.log(`[ssh-forwarding] existing tunnel reused id=${existingTunnel.id}`);
            this.refresh();
            this._setStateIfChanged({
                active: true,
                host: existingTunnel.host,
                localPort: existingTunnel.localPort,
                remotePort: existingTunnel.remotePort,
                pid: existingTunnel.pid,
                error: 'Tunnel already active',
            });
            return;
        }

        const tunnelId = this._buildTunnelId(host, localPort, remotePort);
        const socketPath = this._socketPath(tunnelId);
        const metadataPath = this._metadataPath(tunnelId);
        const unitName = this._unitName(tunnelId);
        const { sshCommand, extraArgs } = options.bar.customModules.sshForwarding;

        this._clearTunnelArtifacts({
            id: tunnelId,
            host,
            localPort,
            remotePort,
            socketPath,
            unitName,
            pid: null,
        });

        try {
            console.log(
                `[ssh-forwarding] starting unit=${unitName} socket=${socketPath} command=${sshCommand.get()} -L ${localPort}:localhost:${remotePort} ${host}`,
            );
            await execAsync([
                '/run/current-system/sw/bin/systemd-run',
                '--user',
                '--quiet',
                '--collect',
                `--unit=${unitName}`,
                sshCommand.get(),
                '-N',
                '-M',
                '-S',
                socketPath,
                '-o',
                'ExitOnForwardFailure=yes',
                ...extraArgs.get(),
                '-L',
                `${localPort}:localhost:${remotePort}`,
                host,
            ]);

            this._writeMetadata(metadataPath, {
                id: tunnelId,
                host,
                localPort,
                remotePort,
                socketPath,
                unitName,
            });

            const verifiedTunnel = await this._verifyStartedTunnel(host, localPort, remotePort, 8, 250);
            this.refresh();

            if (!verifiedTunnel) {
                console.log(`[ssh-forwarding] tunnel verification failed for id=${tunnelId}`);
                this._clearTunnelArtifacts({
                    id: tunnelId,
                    host,
                    localPort,
                    remotePort,
                    socketPath,
                    unitName,
                    pid: null,
                });
                this._setError('Failed to verify tunnel');
                return;
            }

            console.log(`[ssh-forwarding] tunnel started id=${tunnelId}`);
        } catch (error) {
            console.error('Failed to start SSH forwarding:', error);
            this._clearTunnelArtifacts({
                id: tunnelId,
                host,
                localPort,
                remotePort,
                socketPath,
                unitName,
                pid: null,
            });
            this._setError('Failed to start tunnel');
        }
    }

    public async stop(clearError = true, tunnelId?: string): Promise<void> {
        const target = tunnelId
            ? this.connections.get().find((connection) => connection.id === tunnelId)
            : this._findExistingTunnel();

        console.log(`[ssh-forwarding] stop requested target=${target?.id ?? '<none>'}`);

        if (target) {
            this._clearTunnelArtifacts(target);
        }

        this.state.set({
            ...this.state.get(),
            error: clearError ? '' : this.state.get().error,
        });
        await this._sleep(150);
        this.refresh();
    }

    public refresh(): void {
        const allTunnels = this._loadActiveTunnels();
        if (!this._sameConnections(this.connections.get(), allTunnels)) {
            console.log(
                `[ssh-forwarding] refresh connections changed count=${allTunnels.length} ids=${allTunnels.map((tunnel) => tunnel.id).join(',')}`,
            );
            this.connections.set(allTunnels);
        }

        const detectedTunnel = this._findExistingTunnel();
        if (!detectedTunnel) {
            this._setStateIfChanged({
                active: false,
                host: '',
                localPort: '',
                remotePort: '',
                pid: null,
                error: this.state.get().error,
            });
            return;
        }

        this._setStateIfChanged({
            active: true,
            host: detectedTunnel.host,
            localPort: detectedTunnel.localPort,
            remotePort: detectedTunnel.remotePort,
            pid: detectedTunnel.pid,
            error: '',
        });
    }

    public destroy(): void {
        if (this._timer) {
            clearInterval(this._timer);
        }

        this._pollIntervalBinding?.drop();
        this.hosts.drop();
        this.selectedHost.drop();
        this.localPort.drop();
        this.remotePort.drop();
        this.connections.drop();
        this.state.drop();
    }

    private _restartPolling(interval: number): void {
        if (this._timer) {
            clearInterval(this._timer);
        }

        this._timer = setInterval(() => this.refresh(), Math.max(interval, 500));
    }

    private async _readHosts(configPath: string): Promise<string[]> {
        try {
            const contents = await readFileAsync(this._expandPath(configPath));
            const hosts = new Set<string>();

            for (const rawLine of contents.split('\n')) {
                const line = rawLine.trim();
                const match = line.match(/^Host\s+(.+)$/i);

                if (!match) {
                    continue;
                }

                for (const token of match[1].split(/\s+/)) {
                    if (!token || /[*?!]/.test(token)) {
                        continue;
                    }

                    hosts.add(token);
                }
            }

            return [...hosts];
        } catch (error) {
            console.error('Failed to read SSH config:', error);
            return [];
        }
    }

    private _expandPath(path: string): string {
        if (path.startsWith('~/')) {
            return `${GLib.get_home_dir()}/${path.slice(2)}`;
        }

        return path;
    }

    private _runtimeDir(): string {
        return `${GLib.getenv('XDG_RUNTIME_DIR') ?? GLib.get_tmp_dir()}/hyprpanel/ssh-forwarding`;
    }

    private _sshCommand(): string {
        return options.bar.customModules.sshForwarding.sshCommand.get();
    }

    private _ensureRuntimeDir(): void {
        SystemUtilities.runCommand(`mkdir -p ${this._escapeShellArg(this._runtimeDir())}`);
    }

    private _metadataPath(tunnelId: string): string {
        return `${this._runtimeDir()}/${tunnelId}.meta`;
    }

    private _socketPath(tunnelId: string): string {
        return `${this._runtimeDir()}/${tunnelId}.sock`;
    }

    private _unitName(tunnelId: string): string {
        return `hyprpanel-ssh-forwarding-${tunnelId}`;
    }

    private _buildTunnelId(host: string, localPort: string, remotePort: string): string {
        const safeHost = host.replace(/[^a-zA-Z0-9._-]/g, '_');
        return `${safeHost}-${localPort}-${remotePort}`;
    }

    private _validate(host: string, localPort: string, remotePort: string): string {
        if (!host) {
            return 'Select a host';
        }

        if (!this._isValidPort(localPort) || !this._isValidPort(remotePort)) {
            return 'Ports must be between 1 and 65535';
        }

        return '';
    }

    private _isValidPort(port: string): boolean {
        const value = Number.parseInt(port, 10);
        return Number.isInteger(value) && value >= 1 && value <= 65535;
    }

    private _findExistingTunnel(hostArg?: string, localPortArg?: string, remotePortArg?: string): DetectedTunnel | null {
        const allTunnels = this.connections.get();
        if (allTunnels.length === 0) {
            return null;
        }

        const exactMatchRequested =
            hostArg !== undefined || localPortArg !== undefined || remotePortArg !== undefined;
        const selectedHost = hostArg ?? this.selectedHost.get().trim();
        const remotePort = remotePortArg ?? this.remotePort.get().trim();
        const localPort = localPortArg ?? (this.localPort.get().trim() || remotePort);

        const matchedTunnel =
            allTunnels.find(
                (tunnel) =>
                    (!selectedHost || tunnel.host === selectedHost) &&
                    (!remotePort || tunnel.remotePort === remotePort) &&
                    (!localPort || tunnel.localPort === localPort),
            ) ?? null;

        if (exactMatchRequested) {
            return matchedTunnel;
        }

        return matchedTunnel ?? allTunnels[0] ?? null;
    }

    private _setError(error: string): void {
        this._setStateIfChanged({
            ...this.state.get(),
            active: false,
            pid: null,
            error,
        });
    }

    private _loadActiveTunnels(): DetectedTunnel[] {
        this._ensureRuntimeDir();

        const directory = Gio.File.new_for_path(this._runtimeDir());
        if (!directory.query_exists(null)) {
            return [];
        }

        const enumerator = directory.enumerate_children('standard::*', Gio.FileQueryInfoFlags.NONE, null);
        const tunnels: DetectedTunnel[] = [];

        for (const info of enumerator) {
            const fileName = info.get_name();
            if (!fileName.endsWith('.meta')) {
                continue;
            }

            const tunnel = this._loadTunnelFromMetadata(`${this._runtimeDir()}/${fileName}`, true);
            if (tunnel) {
                tunnels.push(tunnel);
            }
        }

        enumerator.close(null);
        return tunnels;
    }

    private _loadTunnelFromMetadata(metadataPath: string, cleanupOnFailure: boolean): DetectedTunnel | null {
        const metadata = this._readMetadata(metadataPath);
        if (!metadata) {
            return null;
        }

        const unitResult = SystemUtilities.runCommand(
            `systemctl --user is-active ${this._escapeShellArg(metadata.unitName)}`,
        );
        if (unitResult.exitCode !== 0 || unitResult.stdout !== 'active') {
            if (cleanupOnFailure) {
                this._clearTunnelArtifacts({ ...metadata, pid: null });
            }
            return null;
        }

        const checkResult = SystemUtilities.runCommand(
            `${this._escapeShellArg(this._sshCommand())} -S ${this._escapeShellArg(metadata.socketPath)} -O check ${this._escapeShellArg(metadata.host)}`,
        );
        if (checkResult.exitCode !== 0) {
            if (cleanupOnFailure) {
                this._clearTunnelArtifacts({ ...metadata, pid: null });
            }
            return null;
        }

        const pidMatch = `${checkResult.stdout}\n${checkResult.stderr}`.match(/pid=(\d+)/);
        return {
            ...metadata,
            pid: pidMatch ? Number.parseInt(pidMatch[1] ?? '', 10) : null,
        };
    }

    private _readMetadata(metadataPath: string): Omit<DetectedTunnel, 'pid'> | null {
        try {
            const [success, contents] = GLib.file_get_contents(metadataPath);
            if (!success || !contents) {
                return null;
            }

            const text = new TextDecoder().decode(contents);
            const data = Object.fromEntries(
                text
                    .split('\n')
                    .map((line) => line.trim())
                    .filter(Boolean)
                    .map((line) => {
                        const [key, ...rest] = line.split('=');
                        return [key ?? '', rest.join('=')];
                    }),
            );

            if (!data.id || !data.host || !data.localPort || !data.remotePort || !data.socketPath || !data.unitName) {
                return null;
            }

            return {
                id: data.id,
                host: data.host,
                localPort: data.localPort,
                remotePort: data.remotePort,
                socketPath: data.socketPath,
                unitName: data.unitName,
            };
        } catch (error) {
            console.error('Failed to read SSH metadata:', error);
            return null;
        }
    }

    private _writeMetadata(metadataPath: string, tunnel: Omit<DetectedTunnel, 'pid'>): void {
        const contents = [
            `id=${tunnel.id}`,
            `host=${tunnel.host}`,
            `localPort=${tunnel.localPort}`,
            `remotePort=${tunnel.remotePort}`,
            `socketPath=${tunnel.socketPath}`,
            `unitName=${tunnel.unitName}`,
            '',
        ].join('\n');

        GLib.file_set_contents(metadataPath, contents);
    }

    private async _verifyStartedTunnel(
        host: string,
        localPort: string,
        remotePort: string,
        attempts: number,
        delayMs: number,
    ): Promise<DetectedTunnel | null> {
        for (let attempt = 1; attempt <= attempts; attempt += 1) {
            await this._sleep(delayMs);
            const metadata = this._readMetadata(this._metadataPath(this._buildTunnelId(host, localPort, remotePort)));
            const detectedTunnel = metadata ? this._loadTunnelFromMetadata(this._metadataPath(metadata.id), false) : null;

            if (detectedTunnel) {
                console.log(`[ssh-forwarding] tunnel verified on attempt=${attempt} id=${detectedTunnel.id}`);
                return detectedTunnel;
            }
        }

        return null;
    }

    private _clearTunnelArtifacts(tunnel: DetectedTunnel): void {
        const stopResult = SystemUtilities.runCommand(
            `systemctl --user stop ${this._escapeShellArg(tunnel.unitName)}`,
        );
        if (stopResult.exitCode === 0) {
            console.log(`[ssh-forwarding] stopped unit=${tunnel.unitName}`);
        }

        SystemUtilities.runCommand(`systemctl --user reset-failed ${this._escapeShellArg(tunnel.unitName)}`);
        this._removeTunnelFiles(tunnel.id);
    }

    private _removeTunnelFiles(tunnelId: string): void {
        SystemUtilities.runCommand(
            `rm -f ${this._escapeShellArg(this._socketPath(tunnelId))} ${this._escapeShellArg(this._metadataPath(tunnelId))}`,
        );
    }

    private _setStateIfChanged(nextState: TunnelState): void {
        const currentState = this.state.get();
        if (
            currentState.active === nextState.active &&
            currentState.host === nextState.host &&
            currentState.localPort === nextState.localPort &&
            currentState.remotePort === nextState.remotePort &&
            currentState.pid === nextState.pid &&
            currentState.error === nextState.error
        ) {
            return;
        }

        this.state.set(nextState);
    }

    private _sameConnections(current: DetectedTunnel[], next: DetectedTunnel[]): boolean {
        if (current.length !== next.length) {
            return false;
        }

        return current.every((connection, index) => {
            const other = next[index];
            return (
                other &&
                connection.id === other.id &&
                connection.host === other.host &&
                connection.localPort === other.localPort &&
                connection.remotePort === other.remotePort &&
                connection.socketPath === other.socketPath &&
                connection.unitName === other.unitName &&
                connection.pid === other.pid
            );
        });
    }

    private _escapeShellArg(arg: string): string {
        return `'${arg.replace(/'/g, `'\"'\"'`)}'`;
    }

    private _sleep(ms: number): Promise<void> {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }
}

const sshForwardingService = SshForwardingService.getInstance();

export default sshForwardingService;
