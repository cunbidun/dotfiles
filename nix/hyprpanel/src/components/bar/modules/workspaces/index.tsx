import { WorkspaceModule } from './workspaces';
import { BarBoxChild } from 'src/components/bar/types';

const Workspaces = (monitor = -1): BarBoxChild => {
    const component = (
        <box className={'workspaces-box-container'}>
            <WorkspaceModule monitor={monitor} />
        </box>
    );

    return {
        component,
        isVisible: true,
        boxClass: 'workspaces',
        isBox: true,
    };
};

export { Workspaces };
