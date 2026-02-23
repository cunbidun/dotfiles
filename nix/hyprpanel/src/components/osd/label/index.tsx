import { Gtk } from 'astal/gtk3';
import { setupOsdLabel } from './helpers';

export const OSDLabel = (): JSX.Element => {
    return (
        <label
            className={'osd-label'}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            setup={setupOsdLabel}
            hexpand={false}
            vexpand={false}
        />
    );
};
