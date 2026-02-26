import { bind, Variable } from 'astal';
import { Gtk } from 'astal/gtk3';
import { cpuService, cpuTempService, gpuService, handleClick, networkService, ramService, storageService } from './helpers';
import { Binding } from 'astal';
import { renderResourceLabel } from 'src/components/bar/utils/systemResource';
import options from 'src/configuration';
import { isPrimaryClick } from 'src/lib/events/mouse';
import { uptime } from 'src/services/system/uptime';

const { enable_gpu } = options.menus.dashboard.stats;
const loadAverage = Variable('').poll(5000, 'cut -d" " -f1-3 /proc/loadavg');

const usageTone = (percent: number): 'ok' | 'warn' | 'hot' => {
    if (percent < 70) return 'ok';
    if (percent < 90) return 'warn';
    return 'hot';
};

const alignRate = (rate: string, width = 8): string => {
    const clean = rate.trim();
    if (clean.length >= width) {
        return clean;
    }
    return `${' '.repeat(width - clean.length)}${clean}`;
};

const StatRow = ({ icon, title, value, stat, tone = 'ok', clickable = false }: StatRowProps): JSX.Element => {
    const row = (
        <box className={`stat-row ${stat}`} valign={Gtk.Align.CENTER} halign={Gtk.Align.FILL} hexpand>
            <label className={'txt-icon stat-icon'} label={icon} />
            <label className={'stat-title'} label={title} />
            <label className={'stat-metric'} hexpand halign={Gtk.Align.END} xalign={1} label={value} />
        </box>
    );

    if (!clickable) {
        return row;
    }

    const toneClassName =
        typeof tone === 'string' ? `stat-row-btn ${tone}` : bind(tone).as((level) => `stat-row-btn ${level}`);

    return (
        <button
            className={toneClassName}
            hexpand
            halign={Gtk.Align.FILL}
            onClick={(_, event) => {
                if (isPrimaryClick(event)) {
                    handleClick();
                }
            }}
        >
            {row}
        </button>
    );
};

export const GpuStat = (): JSX.Element => {
    return (
        <box>
            {bind(enable_gpu).as((enabled) => {
                if (!enabled) {
                    return <box />;
                }

                gpuService.initialize();

                return (
                    <StatRow
                        icon={'󰢮'}
                        stat={'gpu'}
                        title={'GPU'}
                        value={bind(gpuService.gpu).as((gpuUsage) => `${Math.floor(gpuUsage * 100)}%`)}
                        tone={bind(gpuService.gpu).as((gpuUsage) => usageTone(Math.floor(gpuUsage * 100)))}
                        clickable
                    />
                );
            })}
        </box>
    );
};

const gpuTempTone = (tempC: number): 'ok' | 'warn' | 'hot' => {
    if (tempC < 70) return 'ok';
    if (tempC < 85) return 'warn';
    return 'hot';
};

export const GpuTempStat = (): JSX.Element => {
    return (
        <box>
            {bind(enable_gpu).as((enabled) => {
                if (!enabled) {
                    return <box />;
                }

                gpuService.initialize();

                return (
                    <StatRow
                        icon={''}
                        stat={'gputemp'}
                        title={'GPU Temp'}
                        value={bind(gpuService.gpuTemp).as((tempC) => `${Math.round(tempC)}C`)}
                        tone={bind(gpuService.gpuTemp).as((tempC) => gpuTempTone(Math.round(tempC)))}
                        clickable
                    />
                );
            })}
        </box>
    );
};

export const CpuStat = (): JSX.Element => {
    cpuService.initialize();

    return (
        <StatRow
            icon={''}
            stat={'cpu'}
            title={'CPU'}
            value={bind(cpuService.cpu).as((cpuUsage) => `${Math.round(cpuUsage)}%`)}
            tone={bind(cpuService.cpu).as((cpuUsage) => usageTone(Math.round(cpuUsage)))}
            clickable
        />
    );
};

export const CpuTempStat = (): JSX.Element => {
    cpuTempService.initialize();

    return (
        <StatRow
            icon={''}
            stat={'cputemp'}
            title={'CPU Temp'}
            value={bind(cpuTempService.temperature).as((tempC) => `${Math.round(tempC)}C`)}
            tone={bind(cpuTempService.temperature).as((tempC) => gpuTempTone(Math.round(tempC)))}
            clickable
        />
    );
};

export const RamStat = (): JSX.Element => {
    ramService.initialize();

    return (
        <StatRow
            icon={''}
            stat={'ram'}
            title={'RAM'}
            value={bind(ramService.ram).as((ramUsage) => renderResourceLabel('used/total', ramUsage, true))}
            tone={bind(ramService.ram).as((ramUsage) => usageTone(ramUsage.percentage))}
            clickable
        />
    );
};

export const StorageStat = (): JSX.Element => {
    storageService.initialize();

    return (
        <StatRow
            icon={'󰋊'}
            stat={'storage'}
            title={'Disk'}
            value={bind(storageService.storage).as((storageUsage) => renderResourceLabel('used/total', storageUsage, true))}
            tone={bind(storageService.storage).as((storageUsage) => usageTone(storageUsage.percentage))}
            clickable
        />
    );
};

export const NetworkStat = (): JSX.Element => {
    networkService.initialize();

    return (
        <StatRow
            icon={'󰤨'}
            stat={'network'}
            title={'Net'}
            value={bind(networkService.network).as((net) => {
                const inRate = alignRate(`↓ ${net.in}`, 10);
                const outRate = alignRate(`↑ ${net.out}`, 10);
                return `${inRate}   ${outRate}`;
            })}
        />
    );
};

export const UptimeStat = (): JSX.Element => {
    return (
        <StatRow
            icon={'󱫐'}
            stat={'uptime'}
            title={'Uptime'}
            value={bind(uptime).as((mins) => {
                const totalMins = Math.max(0, Math.floor(mins));
                const days = Math.floor(totalMins / 1440);
                const hours = Math.floor((totalMins % 1440) / 60);
                const minutes = totalMins % 60;
                if (days > 0) return `${days}d ${hours}h ${minutes}m`;
                if (hours > 0) return `${hours}h ${minutes}m`;
                return `${minutes}m`;
            })}
        />
    );
};

export const LoadStat = (): JSX.Element => {
    return <StatRow icon={'󰾆'} stat={'load'} title={'Load'} value={bind(loadAverage)} />;
};

interface StatRowProps {
    icon: string;
    stat: string;
    title: string;
    value: Binding<string> | string;
    tone?: Binding<'ok' | 'warn' | 'hot'> | 'ok' | 'warn' | 'hot';
    clickable?: boolean;
}
