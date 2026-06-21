import QtQuick
import Quickshell
import Quickshell.Wayland

ModuleChip {
    id: root

    required property var panelWindow

    property bool popupOpen: false

    icon: "󰃭"
    iconColor: theme.clockIcon
    label: clock.date.toLocaleString(Qt.locale(), "ddd MMM d  hh:mm:ss AP")
    maxLabelWidth: theme.clockMaxWidth
    activate: () => root.popupOpen = true

    PanelWindow {
        id: calendarPopup

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
        WlrLayershell.namespace: "quickshell-calendar-popup"

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
            x: root.popupX(width, calendarPopup.width)
            y: root.theme.barOuterSpacing + root.theme.barHeight + root.theme.gap

            MouseArea { anchors.fill: parent }

            CalendarWeatherPopup {
                id: popupContent

                theme: root.theme
            }
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
