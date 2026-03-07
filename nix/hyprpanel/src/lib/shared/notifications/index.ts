import AstalNotifd from 'gi://AstalNotifd?version=0.1';
import { Variable } from 'astal';
import { iconExists } from 'src/lib/icons/helpers';
import icons from 'src/lib/icons/icons';

const normalizeName = (name: string): string => name.toLowerCase().replace(/\s+/g, '_');
const MAX_CLEAR_DURATION_MS = 300;

const normalizeNotificationFilter = (filter: string[]): Set<string> => {
    return new Set(filter.map(normalizeName));
};

export const removingNotifications = Variable(false);

export const isNotificationIgnored = (
    notification: AstalNotifd.Notification | null,
    filter: string[],
    normalizedFilter?: Set<string>,
): boolean => {
    if (!notification) {
        return false;
    }

    const notificationFilters = normalizedFilter ?? normalizeNotificationFilter(filter);
    const normalizedAppName = normalizeName(notification.app_name);

    return notificationFilters.has(normalizedAppName);
};

export const filterNotifications = (
    notifications: AstalNotifd.Notification[],
    filter: string[],
): AstalNotifd.Notification[] => {
    const notificationFilters = normalizeNotificationFilter(filter);

    const filteredNotifications = notifications.filter((notif) => {
        return !isNotificationIgnored(notif, filter, notificationFilters);
    });

    return filteredNotifications;
};

export const getNotificationIcon = (app_name: string, app_icon: string, app_entry: string): string => {
    const icon = icons.fallback.notification;

    if (iconExists(app_name)) {
        return app_name;
    } else if (app_name && iconExists(app_name.toLowerCase())) {
        return app_name.toLowerCase();
    }

    if (app_icon && iconExists(app_icon)) {
        return app_icon;
    }

    if (app_entry && iconExists(app_entry)) {
        return app_entry;
    }

    return icon;
};

export const clearNotifications = async (
    notifications: AstalNotifd.Notification[],
    delay: number,
): Promise<void> => {
    removingNotifications.set(true);
    try {
        const notificationCount = notifications.length;

        if (notificationCount <= 0) {
            return;
        }

        const baseDelay = Math.max(0, delay);
        const effectiveDelay =
            baseDelay === 0
                ? 0
                : Math.min(baseDelay, Math.max(1, Math.floor(MAX_CLEAR_DURATION_MS / notificationCount)));

        for (const notification of notifications) {
            notification.dismiss();

            if (effectiveDelay > 0) {
                await new Promise((resolve) => setTimeout(resolve, effectiveDelay));
            }
        }
    } finally {
        removingNotifications.set(false);
    }
};
