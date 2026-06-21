//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"

ShellRoot {
    id: shell

    property bool settingsVisible: false
    property string settingsTab: "network"
    property string settingsScreenName: ""

    Theme {
        id: shellTheme
    }

    function openSettings(tab, targetScreen) {
        settingsTab = tab || "network";
        settingsScreenName = targetScreen ? targetScreen.name : "";
        settingsVisible = true;
    }

    function closeSettings() {
        settingsVisible = false;
    }

    Component.onCompleted: Quickshell.watchFiles = true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow

            required property var modelData

            screen: modelData
            color: shellTheme.transparentColor
            implicitHeight: shellTheme.barHeight
            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: shellTheme.barOuterSpacing
                left: shellTheme.barOuterSpacing
                right: shellTheme.barOuterSpacing
            }
            exclusiveZone: shellTheme.barHeight + shellTheme.barOuterSpacing

            Bar {
                anchors.fill: parent
                theme: shellTheme
                screen: barWindow.screen
                panelWindow: barWindow
                openSettings: tab => shell.openSettings(tab, barWindow.screen)
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: settingsWindow

            required property var modelData

            screen: modelData
            visible: shell.settingsVisible && (shell.settingsScreenName.length === 0 || modelData.name === shell.settingsScreenName)
            color: shellTheme.transparentColor

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "quickshell-settings-popup"

            SystemSettingsPanel {
                anchors.fill: parent
                theme: shellTheme
                currentTab: shell.settingsTab
                close: shell.closeSettings
                onCurrentTabChanged: shell.settingsTab = currentTab
            }
        }
    }
}
