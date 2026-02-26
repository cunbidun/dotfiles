import { Clock } from '../modules/clock';
import { Menu } from '../modules/menu';
import { Notifications } from '../modules/notifications';
import { ModuleSeparator } from '../modules/separator';
import { Submap } from '../modules/submap';
import { SysTray } from '../modules/systray';
import { ClientTitle } from '../modules/window_title';
import { Workspaces } from '../modules/workspaces';
import { WidgetContainer } from '../shared/widgetContainer';
import { WidgetFactory } from './WidgetRegistry';

export function getCoreWidgets(): Record<string, WidgetFactory> {
    return {
        dashboard: () => WidgetContainer(Menu()),
        workspaces: (monitor: number) => WidgetContainer(Workspaces(monitor)),
        windowtitle: () => WidgetContainer(ClientTitle()),
        notifications: () => WidgetContainer(Notifications()),
        clock: () => WidgetContainer(Clock()),
        systray: () => WidgetContainer(SysTray()),
        submap: () => WidgetContainer(Submap()),
        separator: () => ModuleSeparator(),
    };
}
