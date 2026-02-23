import DropdownMenu from '../shared/dropdown/index.js';
import { Controls } from './controls/index.js';
import { Stats } from './stats/index.js';
import { Directories } from './directories/index.js';
import { bind, Variable } from 'astal';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import options from 'src/configuration';

const { controls, stats, directories } = options.menus.dashboard;
const { transition } = options.menus;

export default (): JSX.Element => {
    const dashboardBinding = Variable.derive(
        [bind(controls.enabled), bind(stats.enabled), bind(directories.enabled)],
        (isControlsEnabled, isStatsEnabled, isDirectoriesEnabled) => {
            return [
                <box className={'dashboard-content-container'} vertical>
                    <box className={'dashboard-content-items'} vertical>
                        <Controls isEnabled={isControlsEnabled} />
                        <Directories isEnabled={isDirectoriesEnabled} />
                        <Stats isEnabled={isStatsEnabled} />
                    </box>
                </box>,
            ];
        },
    );

    return (
        <DropdownMenu
            name={'dashboardmenu'}
            transition={bind(transition).as((transition) => RevealerTransitionMap[transition])}
            onDestroy={() => {
                dashboardBinding.drop();
            }}
        >
            <box className={'dashboard-menu-content'} css={'padding: 1px; margin: -1px;'} vexpand={false}>
                {dashboardBinding()}
            </box>
        </DropdownMenu>
    );
};
