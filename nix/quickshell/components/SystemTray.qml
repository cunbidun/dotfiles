import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

Rectangle {
    id: root

    required property var theme
    required property var panelWindow
    property string fcitxInputMethod: ""
    property int fcitxState: 0
    property var activeTrayItem: null
    property var menuStack: []
    property bool menuOpen: false
    property real menuAnchorX: 0
    property real menuAnchorY: 0
    readonly property var activeMenuHandle: menuStack.length > 0 ? menuStack[menuStack.length - 1] : (activeTrayItem ? activeTrayItem.menu : null)
    readonly property bool hasFcitxTrayItem: SystemTray.items.values.some(item => root.isFcitx(item.id))

    readonly property string iconRoot: `${Quickshell.env("HOME")}/dotfiles/nix/quickshell/assets/icons`

    visible: trayItems.count > 0
    implicitWidth: trayContent.implicitWidth + theme.chipPaddingX * 2
    implicitHeight: theme.barItemHeight
    width: implicitWidth
    height: implicitHeight
    radius: theme.chipRadius
    color: theme.chipBackground

    Component.onCompleted: if (hasFcitxTrayItem) refreshFcitx()
    onVisibleChanged: if (visible && hasFcitxTrayItem) refreshFcitx()
    onHasFcitxTrayItemChanged: if (hasFcitxTrayItem) refreshFcitx()

    Row {
        id: trayContent

        anchors.centerIn: parent
        spacing: root.theme.trayGap

        Repeater {
            id: trayItems

            model: ScriptModel {
                values: SystemTray.items.values
            }

            Item {
                id: trayItem

                required property SystemTrayItem modelData

                width: root.theme.trayIconSize
                height: root.theme.barItemHeight
                property bool inputMethodItem: root.isFcitx(trayItem.modelData.id)
                property string resolvedIcon: root.trayIconSource(trayItem.modelData.id, trayItem.modelData.icon)

                Rectangle {
                    anchors.centerIn: parent
                    width: root.theme.trayItemSize
                    height: root.theme.barItemHeight
                    radius: root.theme.chipRadius
                    color: hoverArea.containsMouse ? root.theme.chipHoverBackground : root.theme.transparentColor
                }

                IconImage {
                    id: iconImage

                    anchors.centerIn: parent
                    width: root.theme.trayIconSize
                    height: root.theme.trayIconSize
                    source: trayItem.inputMethodItem ? "" : trayItem.resolvedIcon
                    asynchronous: true
                    mipmap: true
                    smooth: true
                    visible: !trayItem.inputMethodItem && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: trayItem.inputMethodItem || !iconImage.visible
                    text: trayItem.inputMethodItem ? root.fcitxLabel(trayItem.modelData.icon) : root.trayTextLabel(trayItem.modelData.id)
                    color: root.theme.popupText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.barIconSize
                    font.bold: true
                }

                MouseArea {
                    id: hoverArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.ArrowCursor
                    hoverEnabled: true
                    onClicked: mouse => {
                        if (trayItem.inputMethodItem && mouse.button === Qt.LeftButton) {
                            root.toggleFcitxInputMethod();
                        } else if (mouse.button === Qt.RightButton) {
                            root.openTrayMenu(trayItem.modelData, trayItem, mouse.x, mouse.y);
                        } else if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu) {
                            root.openTrayMenu(trayItem.modelData, trayItem, mouse.x, mouse.y);
                        } else {
                            trayItem.modelData.activate();
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: trayMenuWindow

        visible: root.menuOpen
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
        WlrLayershell.keyboardFocus: root.menuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-tray-popup"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: root.closeTrayMenu()
        }

        FocusScope {
            anchors.fill: parent
            focus: root.menuOpen
            Keys.onEscapePressed: root.closeTrayMenu()
        }

        Rectangle {
            id: trayMenuSurface

            width: Math.max(root.theme.popupElementSize * 8, menuColumn.implicitWidth + root.theme.gap * 2)
            height: menuColumn.implicitHeight + root.theme.gap * 2
            x: root.menuX(width)
            y: root.menuY(height)
            radius: root.theme.popupSectionRadius
            color: root.theme.popupBackground
            border.width: root.theme.popupBorderWidth
            border.color: root.theme.popupBorder

            MouseArea { anchors.fill: parent }

            QsMenuOpener {
                id: menuOpener
                menu: root.activeMenuHandle
            }

            Column {
                id: menuColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.theme.gap
                spacing: Math.max(1, Math.round(root.theme.gap * 0.25))

                Rectangle {
                    visible: root.menuStack.length > 0
                    width: parent.width
                    height: root.theme.popupElementSize * 0.92
                    radius: root.theme.popupSectionRadius * 0.65
                    color: backHover.containsMouse ? root.theme.popupHoverBackground : root.theme.transparentColor

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.gap
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.theme.gap * 0.5

                        Text { text: "󰁍"; color: root.theme.popupText; font.family: root.theme.fontFamily; font.pixelSize: root.theme.fontSize }
                        Text { text: "Back"; color: root.theme.popupText; font.family: root.theme.fontFamily; font.pixelSize: root.theme.fontSize; font.bold: true }
                    }

                    MouseArea {
                        id: backHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: root.popTraySubmenu()
                    }
                }

                Rectangle {
                    visible: root.menuStack.length > 0
                    width: parent.width
                    height: 1
                    color: root.theme.popupBorder
                }

                Repeater {
                    model: menuOpener.children || []

                    Rectangle {
                        id: menuEntryRow

                        required property var modelData

                        width: menuColumn.width
                        height: modelData && modelData.isSeparator ? 1 : root.theme.popupElementSize * 0.92
                        radius: modelData && modelData.isSeparator ? 0 : root.theme.popupSectionRadius * 0.65
                        color: {
                            if (modelData && modelData.isSeparator) return root.theme.popupBorder;
                            return entryHover.containsMouse ? root.theme.popupHoverBackground : root.theme.transparentColor;
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.gap
                            anchors.right: parent.right
                            anchors.rightMargin: root.theme.gap * 0.75
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.theme.gap * 0.55
                            visible: !(menuEntryRow.modelData && menuEntryRow.modelData.isSeparator)

                            Item {
                                id: menuIconSlot

                                width: hasButtonIndicator ? root.theme.barIconSize : 0
                                height: root.theme.barIconSize
                                visible: width > 0
                                anchors.verticalCenter: parent.verticalCenter
                                property bool hasButtonIndicator: menuEntryRow.modelData && menuEntryRow.modelData.buttonType !== undefined && menuEntryRow.modelData.buttonType !== 0

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.82
                                    height: parent.height * 0.82
                                    radius: menuEntryRow.modelData && menuEntryRow.modelData.buttonType === 2 ? width / 2 : 3
                                    visible: parent.hasButtonIndicator
                                    color: root.theme.transparentColor
                                    border.width: root.theme.popupBorderWidth
                                    border.color: root.theme.popupMutedText

                                    Text {
                                        anchors.centerIn: parent
                                        visible: menuEntryRow.modelData && menuEntryRow.modelData.checkState === 2
                                        text: "✓"
                                        color: root.theme.popupAccent
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: root.theme.fontSizeSmall
                                    }
                                }
                            }

                            Text {
                                width: parent.width - root.theme.barIconSize - parent.spacing - (menuIconSlot.visible ? menuIconSlot.width + parent.spacing : 0)
                                text: menuEntryRow.modelData ? menuEntryRow.modelData.text || "" : ""
                                color: menuEntryRow.modelData && menuEntryRow.modelData.enabled === false ? root.theme.popupMutedText : root.theme.popupText
                                elide: Text.ElideRight
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSize
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: root.theme.barIconSize
                                visible: menuEntryRow.modelData && menuEntryRow.modelData.hasChildren
                                text: "󰅂"
                                color: root.theme.popupMutedText
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSize
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        MouseArea {
                            id: entryHover
                            anchors.fill: parent
                            enabled: menuEntryRow.modelData && !menuEntryRow.modelData.isSeparator && menuEntryRow.modelData.enabled !== false
                            hoverEnabled: enabled
                            cursorShape: Qt.ArrowCursor
                            onClicked: root.activateMenuEntry(menuEntryRow.modelData)
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: root.visible && root.hasFcitxTrayItem
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshFcitx()
    }

    Process {
        id: fcitxProcess

        command: ["sh", "-c", "printf 'im=%s\\n' \"$(fcitx5-remote -n 2>/dev/null || true)\"; printf 'state=%s\\n' \"$(fcitx5-remote 2>/dev/null || echo 0)\""]
        stdout: StdioCollector {
            onStreamFinished: root.updateFcitx(text)
        }
    }

    Process {
        id: fcitxToggleProcess

        command: ["true"]
        onExited: () => root.refreshFcitx()
    }

    function isFcitx(id) {
        return String(id || "").match(/Fcitx/) !== null;
    }

    function refreshFcitx() {
        if (!fcitxProcess.running) {
            fcitxProcess.running = true;
        }
    }

    function toggleFcitxInputMethod() {
        const next = root.fcitxInputMethod === "bamboo" ? "keyboard-us" : "bamboo";
        fcitxToggleProcess.command = ["sh", "-c", `fcitx5-remote -s ${root.shellQuote(next)} && fcitx5-remote -o`];
        fcitxToggleProcess.running = true;
    }

    function updateFcitx(rawText) {
        for (const line of rawText.trim().split("\n")) {
            if (line.startsWith("im=")) {
                root.fcitxInputMethod = line.slice(3).trim();
            } else if (line.startsWith("state=")) {
                root.fcitxState = Number(line.slice(6).trim() || 0);
            }
        }
    }

    function shellQuote(value) {
        return `'${String(value).replace(/'/g, `'\\''`)}'`;
    }

    function openTrayMenu(item, anchorItem, x, y) {
        if (!item.hasMenu) {
            item.secondaryActivate();
            return;
        }

        const screen = root.panelWindow.screen;
        const globalPos = anchorItem.mapToGlobal(anchorItem.width / 2, anchorItem.height);
        root.activeTrayItem = item;
        root.menuStack = [];
        root.menuAnchorX = globalPos.x - (screen ? screen.x : 0);
        root.menuAnchorY = globalPos.y - (screen ? screen.y : 0);
        root.menuOpen = true;
    }

    function activateMenuEntry(entry) {
        if (!entry || entry.isSeparator) return;
        if (entry.hasChildren) {
            const nextMenu = entry.menu || entry;
            root.menuStack = [...root.menuStack, nextMenu];
            return;
        }
        if (typeof entry.activate === "function") {
            entry.activate();
        } else if (typeof entry.triggered === "function") {
            entry.triggered();
        }
        root.closeTrayMenu();
    }

    function popTraySubmenu() {
        if (root.menuStack.length === 0) return;
        root.menuStack = root.menuStack.slice(0, root.menuStack.length - 1);
    }

    function closeTrayMenu() {
        root.menuOpen = false;
        root.menuStack = [];
        root.activeTrayItem = null;
    }

    function menuX(menuWidth) {
        const minX = root.theme.barOuterSpacing;
        const maxX = Math.max(minX, trayMenuWindow.width - menuWidth - root.theme.barOuterSpacing);
        return Math.max(minX, Math.min(maxX, root.menuAnchorX - menuWidth / 2));
    }

    function menuY(menuHeight) {
        const minY = root.theme.barOuterSpacing + root.theme.barHeight + root.theme.gap;
        const maxY = Math.max(minY, trayMenuWindow.height - menuHeight - root.theme.barOuterSpacing);
        return Math.max(minY, Math.min(maxY, root.menuAnchorY + root.theme.gap));
    }

    function trayIconSource(id, iconName) {
        const itemId = String(id || "");
        const polarity = root.theme.isLightTheme ? "light" : "dark";

        if (itemId.match(/^theme-manager$/)) {
            return `file://${root.iconRoot}/systray/${polarity}/theme-manager.svg`;
        }
        if (itemId.match(/^steam$/)) {
            return `file://${root.iconRoot}/systray/${polarity}/steam.svg`;
        }
        if (itemId.match(/Slack_status_icon_.*/)) {
            return `file://${root.iconRoot}/systray/${polarity}/slack.svg`;
        }
        if (itemId.match(/Claude_status_icon_.*/)) {
            return `file://${root.iconRoot}/claude-tray.svg`;
        }
        if (itemId.match(/Codex_status_icon_.*/)) {
            return `file://${root.iconRoot}/codex-tray.svg`;
        }
        return iconName || "";
    }

    function fcitxLabel(iconName) {
        const value = String(iconName || root.fcitxInputMethod || "").toLowerCase();
        if (value.includes("bamboo")) {
            return "VN";
        }
        if (value.includes("keyboard-us") || value.includes("keyboard_us") || value.includes("fcitx-keyboard")) {
            return "US";
        }
        if (root.fcitxInputMethod === "bamboo") {
            return "VN";
        }
        return "US";
    }

    function trayTextLabel(id) {
        const value = String(id || "?").replace(/^org\./, "");
        return value.length > 0 ? value[0].toUpperCase() : "?";
    }
}
