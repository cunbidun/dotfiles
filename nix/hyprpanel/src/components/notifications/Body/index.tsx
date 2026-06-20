import AstalNotifd from 'gi://AstalNotifd?version=0.1';
import { Gtk } from 'astal/gtk3';
import { notifHasImg, formatNotificationMarkdown, getNotificationDisplayBody } from '../helpers';

export const Body = ({ notification }: BodyProps): JSX.Element => {
    const body = getNotificationDisplayBody(notification);
    const bodyMarkup = formatNotificationMarkdown(body);

    return (
        <box className={'notification-card-body'} valign={Gtk.Align.START} hexpand>
            <label
                className={'notification-card-body-label'}
                halign={Gtk.Align.START}
                label={bodyMarkup}
                maxWidthChars={!notifHasImg(notification) ? 58 : 48}
                lines={4}
                truncate
                wrap
                justify={Gtk.Justification.LEFT}
                hexpand
                useMarkup
                onRealize={(self) => self.set_markup(bodyMarkup)}
            />
        </box>
    );
};

interface BodyProps {
    notification: AstalNotifd.Notification;
}
