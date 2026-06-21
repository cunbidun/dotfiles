import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
    id: root

    required property var theme
    required property var record
    property var closeNotification: record => {}
    readonly property var safeRecord: record || ({})
    readonly property var visibleActions: (safeRecord.actions || []).filter(action => String(action.text || "").trim().length > 0).slice(0, 3)

    width: parent.width
    height: cardContent.implicitHeight + theme.gap * 1.15
    radius: theme.popupSectionRadius
    color: cardHoverArea.containsMouse ? theme.chipHoverBackground : theme.popupSectionBackground
    border.width: safeRecord.urgency === NotificationUrgency.Critical ? theme.popupBorderWidth : 0
    border.color: theme.popupDanger

    MouseArea {
        id: cardHoverArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
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
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.88
                    font.bold: true
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
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 0.82
                        font.bold: true
                    }

                    Text {
                        id: timeLabel

                        text: root.timeLabel(root.safeRecord.time)
                        color: root.theme.popupMutedText
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 0.74
                    }
                }

                Text {
                    width: parent.width
                    text: root.safeRecord.summary || "Notification"
                    color: root.theme.popupText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize * 0.92
                    font.bold: true
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
                    font.pixelSize: root.theme.fontSize * 0.82
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
                    font.pixelSize: root.theme.fontSize * 0.78
                }

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.record) root.closeNotification(root.record)
                }
            }
        }

        Row {
            width: parent.width
            visible: root.visibleActions.length > 0
            spacing: root.theme.gap * 0.55

            Repeater {
                model: root.visibleActions

                Rectangle {
                    required property var modelData

                    width: (cardContent.width - root.theme.gap * 0.55 * (root.visibleActions.length - 1)) / root.visibleActions.length
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
                        font.pixelSize: root.theme.fontSize * 0.8
                        font.bold: true
                    }

                    MouseArea {
                        id: actionArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke();
                            root.closeNotification(root.record);
                        }
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

    function activateNotification() {
        if (!root.record) {
            return;
        }

        const actions = root.safeRecord.actions || [];
        const notification = root.safeRecord.notification;
        const defaultAction = actions.find(action => String(action.identifier || "") === "default") || null;
        let activated = false;

        if (notification && typeof notification.activate === "function") {
            notification.activate();
            activated = true;
        } else if (defaultAction && typeof defaultAction.invoke === "function") {
            defaultAction.invoke();
            activated = true;
        } else if (actions.length === 1 && typeof actions[0].invoke === "function") {
            actions[0].invoke();
            activated = true;
        }

        if (activated) {
            root.closeNotification(root.record);
        }
    }
}
