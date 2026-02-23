import { Gtk } from 'astal/gtk3';
import { setupOsdIcon } from './helpers';

export const OSDIcon = (): JSX.Element => {
    return (
        <label
            className={'osd-icon txt-icon'}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            setup={setupOsdIcon}
            hexpand={false}
            vexpand={false}
        />
    );
};
