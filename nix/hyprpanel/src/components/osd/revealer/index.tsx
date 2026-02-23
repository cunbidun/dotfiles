import { Gtk } from 'astal/gtk3';
import { OSDBar } from '../bar';
import { revealerSetup } from '../helpers';
import { OSDIcon } from '../icon';
import { OSDLabel } from '../label';

const DynamicContextOsd = (): JSX.Element => (
    <box className={'osd-shell'}>
        <OSDIcon />
        <OSDBar orientation={'horizontal'} />
        <OSDLabel />
    </box>
);

export const OsdRevealer = (): JSX.Element => {
    return (
        <revealer
            transitionType={Gtk.RevealerTransitionType.CROSSFADE}
            revealChild={false}
            setup={(self) => {
                revealerSetup(self);
            }}
        >
            <box className={'osd-container'}>
                <DynamicContextOsd />
            </box>
        </revealer>
    );
};
