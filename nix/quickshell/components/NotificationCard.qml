import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
    id: root

    required property var theme
    required property var record
    property bool elevated: false
    property var closeNotification: record => {}
    property var removeNotification: record => {}
    readonly property var safeRecord: record || ({})
    readonly property var allActions: safeRecord.actions || []
    readonly property var visibleActions: allActions.filter(action => String(action.text || "").trim().length > 0).slice(0, 3)

    width: parent.width
    height: cardContent.implicitHeight + theme.gap * 1.15
    radius: theme.popupSectionRadius
    color: cardHoverArea.containsMouse ? theme.chipHoverBackground : (root.elevated ? theme.popupElevatedBackground : theme.popupSectionBackground)
    border.width: theme.popupBorderWidth
    border.color: safeRecord.urgency === NotificationUrgency.Critical ? theme.popupDanger : (root.elevated ? theme.popupElevatedBorder : theme.popupBorder)

    layer.enabled: root.elevated
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#73000000"
        shadowBlur: 0.6
        shadowVerticalOffset: 4
        autoPaddingEnabled: true
    }

    MouseArea {
        id: cardHoverArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onClicked: root.activateNotification()
    }

    Column {
        id: cardContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.theme.gap * 0.58
        spacing: root.theme.gap * 0.5

        Row {
            width: parent.width
            spacing: root.theme.gap * 0.8

            Item {
                width: root.theme.popupElementSize
                height: width
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    id: appIcon

                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.safeRecord.appIcon || ""
                    asynchronous: true
                    mipmap: true
                    smooth: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    text: root.fallbackIconText(root.safeRecord.appName)
                    color: root.theme.iconColor
                    font.family: root.theme.fontFamilyEmphasis
                    font.pixelSize: root.theme.fontSizeSmall
                }
            }

            Column {
                width: Math.max(root.theme.popupElementSize * 4, parent.width - root.theme.popupElementSize - closeButton.width - parent.spacing * 2)
                spacing: root.theme.gap * 0.22

                Row {
                    width: parent.width
                    spacing: root.theme.gap * 0.5

                    Text {
                        width: parent.width - timeLabel.width - parent.spacing
                        text: root.safeRecord.appName || "App"
                        color: root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamilyEmphasis
                        font.pixelSize: root.theme.fontSizeSmall
                    }

                    Text {
                        id: timeLabel

                        text: root.timeLabel(root.safeRecord.time)
                        color: root.theme.popupMutedText
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSizeSmall
                    }
                }

                Text {
                    width: parent.width
                    text: root.safeRecord.summary || "Notification"
                    color: root.theme.popupText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamilyEmphasis
                    font.pixelSize: root.theme.fontSizeMedium
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: root.stripMarkup(root.safeRecord.body || "")
                    color: root.theme.popupText
                    opacity: 0.85
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }
            }

            Rectangle {
                id: closeButton

                width: root.theme.popupElementSize * 0.82
                height: width
                radius: width / 2
                color: closeArea.containsMouse ? root.theme.chipHoverBackground : root.theme.transparentColor
                opacity: closeArea.containsMouse || cardHoverArea.containsMouse ? 1 : 0.45

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                }

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: if (root.record) root.closeNotification(root.record)
                }
            }
        }

        Row {
            width: parent.width
            spacing: root.theme.gap * 0.55
            visible: root.visibleActions.length > 0
            height: visible ? implicitHeight : 0

            Repeater {
                model: root.visibleActions

                Rectangle {
                    required property var modelData

                    width: (parent.width - parent.spacing * (root.visibleActions.length - 1)) / root.visibleActions.length
                    height: root.theme.popupElementSize * 0.78
                    radius: root.theme.popupSectionRadius
                    color: actionArea.containsMouse ? root.theme.chipHoverBackground : root.theme.popupHoverBackground

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - root.theme.gap
                        text: modelData.text || "Open"
                        color: root.theme.popupAccent
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSizeSmall
                        font.bold: true
                    }

                    MouseArea {
                        id: actionArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: root.invokeAction(modelData)
                    }
                }
            }
        }

    }

    function timeLabel(date) {
        const value = date || new Date();
        return value.toLocaleTimeString(Qt.locale(), "hh:mm AP");
    }

    function fallbackIconText(appName) {
        const value = String(appName || "?");
        return value.length > 0 ? value[0].toUpperCase() : "?";
    }

    function stripMarkup(text) {
        return text.replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    }

    function invokeNotificationAction() {
        const actions = root.allActions;
        const defaultAction = actions.find(action => String(action.identifier || "") === "default") || null;
        if (defaultAction && typeof defaultAction.invoke === "function") {
            return root.invokeAction(defaultAction);
        }

        if (actions.length === 1 && typeof actions[0].invoke === "function") {
            return root.invokeAction(actions[0]);
        }

        return false;
    }

    function invokeAction(action) {
        if (!action || typeof action.invoke !== "function") {
            return false;
        }

        const focusAfterAction = root.shouldFocusAfterAction(action);
        const focusRecord = root.focusRecord(root.safeRecord);
        action.invoke();
        if (focusAfterAction) {
            root.activateMatchingToplevel(focusRecord);
        }
        if (!root.safeRecord.resident) {
            root.removeNotification(root.record);
        }
        return true;
    }

    function shouldFocusAfterAction(action) {
        const key = `${String(action.identifier || "")} ${String(action.text || "")}`.toLowerCase();
        return key.includes("default") || key.includes("open") || key.includes("activate") || key.includes("active");
    }

    function focusRecord(record) {
        return {
            appName: record.appName || "",
            appIcon: record.appIcon || "",
            desktopEntry: record.desktopEntry || "",
            hints: record.hints || ({}),
            summary: record.summary || ""
        };
    }

    function activateMatchingToplevel(record) {
        const target = root.matchingToplevel(record);
        if (target && target.address) {
            const windowAddress = root.hyprlandWindowAddress(target.address);
            console.log(`[notification-focus] focusing window=${windowAddress} class=${root.toplevelClass(target)} title=${target.title}`);
            Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ window = ${JSON.stringify(windowAddress)} })` : `focuswindow ${windowAddress}`);
        } else if (target?.wayland && typeof target.wayland.activate === "function") {
            console.log(`[notification-focus] activating title=${target.title}`);
            target.wayland.activate();
        } else {
            console.log(`[notification-focus] no match app=${record?.appName || ""} desktop=${record?.desktopEntry || ""} icon=${record?.appIcon || ""} summary=${record?.summary || ""}`);
        }
    }

    function matchingToplevel(record) {
        const appName = root.normalizeToken(record?.appName);
        const desktopEntry = root.normalizeToken(record?.desktopEntry || record?.hints?.["desktop-entry"] || record?.appIcon);
        const titleHint = String(record?.summary || "").toLowerCase();
        const windows = Hyprland.toplevels.values;

        if (windows.length === 0) {
            return null;
        }

        const titleMatch = windows.find(toplevel => titleHint.length > 0 && String(toplevel.title || "").toLowerCase().includes(titleHint));
        if (titleMatch) {
            return titleMatch;
        }

        const appMatches = windows.filter(toplevel => {
            const appId = root.normalizeToken(root.toplevelClass(toplevel));
            return root.tokensMatch(appId, desktopEntry) || root.tokensMatch(appId, appName);
        }).sort((left, right) => root.focusHistoryId(left) - root.focusHistoryId(right));
        if (appMatches.length === 1) {
            return appMatches[0];
        }
        if (appMatches.length > 1) {
            const target = appMatches[0];
            console.log(`[notification-focus] recency fallback count=${appMatches.length} address=${target.address} class=${root.toplevelClass(target)} title=${target.title}`);
            return target;
        }

        return null;
    }

    function toplevelClass(toplevel) {
        const ipc = toplevel?.lastIpcObject || ({});
        return ipc.class || ipc.initialClass || "";
    }

    function focusHistoryId(toplevel) {
        const value = Number(toplevel?.lastIpcObject?.focusHistoryID);
        return Number.isFinite(value) ? value : 999999;
    }

    function hyprlandWindowAddress(address) {
        const value = String(address || "").replace(/^0x/, "");
        return `address:0x${value}`;
    }

    function normalizeToken(value) {
        return String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]+/g, "");
    }

    function tokensMatch(left, right) {
        if (left.length === 0 || right.length === 0) {
            return false;
        }

        return left.includes(right) || right.includes(left);
    }

    function activateNotification() {
        if (!root.record) {
            return;
        }

        root.invokeNotificationAction();
    }
}
