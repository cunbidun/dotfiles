import AstalTray from 'gi://AstalTray?version=0.1';
import { bind, exec, Gio, Variable } from 'astal';
import { readFile } from 'astal/file';
import { GLib } from 'astal/gobject';
import { Gdk, Gtk } from 'astal/gtk3';
import { BarBoxChild } from 'src/components/bar/types';
import options from 'src/configuration';
import { isPrimaryClick, isSecondaryClick, isMiddleClick } from 'src/lib/events/mouse';
import { SystemUtilities } from 'src/core/system/SystemUtilities';

const systemtray = AstalTray.get_default();
const { ignore, customIcons } = options.bar.systray;
const stylixThemeNamePath = `${GLib.get_home_dir()}/.local/state/stylix/current-theme-name.txt`;

const getThemePolarity = (): 'light' | 'dark' => {
    try {
        return readFile(stylixThemeNamePath).trim().endsWith('-light') ? 'light' : 'dark';
    } catch {
        return 'dark';
    }
};

const getFcitxInputMethod = (): string => {
    try {
        const output = exec(
            'bash -lc "gdbus call --session --dest org.fcitx.Fcitx5 --object-path /controller --method org.fcitx.Fcitx.Controller1.CurrentInputMethod 2>/dev/null || true"',
        );
        return output.match(/\('([^']+)'/)?.[1] ?? '';
    } catch {
        return '';
    }
};

const createMenu = (menuModel: Gio.MenuModel, actionGroup: Gio.ActionGroup | null): Gtk.Menu => {
    const menu = Gtk.Menu.new_from_model(menuModel);
    menu.insert_action_group('dbusmenu', actionGroup);
    menu.get_style_context().add_class('systray-popup-menu');

    return menu;
};

const MenuCustomIcon = ({ iconLabel, iconColor, iconSize, item }: MenuCustomIconProps): JSX.Element => {
    return (
        <label
            className={'systray-icon txt-icon'}
            label={iconLabel}
            css={iconColor ? `color: ${iconColor}; font-size: ${iconSize}` : ''}
            tooltipMarkup={bind(item, 'tooltipMarkup')}
        />
    );
};

const MenuCustomFileIcon = ({ iconFile, iconSize, item }: MenuCustomFileIconProps): JSX.Element => {
    const resolvedIconFile = iconFile.startsWith('/') ? iconFile : `${CONFIG_DIR}/${iconFile}`;
    const gicon = new Gio.FileIcon({ file: Gio.File.new_for_path(resolvedIconFile) });

    return (
        <icon
            className={'systray-icon'}
            gicon={gicon}
            css={iconSize ? `font-size: ${iconSize};` : ''}
            tooltipMarkup={bind(item, 'tooltipMarkup')}
        />
    );
};

const MenuFcitxInputMethodIcon = ({
    defaultInputMethodLabel,
    iconSize,
    inputMethodLabels,
    item,
}: MenuFcitxInputMethodIconProps): JSX.Element => {
    const inputMethodLabel = bind(item, 'gicon').as(
        () => inputMethodLabels[getFcitxInputMethod()] ?? defaultInputMethodLabel,
    );

    return (
        <label
            className={'systray-icon systray-input-method txt-icon'}
            label={inputMethodLabel}
            css={`font-size: ${iconSize};`}
            tooltipText={inputMethodLabel.as((label) => `Input method: ${label}`)}
        />
    );
};

const MenuDefaultIcon = ({ item }: MenuEntryProps): JSX.Element => {
    return (
        <icon
            className={'systray-icon'}
            gicon={bind(item, 'gicon')}
            tooltipMarkup={bind(item, 'tooltipMarkup')}
        />
    );
};

const MenuEntry = ({ item, child }: MenuEntryProps): JSX.Element => {
    let menu: Gtk.Menu;

    const entryBinding = Variable.derive(
        [bind(item, 'menuModel'), bind(item, 'actionGroup')],
        (menuModel, actionGroup) => {
            if (menuModel === null) {
                return console.error(`Menu Model not found for ${item.id}`);
            }
            if (actionGroup === null) {
                return console.error(`Action Group not found for ${item.id}`);
            }

            menu = createMenu(menuModel, actionGroup);
        },
    );

    return (
        <button
            cursor={'pointer'}
            onClick={(self, event) => {
                if (isPrimaryClick(event)) {
                    item.activate(0, 0);
                }

                if (isSecondaryClick(event)) {
                    menu?.popup_at_widget(self, Gdk.Gravity.NORTH, Gdk.Gravity.SOUTH, null);
                }

                if (isMiddleClick(event)) {
                    SystemUtilities.notify({ summary: 'App Name', body: item.id });
                }
            }}
            onDestroy={() => {
                menu?.destroy();
                entryBinding.drop();
            }}
        >
            {child}
        </button>
    );
};

const SysTray = (): BarBoxChild => {
    const isVis = Variable(false);

    const componentChildren = Variable.derive(
        [bind(systemtray, 'items'), bind(ignore), bind(customIcons)],
        (items, ignored, custIcons) => {
            const filteredTray = items.filter(({ id }) => !ignored.includes(id) && id !== null);

            isVis.set(filteredTray.length > 0);

            return filteredTray.map((item) => {
                const matchedCustomIcon = Object.keys(custIcons).find((iconRegex) =>
                    item.id.match(iconRegex),
                );

                if (matchedCustomIcon !== undefined) {
                    const customIcon = custIcons[matchedCustomIcon];
                    const themeFile =
                        getThemePolarity() === 'light' ? customIcon.lightFile : customIcon.darkFile;
                    const iconLabel = customIcon.icon || '󰠫';
                    const iconColor = customIcon.color;
                    const iconSize = customIcon.size || '16px';
                    const iconFile = themeFile || customIcon.file;

                    return (
                        <MenuEntry item={item}>
                            {customIcon.inputMethodLabels ? (
                                <MenuFcitxInputMethodIcon
                                    defaultInputMethodLabel={
                                        customIcon.defaultInputMethodLabel ?? iconLabel
                                    }
                                    iconSize={iconSize}
                                    inputMethodLabels={customIcon.inputMethodLabels}
                                    item={item}
                                />
                            ) : iconFile ? (
                                <MenuCustomFileIcon iconFile={iconFile} iconSize={iconSize} item={item} />
                            ) : (
                                <MenuCustomIcon
                                    iconLabel={iconLabel}
                                    iconColor={iconColor}
                                    iconSize={iconSize}
                                    item={item}
                                />
                            )}
                        </MenuEntry>
                    );
                }
                return (
                    <MenuEntry item={item}>
                        <MenuDefaultIcon item={item} />
                    </MenuEntry>
                );
            });
        },
    );

    const component = (
        <box
            className={'systray-container'}
            onDestroy={() => {
                isVis.drop();
                componentChildren.drop();
            }}
        >
            {componentChildren()}
        </box>
    );

    return {
        component,
        isVisible: true,
        boxClass: 'systray',
        isVis: bind(isVis),
        isBox: true,
        props: {},
    };
};

interface MenuCustomIconProps {
    iconLabel: string;
    iconColor?: string;
    iconSize: string;
    item: AstalTray.TrayItem;
}

interface MenuCustomFileIconProps {
    iconFile: string;
    iconSize: string;
    item: AstalTray.TrayItem;
}

interface MenuFcitxInputMethodIconProps {
    defaultInputMethodLabel: string;
    iconSize: string;
    inputMethodLabels: Record<string, string>;
    item: AstalTray.TrayItem;
}

interface MenuEntryProps {
    item: AstalTray.TrayItem;
    child?: JSX.Element;
}

export { SysTray };
