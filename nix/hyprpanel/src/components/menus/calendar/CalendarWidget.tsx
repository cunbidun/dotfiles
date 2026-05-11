import { Gtk } from 'astal/gtk3';
import { bind, Variable } from 'astal';
import Calendar from 'src/components/shared/Calendar';

const monthLabel = (date: Date): string => date.toLocaleString(undefined, { month: 'short' });

export const CalendarWidget = (): JSX.Element => {
    const visibleDate = Variable(new Date());
    let calendar: Calendar | undefined;

    const selectTodayOnly = (date: Date): void => {
        const today = new Date();
        const isCurrentMonth = date.getMonth() === today.getMonth() && date.getFullYear() === today.getFullYear();

        calendar?.select_day(isCurrentMonth ? today.getDate() : 0);
    };

    const setVisibleDate = (monthDelta: number, yearDelta = 0): void => {
        const current = visibleDate.get();
        const next = new Date(current.getFullYear() + yearDelta, current.getMonth() + monthDelta, 1);

        visibleDate.set(next);
        calendar?.select_month(next.getMonth(), next.getFullYear());
        selectTodayOnly(next);
    };

    return (
        <box
            className={'calendar-menu-item-container calendar'}
            halign={Gtk.Align.FILL}
            valign={Gtk.Align.FILL}
            expand
        >
            <box className={'calendar-container-box'} vertical>
                <box className={'calendar-menu-heading'} halign={Gtk.Align.CENTER}>
                    <box className={'calendar-menu-heading-group'}>
                        <button className={'calendar-menu-heading-button'} onClick={() => setVisibleDate(-1)}>
                            <label label={'‹'} />
                        </button>
                        <label
                            className={'calendar-menu-heading-label'}
                            halign={Gtk.Align.CENTER}
                            xalign={0.5}
                            label={bind(visibleDate).as(monthLabel)}
                        />
                        <button className={'calendar-menu-heading-button'} onClick={() => setVisibleDate(1)}>
                            <label label={'›'} />
                        </button>
                    </box>

                    <box className={'calendar-menu-heading-group'}>
                        <button className={'calendar-menu-heading-button'} onClick={() => setVisibleDate(0, -1)}>
                            <label label={'‹'} />
                        </button>
                        <label
                            className={'calendar-menu-heading-label'}
                            halign={Gtk.Align.CENTER}
                            xalign={0.5}
                            label={bind(visibleDate).as((date) => date.getFullYear().toString())}
                        />
                        <button className={'calendar-menu-heading-button'} onClick={() => setVisibleDate(0, 1)}>
                            <label label={'›'} />
                        </button>
                    </box>
                </box>

                <Calendar
                    className={'calendar-menu-widget'}
                    setup={(self) => {
                        calendar = self;
                    }}
                    halign={Gtk.Align.FILL}
                    valign={Gtk.Align.FILL}
                    showDetails={false}
                    expand
                    showDayNames
                    showHeading={false}
                />
            </box>
        </box>
    );
};
