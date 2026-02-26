import { execAsync } from 'astal';
import { App } from 'astal/gtk3';
import options from 'src/configuration';
import CpuUsageService from 'src/services/system/cpuUsage';
import CpuTempService from 'src/services/system/cputemp';
import GpuUsageService from 'src/services/system/gpuUsage';
import NetworkUsageService from 'src/services/system/networkUsage';
import RamUsageService from 'src/services/system/ramUsage';
import StorageService from 'src/services/system/storage';

const { terminal } = options;
const { interval, enabled, enable_gpu } = options.menus.dashboard.stats;
const { paths } = options.bar.customModules.storage;

export const gpuService = new GpuUsageService();
export const cpuService = new CpuUsageService();
export const cpuTempService = new CpuTempService({ frequency: interval });
export const ramService = new RamUsageService();
export const storageService = new StorageService({ pathsToMonitor: paths });
export const networkService = new NetworkUsageService({ frequency: interval });

/**
 * Handles the click event for the dashboard menu.
 *
 * This function hides the dashboard menu window and attempts to open the `btop` terminal application.
 * If the command fails, it logs an error message.
 */
export const handleClick = (): void => {
    App.get_window('dashboardmenu')?.set_visible(false);
    execAsync(`bash -c "${terminal} -e btop"`).catch((err) => `Failed to open btop: ${err}`);
};

/**
 * Monitors the interval for updating CPU, RAM, and storage services.
 *
 * This function subscribes to the interval setting and updates the timers for the CPU, RAM, and storage services accordingly.
 */
const monitorInterval = (): void => {
    interval.subscribe(() => {
        ramService.updateTimer(interval.get());
        cpuService.updateTimer(interval.get());
        cpuTempService.updateFrequency(interval.get());
        storageService.frequency = interval.get();
        networkService.updateTimer(interval.get());
    });
};

/**
 * Monitors the enabled state for CPU, RAM, GPU, and storage services.
 *
 * This function subscribes to the enabled setting and starts or stops the pollers for the CPU, RAM, GPU, and storage services based on the enabled state.
 */
const monitorStatsEnabled = (): void => {
    enabled.subscribe(() => {
        if (!enabled.get()) {
            ramService.stopPoller();
            cpuService.stopPoller();
            cpuTempService.stopPoller();
            gpuService.stopPoller();
            storageService.stopPoller();
            networkService.stopPoller();
            return;
        }

        if (enable_gpu.get()) {
            gpuService.startPoller();
        }

        ramService.startPoller();
        cpuService.startPoller();
        cpuTempService.startPoller();
        storageService.startPoller();
        networkService.startPoller();
    });
};

/**
 * Monitors the GPU tracking enabled state.
 *
 * This function subscribes to the GPU tracking enabled setting and starts or stops the GPU poller based on the enabled state.
 */
const monitorGpuTrackingEnabled = (): void => {
    enable_gpu.subscribe((gpuEnabled) => {
        if (gpuEnabled) {
            return gpuService.startPoller();
        }

        gpuService.stopPoller();
    });
};

/**
 * Sets up dashboard monitoring for CPU, RAM, GPU, and storage services.
 *
 * This function sets up the initial state for the services and monitoring for interval changes, enabled state changes, and GPU tracking enabled state.
 */
export const setupDashboardMonitoring = (): void => {
    storageService.round = true;
    networkService.setShouldRound(true);

    if (enabled.get()) {
        ramService.startPoller();
        cpuService.startPoller();
        cpuTempService.startPoller();
        storageService.startPoller();
        networkService.startPoller();
    }

    if (enabled.get() && enable_gpu.get()) {
        gpuService.startPoller();
    } else {
        gpuService.stopPoller();
    }

    monitorInterval();
    monitorStatsEnabled();
    monitorGpuTrackingEnabled();
};
