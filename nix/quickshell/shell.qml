import QtQuick
import Quickshell
import "components"

ShellRoot {
    id: shell

    Component.onCompleted: Quickshell.watchFiles = true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow

            required property var modelData

            Theme {
                id: theme
            }

            screen: modelData
            color: theme.transparentColor
            implicitHeight: theme.barHeight
            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: theme.barOuterSpacing
                left: theme.barOuterSpacing
                right: theme.barOuterSpacing
            }
            exclusiveZone: theme.barHeight + theme.barOuterSpacing

            Bar {
                anchors.fill: parent
                theme: theme
                screen: barWindow.screen
            }
        }
    }
}
