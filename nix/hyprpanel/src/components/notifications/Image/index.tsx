import AstalNotifd from 'gi://AstalNotifd?version=0.1';
import { Gtk } from 'astal/gtk3';
import { isAnImage } from 'src/lib/validation/images';
import { notifHasImg } from '../helpers';

const isFileUrl = (value: string | null | undefined): boolean => {
    return typeof value === 'string' && value.startsWith('file://');
};

const imageUrlFor = (notification: AstalNotifd.Notification): string => {
    return notification.image || notification.appIcon;
};

const ImageItem = ({ notification }: ImageProps): JSX.Element => {
    const imageUrl = imageUrlFor(notification);
    const appIconIsImage = isAnImage(notification.appIcon) || isFileUrl(notification.appIcon);

    if (notification.appIcon && !appIconIsImage) {
        return (
            <icon
                className={'notification-card-image icon'}
                halign={Gtk.Align.CENTER}
                vexpand={false}
                icon={notification.appIcon}
            />
        );
    }

    return (
        <box
            className={'notification-card-image'}
            halign={Gtk.Align.CENTER}
            vexpand={false}
            css={`
                background-image: url('${imageUrl}');
            `}
        />
    );
};
export const Image = ({ notification }: ImageProps): JSX.Element => {
    if (!notifHasImg(notification)) {
        return <box />;
    }

    return (
        <box
            className={'notification-card-image-container'}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            vexpand={false}
        >
            <ImageItem notification={notification} />
        </box>
    );
};

interface ImageProps {
    notification: AstalNotifd.Notification;
}
