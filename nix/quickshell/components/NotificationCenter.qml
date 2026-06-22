import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

ModuleChip {
    id: root

    required property var panelWindow
    property list<var> notifications: []
    property var toastRecord: null
    property bool dnd: false
    property bool popupOpen: false

    icon: dnd ? "󰂛" : "󰂚"
    iconColor: notifications.length > 0 ? theme.popupDanger : theme.iconColor
    label: notifications.length > 0 ? String(notifications.length) : ""
    active: false
    activate: () => root.popupOpen = true

    NotificationServer {
        id: notificationServer

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        extraHints: ["desktop-entry", "sender-pid", "pid"]

        onNotification: notification => {
            if (root.dnd) {
                notification.dismiss();
                return;
            }

            notification.tracked = true;
            const record = {
                key: `${Date.now()}-${notification.id}`,
                notification,
                summary: notification.summary || "Notification",
                body: notification.body || "",
                appName: notification.appName || "App",
                appIcon: notification.appIcon || "",
                desktopEntry: notification.desktopEntry || "",
                hints: notification.hints || ({}),
                image: notification.image || "",
                time: new Date(),
                urgency: notification.urgency,
                resident: notification.resident,
                actions: notification.actions.map(action => ({
                    identifier: action.identifier || "",
                    text: action.text,
                    invoke: () => action.invoke()
                }))
            };
            console.log(`[notification] app=${record.appName} desktop=${record.desktopEntry} icon=${record.appIcon} summary=${record.summary} hints=${JSON.stringify(record.hints)} actions=${JSON.stringify(record.actions.map(action => ({ identifier: action.identifier, text: action.text })))}`);
            root.notifications = [record, ...root.notifications].slice(0, 30);
            root.showToast(record);
        }
    }

    Timer {
        id: toastTimer

        interval: 5000
        repeat: false
        onTriggered: root.toastRecord = null
    }

    PanelWindow {
        id: toastWindow

        visible: root.toastRecord !== null && !root.popupOpen
        screen: root.panelWindow.screen
        color: root.theme.transparentColor
        implicitWidth: root.theme.notificationPopupWidth + root.theme.gap * 2
        implicitHeight: root.theme.popupElementSize * 5

        anchors {
            top: true
            right: true
        }

        margins {
            top: root.theme.barOuterSpacing + root.theme.barHeight + root.theme.gap
            right: root.theme.popupScreenMargin
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-notification-toast"

        Item {
            id: toastFrame

            width: toastWindow.implicitWidth
            height: toastWindow.implicitHeight

            Loader {
                id: toastLoader

                active: root.toastRecord !== null
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.theme.gap
                sourceComponent: toastCardComponent
            }

            Component {
                id: toastCardComponent

                NotificationCard {
                    width: toastLoader.width
                    theme: root.theme
                    record: root.toastRecord
                    elevated: true
                    closeNotification: record => root.closeNotification(record)
                    removeNotification: record => root.removeNotification(record)
                }
            }
        }
    }

    PanelWindow {
        id: centerPopup

        visible: root.popupOpen
        screen: root.panelWindow.screen
        color: root.theme.transparentColor

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: root.popupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-notifications-popup"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: root.popupOpen = false
        }

        FocusScope {
            anchors.fill: parent
            focus: root.popupOpen
            Keys.onEscapePressed: root.popupOpen = false
        }

        Item {
            id: popupFrame

            width: popupContent.width
            height: popupContent.height
            x: root.popupX(width, centerPopup.width)
            y: root.theme.barOuterSpacing + root.theme.barHeight + root.theme.gap

            MouseArea { anchors.fill: parent }

            NotificationCenterPopup {
                id: popupContent

                theme: root.theme
                notifications: root.notifications
                dnd: root.dnd
                toggleDnd: () => root.dnd = !root.dnd
                clearAll: () => root.clearAll()
                closeNotification: record => root.closeNotification(record)
                removeNotification: record => root.removeNotification(record)
            }
        }
    }

    function removeNotification(record) {
        root.notifications = root.notifications.filter(notification => notification.key !== record.key);
        if (root.toastRecord && root.toastRecord.key === record.key) {
            root.toastRecord = null;
        }
    }

    function closeNotification(record) {
        root.removeNotification(record);
        record.notification?.dismiss();
    }

    function showToast(record) {
        root.toastRecord = record;
        toastTimer.restart();
    }

    function clearAll() {
        for (const notification of root.notifications) {
            notification.notification?.dismiss();
        }
        root.notifications = [];
    }
}
