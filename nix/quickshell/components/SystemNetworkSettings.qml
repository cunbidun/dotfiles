import QtQuick

Column {
    id: root

    required property var theme
    property var goBack: () => {}
    readonly property string status: wifiSource.status
    property var passwordNetwork: null
    property string wifiPassword: ""
    readonly property string wifiDeviceName: wifiSource.wifiDeviceName
    readonly property bool wifiEnabled: wifiSource.wifiEnabled
    readonly property var activeNetwork: wifiSource.activeNetwork
    readonly property var connectionInfo: ({
        device: root.wifiDeviceName,
        connection: root.activeNetwork.ssid || "",
        address: wifiSource.address,
        gateway: wifiSource.gateway,
        dns: wifiSource.dns
    })
    readonly property var nearbyNetworks: wifiSource.networks
    readonly property var savedNetworks: wifiSource.knownNetworks
    readonly property var knownNearbyNetworks: root.savedNetworks
    readonly property var otherNetworks: wifiSource.otherNetworks

    spacing: theme.gap

    WifiNetworkSource {
        id: wifiSource
    }

    SettingsHeader {
        theme: root.theme
        width: parent.width
        title: "Wi-Fi"
        subtitle: root.wifiEnabled ? "Choose a network to join." : "Turn on Wi-Fi, then choose a network to join."
        checked: root.wifiEnabled
        toggle: () => root.setWifiEnabled(!root.wifiEnabled)
    }

    Rectangle {
        width: parent.width
        height: detailsColumn.implicitHeight + root.theme.gap * 2
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground
        border.width: root.theme.popupBorderWidth
        border.color: root.theme.popupBorder

        Column {
            id: detailsColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.theme.gap
            spacing: 0

            Row {
                width: parent.width
                height: root.theme.compactRowHeight
                spacing: root.theme.gap

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wifiEnabled ? root.networkIcon(root.activeNetwork.signal || 0) : "󰤭"
                    color: root.activeNetwork.ssid ? root.theme.popupAccent : root.theme.popupMutedText
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeLarge
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - root.theme.popupElementSize
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.activeNetwork.ssid || root.connectionInfo.connection || (root.wifiEnabled ? "Not Connected" : "Wi-Fi Off")
                        color: root.theme.popupText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.connectionInfo.device ? `${root.connectionInfo.device}${root.activeNetwork.signal ? ` • ${root.activeNetwork.signal}%` : ""}` : "No active wireless device"
                        color: root.theme.popupMutedText
                        elide: Text.ElideRight
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSizeSmall
                    }
                }
            }

            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Connection"; value: root.connectionInfo.connection || "--" }
            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Address"; value: root.connectionInfo.address || "--" }
            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Gateway"; value: root.connectionInfo.gateway || "--" }
            SettingsInfoRow { theme: root.theme; width: parent.width; label: "DNS"; value: root.connectionInfo.dns || "--" }
            SettingsInfoRow { theme: root.theme; width: parent.width; label: "Security"; value: root.activeNetwork.security || "--" }
        }
    }

    Rectangle {
        id: passwordCard

        width: parent.width
        height: passwordCard.visible ? passwordColumn.implicitHeight + root.theme.gap * 2 : 0
        visible: root.passwordNetwork !== null
        radius: root.theme.popupSectionRadius
        color: root.theme.popupSectionBackground
        border.width: root.theme.popupBorderWidth
        border.color: root.theme.popupBorder

        Column {
            id: passwordColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.theme.gap
            spacing: root.theme.gap

            Text {
                width: parent.width
                text: `Join ${root.passwordNetwork?.ssid || "network"}`
                color: root.theme.popupText
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: root.theme.compactRowHeight
                radius: root.theme.popupSectionRadius
                color: root.theme.popupElevatedBackground
                border.width: root.theme.popupBorderWidth
                border.color: passwordInput.activeFocus ? root.theme.selectedBackground : root.theme.popupBorder

                TextInput {
                    id: passwordInput

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.theme.gap
                    anchors.rightMargin: root.theme.gap
                    text: root.wifiPassword
                    echoMode: TextInput.Password
                    color: root.theme.popupText
                    selectionColor: root.theme.selectedBackground
                    selectedTextColor: root.theme.selectedForeground
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                    onTextChanged: root.wifiPassword = text
                    Keys.onReturnPressed: root.submitPassword()
                }
            }

            Row {
                width: parent.width
                height: root.theme.compactRowHeight
                spacing: root.theme.gap

                SettingsActionButton { theme: root.theme; width: (parent.width - root.theme.gap) / 2; text: "Cancel"; activate: root.cancelPassword }
                SettingsActionButton { theme: root.theme; width: (parent.width - root.theme.gap) / 2; text: "Join"; active: true; activate: root.submitPassword }
            }
        }
    }

    SettingsSectionLabel {
        theme: root.theme
        width: parent.width
        text: "Known Networks"
    }

    Column {
        width: parent.width
        spacing: root.theme.gap * 0.2

        Repeater {
            model: root.knownNearbyNetworks.slice(0, 8)

            NetworkRow {
                theme: root.theme
                width: parent.width
                wifiNetwork: modelData
                activate: () => modelData.active ? root.disconnectWifi() : root.requestConnect(modelData)
                forget: () => root.forgetNetwork(modelData)
                showForget: true
            }
        }

        SettingsEmptyState {
            theme: root.theme
            width: parent.width
            visible: root.knownNearbyNetworks.length === 0
            text: "No known Wi-Fi networks"
        }
    }

    SettingsSectionLabel {
        theme: root.theme
        width: parent.width
        text: "Other Networks"
    }

    Column {
        width: parent.width
        spacing: root.theme.gap * 0.2

        Repeater {
            model: root.otherNetworks.slice(0, 12)

            NetworkRow {
                theme: root.theme
                width: parent.width
                wifiNetwork: modelData
                activate: () => root.requestConnect(modelData)
                forget: () => {}
                showForget: false
            }
        }

        SettingsEmptyState {
            theme: root.theme
            width: parent.width
            visible: root.otherNetworks.length === 0
            text: root.wifiEnabled ? "No other networks found" : "Wi-Fi disabled"
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

    function refresh(rescan) {
        wifiSource.refresh();
    }

    function setWifiEnabled(enabled) {
        wifiSource.setWifiEnabled(enabled);
    }

    function requestConnect(network) {
        if (network.secure && !network.saved && !network.active) {
            root.passwordNetwork = network;
            root.wifiPassword = "";
            return;
        }
        wifiSource.connectNetwork(network, "");
    }

    function submitPassword() {
        if (!root.passwordNetwork || root.wifiPassword.length === 0) {
            return;
        }
        wifiSource.connectNetwork(root.passwordNetwork, root.wifiPassword);
        root.cancelPassword();
    }

    function cancelPassword() {
        root.passwordNetwork = null;
        root.wifiPassword = "";
    }

    function forgetNetwork(network) {
        wifiSource.forgetNetwork(network);
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

    component NetworkRow: Rectangle {
        id: networkRow

        required property var theme
        property var wifiNetwork: ({})
        property bool showForget: false
        property var activate: () => {}
        property var forget: () => {}

        visible: String(wifiNetwork.ssid || "").trim().length > 0
        height: visible ? theme.listRowHeight : 0
        radius: theme.popupSectionRadius
        color: !!wifiNetwork.active ? theme.popupSelectedBackground : rowHover.containsMouse ? theme.popupHoverBackground : theme.popupSectionBackground
        border.width: !!wifiNetwork.active ? theme.popupBorderWidth : 0
        border.color: theme.popupBorder

        Text {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            text: wifiNetwork.active ? "✓" : wifiNetwork.saved ? "󰤢" : ""
            color: !!wifiNetwork.active ? theme.selectedForeground : theme.iconMutedColor
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: theme.popupElementSize
            anchors.right: detailIcon.left
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: wifiNetwork.ssid || ""
                color: !!wifiNetwork.active ? theme.selectedForeground : theme.popupText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize
                font.bold: !!wifiNetwork.active
            }

            Text {
                width: parent.width
                visible: !!(wifiNetwork.active || wifiNetwork.saved || wifiNetwork.security)
                text: wifiNetwork.active ? "Connected" : wifiNetwork.saved ? "Known Network" : wifiNetwork.security || ""
                color: !!wifiNetwork.active ? theme.selectedForeground : theme.popupMutedText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }
        }

        Row {
            id: detailIcon

            anchors.right: parent.right
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap * 0.7

            Text { visible: !!wifiNetwork.secure; text: "󰌾"; color: !!wifiNetwork.active ? theme.selectedForeground : theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
            Text { text: networkIcon(wifiNetwork.signal || 0); color: !!wifiNetwork.active ? theme.selectedForeground : theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: !!networkRow.showForget; text: "󰍉"; color: theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton && networkRow.showForget) {
                    networkRow.forget();
                } else {
                    networkRow.activate();
                }
            }
        }

        function networkIcon(signal) {
            if (signal >= 75) return "󰤨";
            if (signal >= 50) return "󰤥";
            if (signal >= 25) return "󰤢";
            return "󰤟";
        }
    }
}
