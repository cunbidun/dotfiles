import { Astal } from 'astal/gtk3';
import { dropdownMenuList } from '../../components/settings/constants';
import { FontStyle } from 'src/components/settings/shared/inputs/font/utils';
import { Variable } from 'astal';
import { LabelSettingProps } from 'src/components/settings/shared/Label';
import { Opt } from './opt';

export interface MkOptionsResult {
    toArray: () => Opt[];
    reset: () => Promise<string>;
    handler: (optionsToWatch: string[], callback: () => void) => void;
}

export type OptionsObject = Record<string, unknown>;

export type BarLocation = 'top' | 'bottom';
export type AutoHide = 'never' | 'fullscreen' | 'single-window';
export type BarModule =
    | 'battery'
    | 'dashboard'
    | 'workspaces'
    | 'windowtitle'
    | 'media'
    | 'notifications'
    | 'volume'
    | 'network'
    | 'bluetooth'
    | 'clock'
    | 'ram'
    | 'cpu'
    | 'cputemp'
    | 'storage'
    | 'netstat'
    | 'kbinput'
    | 'updates'
    | 'submap'
    | 'weather'
    | 'power'
    | 'systray'
    | 'hypridle'
    | 'cava';

export type BarLayout = {
    left: BarModule[];
    middle: BarModule[];
    right: BarModule[];
    extends?: string;
};
export type BarLayouts = {
    [key: string]: BarLayout;
};

export type PowerOptions = 'sleep' | 'reboot' | 'logout' | 'shutdown';
export type NotificationAnchor =
    | 'top'
    | 'top right'
    | 'top left'
    | 'bottom'
    | 'bottom right'
    | 'bottom left'
    | 'left'
    | 'right';
export type OSDAnchor =
    | 'top left'
    | 'top'
    | 'top right'
    | 'right'
    | 'bottom right'
    | 'bottom'
    | 'bottom left'
    | 'left';
export type BarButtonStyles = 'default' | 'split' | 'wave' | 'wave2';

export type ThemeExportData = {
    filePath: string;
    themeOnly: boolean;
};
type InputType =
    | 'number'
    | 'color'
    | 'float'
    | 'object'
    | 'string'
    | 'enum'
    | 'boolean'
    | 'img'
    | 'wallpaper'
    | 'export'
    | 'import'
    | 'config_import'
    | 'font';

export interface RowProps<T> {
    opt: Opt<T>;
    note?: string;
    type?: InputType;
    enums?: T[];
    max?: number;
    min?: number;
    disabledBinding?: Variable<boolean>;
    exportData?: ThemeExportData;
    subtitle?: LabelSettingProps['subtitle'];
    subtitleLink?: string;
    dependencies?: string[];
    increment?: number;
    fontStyle?: Opt<FontStyle>;
    fontLabel?: Opt<string>;
}

export type OSDOrientation = 'horizontal' | 'vertical';

export type HexColor = `#${string}`;

export type WindowLayer = 'top' | 'bottom' | 'overlay' | 'background';

export type ActiveWsIndicator = 'underline' | 'highlight' | 'color';

export type ScalingPriority = 'gdk' | 'hyprland' | 'both';

export type BorderLocation =
    | 'none'
    | 'top'
    | 'right'
    | 'bottom'
    | 'left'
    | 'horizontal'
    | 'vertical'
    | 'full';

export type PositionAnchor = { [key: string]: Astal.WindowAnchor };

export type DropdownMenuList = (typeof dropdownMenuList)[number];
