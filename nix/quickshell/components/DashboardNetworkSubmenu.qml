import QtQuick
import Quickshell

Column {
    id: root

    required property var theme
    required property var wifiSource
    property var goBack: () => {}
    property var openSettings: () => {}
    readonly property string status: wifiSource.status
    readonly property string wifiDeviceName: wifiSource.wifiDeviceName
    readonly property bool wifiEnabled: wifiSource.wifiEnabled
    readonly property var networks: wifiSource.networks.filter(network => !network.outOfRange)
    readonly property var visibleNetworks: root.networks.slice(0, 8)

    spacing: theme.gap

    Rectangle {
        width: parent.width
        height: root.theme.sectionHeaderHeight
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground

        TextButton {
            theme: root.theme
            anchors.left: parent.left
            anchors.leftMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            icon: "󰁍"
            text: "Network"
            activate: root.goBack
        }

        SettingsSwitch {
            id: powerSwitch

            theme: root.theme
            anchors.right: parent.right
            anchors.rightMargin: root.theme.gap
            anchors.verticalCenter: parent.verticalCenter
            checked: root.wifiEnabled
            activate: () => root.setWifiEnabled(!root.wifiEnabled)
        }
    }

    Text {
        width: parent.width
        text: root.wifiEnabled ? `${root.networks.length} networks available` : "Wi-Fi disabled"
        color: root.theme.popupMutedText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
    }

    Column {
        width: parent.width
        spacing: root.theme.gap

        Repeater {
            model: root.visibleNetworks.length

            Rectangle {
                id: networkRow

                required property int index

                readonly property var network: root.visibleNetworks[index]
                readonly property bool active: network.active

                width: parent.width
                height: root.theme.listRowHeight
                radius: root.theme.popupSectionRadius
                color: active ? root.theme.popupSelectedBackground : networkHover.containsMouse ? root.theme.popupHoverBackground : root.theme.popupSectionBackground

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.networkIcon(networkRow.network.signal)
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.iconColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.popupElementSize
                    anchors.right: actionIcon.left
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkRow.network.ssid
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.popupText
                    elide: Text.ElideRight
                    font.family: networkRow.active ? root.theme.fontFamilyEmphasis : root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                Text {
                    visible: networkRow.network.secure
                    anchors.right: actionIcon.left
                    anchors.rightMargin: root.theme.popupElementSize * 0.8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌾"
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.iconMutedColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                }

                Spinner {
                    visible: !!networkRow.network.connecting
                    theme: root.theme
                    size: root.theme.fontSize
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: actionIcon

                    visible: !networkRow.network.connecting
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.gap
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkRow.active ? "󰌙" : "󰌘"
                    color: networkRow.active ? root.theme.selectedForeground : root.theme.iconColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                MouseArea {
                    id: networkHover

                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    hoverEnabled: true
                    onClicked: networkRow.active ? root.disconnectWifi() : root.connectWifi(networkRow.network.ssid)
                }
            }
        }

        Item {
            width: parent.width
            height: root.networks.length === 0 ? root.theme.popupElementSize * 2 : 0
            visible: root.networks.length === 0

            Text {
                anchors.centerIn: parent
                text: root.wifiEnabled ? "No networks found" : "Enable Wi-Fi to scan"
                color: root.theme.popupMutedText
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize
            }
        }
    }

    Text {
        width: parent.width
        visible: root.status.length > 0
        text: root.status
        color: root.theme.popupMutedText
        elide: Text.ElideRight
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSizeSmall
    }

    SettingsRow {
        theme: root.theme
        width: parent.width
        icon: "󰒓"
        text: "Wi-Fi Settings"
        activate: root.openSettings
    }

    function refresh(rescan) {
        wifiSource.refresh(rescan);
    }

    function setWifiEnabled(enabled) {
        wifiSource.setWifiEnabled(enabled);
    }

    function connectWifi(ssid) {
        wifiSource.connectSsid(ssid);
    }

    function disconnectWifi() {
        wifiSource.disconnectWifi();
    }

    function networkIcon(signal) {
        if (signal >= 75) return "󰤨";
        if (signal >= 50) return "󰤥";
        if (signal >= 25) return "󰤢";
        return "󰤟";
    }

    component SettingsRow: Rectangle {
        required property var theme
        property string icon: ""
        property string text: ""
        property var activate: () => {}

        height: theme.compactRowHeight
        radius: theme.popupSectionRadius
        color: hover.containsMouse ? theme.chipHoverBackground : theme.popupSectionBackground
        border.width: theme.popupBorderWidth
        border.color: theme.popupBorder

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: theme.gap
            anchors.rightMargin: theme.gap
            spacing: theme.gap

            Text { text: icon; color: theme.iconColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
            Text { width: parent.width - theme.popupElementSize; text: parent.parent.text; color: theme.popupText; font.family: theme.fontFamilyEmphasis; font.pixelSize: theme.fontSizeSmall; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea { id: hover; anchors.fill: parent; cursorShape: Qt.ArrowCursor; hoverEnabled: true; onClicked: parent.activate() }
    }
}
