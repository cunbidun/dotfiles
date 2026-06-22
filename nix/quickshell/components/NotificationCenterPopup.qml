import QtQuick
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var theme
    property list<var> notifications: []
    property bool dnd: false
    property var toggleDnd: () => {}
    property var clearAll: () => {}
    property var closeNotification: record => {}
    property var removeNotification: record => {}

    width: theme.notificationPopupWidth
    height: theme.notificationPopupHeight
    implicitWidth: width
    implicitHeight: height
    radius: theme.popupSectionRadius
    color: theme.popupBackground
    border.width: theme.popupBorderWidth
    border.color: theme.popupBorder

    Column {
        id: shell

        anchors.fill: parent
        anchors.margins: root.theme.gap
        spacing: root.theme.gap * 0.75

        Item {
            id: header

            width: parent.width
            height: root.theme.popupElementSize

            Text {
                id: titleText

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.notifications.length > 0 ? `Notifications (${root.notifications.length})` : "Notifications"
                color: root.theme.popupText
                font.family: root.theme.fontFamilyEmphasis
                font.pixelSize: root.theme.fontSizeMedium
            }

            Rectangle {
                id: clearButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: root.theme.popupElementSize
                height: width
                radius: root.theme.popupSectionRadius
                visible: root.notifications.length > 0
                color: clearArea.containsMouse ? root.theme.chipHoverBackground : root.theme.transparentColor

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: clearArea.containsMouse ? root.theme.popupText : root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                }

                MouseArea {
                    id: clearArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: root.clearAll()
                }
            }

            Rectangle {
                id: dndButton

                anchors.right: clearButton.visible ? clearButton.left : parent.right
                anchors.rightMargin: clearButton.visible ? root.theme.gap : 0
                anchors.verticalCenter: parent.verticalCenter
                width: root.theme.popupElementSize
                height: width
                radius: root.theme.popupSectionRadius
                color: dndArea.containsMouse ? root.theme.chipHoverBackground : root.dnd ? root.theme.popupAccent : root.theme.transparentColor

                Text {
                    anchors.centerIn: parent
                    text: root.dnd ? "󰂛" : "󰂚"
                    color: root.dnd ? root.theme.popupBackground : root.theme.popupText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                }

                MouseArea {
                    id: dndArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: root.toggleDnd()
                }
            }

        }

        Rectangle {
            id: headerDivider

            width: parent.width
            height: 1
            color: root.theme.popupBorder
            opacity: 0.8
        }

        Rectangle {
            id: dndNotice

            width: parent.width
            height: root.dnd ? root.theme.popupElementSize : 0
            visible: root.dnd
            radius: root.theme.popupSectionRadius
            color: root.theme.popupSectionBackground
            border.width: 0

            Text {
                anchors.left: parent.left
                anchors.leftMargin: root.theme.gap
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - root.theme.gap * 2
                text: "Do Not Disturb"
                color: root.theme.popupMutedText
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeSmall
            }
        }

        Flickable {
            id: scrollArea

            width: parent.width
            height: Math.max(0, parent.height - header.height - parent.spacing - (dndNotice.visible ? dndNotice.height + parent.spacing : 0))
            contentWidth: width
            contentHeight: notificationColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: notificationColumn

                width: scrollArea.width
                spacing: root.theme.gap * 0.65

                Item {
                    width: parent.width
                    height: root.notifications.length === 0 ? root.theme.popupElementSize * 7 : 0
                    visible: root.notifications.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: root.theme.gap

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂛"
                            color: root.theme.iconMutedColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize * 2
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nothing to see here"
                            color: root.theme.popupMutedText
                            font.family: root.theme.fontFamilyEmphasis
                            font.pixelSize: root.theme.fontSize
                        }
                    }
                }

                Repeater {
                    model: root.notifications

                    NotificationCard {
                        required property var modelData

                        theme: root.theme
                        record: modelData
                        closeNotification: root.closeNotification
                        removeNotification: root.removeNotification
                    }
                }
            }
        }
    }
}
