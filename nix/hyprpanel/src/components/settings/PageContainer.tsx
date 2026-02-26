import { Gtk } from 'astal/gtk3';

export const PageContainer = (): JSX.Element => {
    return (
        <box className={'settings-page-container'} halign={Gtk.Align.FILL} vertical>
            <box className={'settings-page-container2'} halign={Gtk.Align.FILL} hexpand>
                <label className={'settings-disabled-label'} label={'Settings pages removed'} halign={Gtk.Align.CENTER} />
            </box>
        </box>
    );
};
