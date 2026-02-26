import { bind, execAsync, Variable } from 'astal';
import AstalNetwork from 'gi://AstalNetwork?version=0.1';
import options from 'src/configuration';
import { BashPoller } from 'src/lib/poller/BashPoller';

const networkService = AstalNetwork.get_default();

export const isWifiEnabled: Variable<boolean> = Variable(false);
export const isRecording: Variable<boolean> = Variable(false);
const recordingPollingInterval = Variable(1000);
let wifiEnabledBinding: Variable<void> | undefined;

Variable.derive([bind(networkService, 'wifi')], () => {
    wifiEnabledBinding?.drop();
    wifiEnabledBinding = undefined;

    if (networkService.wifi === null) {
        return;
    }

    wifiEnabledBinding = Variable.derive([bind(networkService.wifi, 'enabled')], (isEnabled) => {
        isWifiEnabled.set(isEnabled);
    });
});

export const executeCommand = (command: string): void => {
    void execAsync(['bash', '-lc', command]).catch((error) => {
        console.error(`Failed to execute command: ${command}`, error);
    });
};

export const getRecordingPath = (): string => options.menus.dashboard.recording.path.get();

export const recordingPoller = new BashPoller<boolean, []>(
    isRecording,
    [],
    bind(recordingPollingInterval),
    `${SRC_DIR}/scripts/screen_record.sh status`,
    (output) => output.trim() === 'recording',
);
