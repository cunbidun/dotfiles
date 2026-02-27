import AstalNotifd from 'gi://AstalNotifd?version=0.1';
import options from 'src/configuration';
import { GLib } from 'astal';
import { Gtk } from 'astal/gtk3';
import { notifHasImg, escapeMarkup, normalizeNotificationText } from '../helpers';
import { getNotificationIcon } from 'src/lib/shared/notifications';

const { military } = options.menus.clock.time;

export const Header = ({ notification }: HeaderProps): JSX.Element => {
    return (
        <box vertical={false} hexpand>
            <NotificationIcon notification={notification} />
            <SummaryLabel notification={notification} />
            <TimeLabel notification={notification} />
        </box>
    );
};

const NotificationIcon = ({ notification }: HeaderProps): JSX.Element => {
    const { appName, appIcon, desktopEntry } = notification;

    return (
        <box className={'notification-card-header'} halign={Gtk.Align.START}>
            <box css={'min-width: 2rem; min-height: 2rem; '}>
                <icon
                    className={'notification-icon'}
                    icon={getNotificationIcon(appName, appIcon, desktopEntry)}
                />
            </box>
        </box>
    );
};

const SummaryLabel = ({ notification }: HeaderProps): JSX.Element => {
    const summary = normalizeNotificationText(notification.summary);

    return (
        <box className={'notification-card-header'} halign={Gtk.Align.START} valign={Gtk.Align.START} hexpand>
            <label
                className={'notification-card-header-label'}
                halign={Gtk.Align.START}
                onRealize={(self) => self.set_markup(escapeMarkup(summary))}
                label={escapeMarkup(summary)}
                maxWidthChars={!notifHasImg(notification) ? 42 : 30}
                hexpand
                vexpand
                lines={2}
                wrap
            />
        </box>
    );
};

const TimeLabel = ({ notification }: HeaderProps): JSX.Element => {
    const time = (time: number, format = '%I:%M %p'): string => {
        return GLib.DateTime.new_from_unix_local(time).format(military.get() ? '%H:%M' : format) ?? '--';
    };

    return (
        <box
            className={'notification-card-header menu'}
            halign={Gtk.Align.END}
            valign={Gtk.Align.START}
        >
            <label className={'notification-time'} label={time(notification.time)} vexpand />
        </box>
    );
};

interface HeaderProps {
    notification: AstalNotifd.Notification;
}
