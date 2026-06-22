import QtQuick

Column {
    id: root

    required property var theme
    required property var wifiSource
    property var goBack: () => {}
    readonly property string status: wifiSource.status
    property var passwordNetwork: null
    property string wifiPassword: ""
    readonly property string wifiDeviceName: wifiSource.wifiDeviceName
    readonly property bool wifiEnabled: wifiSource.wifiEnabled
    readonly property var activeNetwork: wifiSource.activeNetwork
    readonly property var connectionInfo: ({
        device: root.wifiDeviceName,
        connection: root.activeNetwork.ssid || ""
    })
    readonly property var nearbyNetworks: wifiSource.networks
    readonly property var savedNetworks: wifiSource.knownNetworks
    readonly property var knownNearbyNetworks: root.savedNetworks
    readonly property var otherNetworks: wifiSource.otherNetworks

    spacing: theme.gap

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
                        font.family: root.theme.fontFamilyEmphasis
                        font.pixelSize: root.theme.fontSize
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
                font.family: root.theme.fontFamilyEmphasis
                font.pixelSize: root.theme.fontSize
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
            model: root.knownNearbyNetworks.length

            NetworkRow {
                required property int index

                theme: root.theme
                width: parent.width
                wifiNetwork: root.knownNearbyNetworks[index]
                activate: () => root.requestConnect(wifiNetwork)
                disconnect: () => root.disconnectWifi()
                forget: () => root.forgetNetwork(wifiNetwork)
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
            model: root.otherNetworks.length

            NetworkRow {
                required property int index

                theme: root.theme
                width: parent.width
                wifiNetwork: root.otherNetworks[index]
                activate: () => root.requestConnect(wifiNetwork)
                disconnect: () => {}
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
        wifiSource.refresh(rescan);
    }

    function setWifiEnabled(enabled) {
        wifiSource.setWifiEnabled(enabled);
    }

    function requestConnect(network) {
        if (network.active) {
            return;
        }
        if (network.enterprise) {
            wifiSource.status = "Enterprise Wi-Fi is not supported here yet";
            return;
        }
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
        property var disconnect: () => {}
        property var forget: () => {}
        property bool menuOpen: false
        readonly property bool showMenu: true

        visible: String(wifiNetwork.ssid || "").trim().length > 0
        z: networkRow.menuOpen ? 30 : 0
        height: visible ? theme.listRowHeight : 0
        radius: theme.popupSectionRadius
        color: rowHover.containsMouse || menuButtonHover.containsMouse || networkRow.menuOpen ? theme.popupHoverBackground : theme.popupSectionBackground
        border.width: !!wifiNetwork.active ? theme.popupBorderWidth : 0
        border.color: theme.popupBorder

        Text {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            text: wifiNetwork.active ? "✓" : wifiNetwork.saved ? "󰤢" : ""
            color: !!wifiNetwork.active ? theme.popupAccent : theme.iconMutedColor
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: theme.popupElementSize
            anchors.right: trailingIcons.left
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: wifiNetwork.ssid || ""
                color: theme.popupText
                elide: Text.ElideRight
                font.family: !!wifiNetwork.active ? theme.fontFamilyEmphasis : theme.fontFamily
                font.pixelSize: theme.fontSize
            }

            Text {
                width: parent.width
                visible: !!(wifiNetwork.saved || wifiNetwork.security)
                text: wifiNetwork.saved ? "Known Network" : wifiNetwork.security || ""
                color: theme.popupMutedText
                elide: Text.ElideRight
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }
        }

        Row {
            id: trailingIcons

            anchors.right: parent.right
            anchors.rightMargin: theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap * 0.7

            Spinner { visible: !!networkRow.wifiNetwork.connecting; theme: networkRow.theme; size: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: !!wifiNetwork.secure && !networkRow.wifiNetwork.connecting; text: "󰌾"; color: theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: !networkRow.wifiNetwork.connecting; text: networkIcon(wifiNetwork.signal || 0); color: theme.iconMutedColor; font.family: theme.fontFamily; font.pixelSize: theme.fontSize; anchors.verticalCenter: parent.verticalCenter }

            Rectangle {
                id: menuButton

                visible: networkRow.showMenu
                width: Math.round(theme.em * 1.25)
                height: width
                radius: width / 2
                color: menuButtonHover.containsMouse || networkRow.menuOpen ? theme.chipHoverBackground : theme.transparentColor
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "ⓘ"
                    color: menuButtonHover.containsMouse || networkRow.menuOpen ? theme.popupText : theme.iconMutedColor
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeMedium
                }

                MouseArea {
                    id: menuButtonHover

                    anchors.fill: parent
                    anchors.margins: -theme.gap * 0.45
                    cursorShape: Qt.ArrowCursor
                    hoverEnabled: true
                    onClicked: mouse => {
                        mouse.accepted = true;
                        networkRow.menuOpen = !networkRow.menuOpen;
                    }
                }
            }
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            anchors.rightMargin: networkRow.showMenu ? theme.popupElementSize : 0
            cursorShape: Qt.ArrowCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: {
                networkRow.menuOpen = false;
                networkRow.activate();
            }
        }

        Rectangle {
            id: actionMenu

            visible: networkRow.menuOpen
            z: 20
            width: theme.popupElementSize * 3.4
            height: actionColumn.implicitHeight + theme.gap * 0.8
            radius: theme.popupSectionRadius
            color: theme.popupElevatedBackground
            border.width: theme.popupBorderWidth
            border.color: theme.popupBorder
            anchors.right: parent.right
            anchors.top: parent.bottom
            anchors.topMargin: theme.gap * 0.35

            Column {
                id: actionColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.gap * 0.4
                spacing: 0

                ActionMenuRow {
                    theme: networkRow.theme
                    width: parent.width
                    visible: !networkRow.wifiNetwork.active
                    text: "Join"
                    activate: () => {
                        networkRow.menuOpen = false;
                        networkRow.activate();
                    }
                }

                ActionMenuRow {
                    theme: networkRow.theme
                    width: parent.width
                    visible: !!networkRow.wifiNetwork.active
                    text: "Disconnect"
                    activate: () => {
                        networkRow.menuOpen = false;
                        networkRow.disconnect();
                    }
                }

                ActionMenuRow {
                    theme: networkRow.theme
                    width: parent.width
                    visible: networkRow.showForget
                    text: "Forget"
                    destructive: true
                    activate: () => {
                        networkRow.menuOpen = false;
                        networkRow.forget();
                    }
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

    component ActionMenuRow: Rectangle {
        id: actionRow

        required property var theme
        property string text: ""
        property bool destructive: false
        property var activate: () => {}

        height: visible ? theme.compactRowHeight * 0.82 : 0
        radius: theme.popupSectionRadius * 0.7
        color: actionHover.containsMouse ? theme.popupHoverBackground : theme.transparentColor

        Text {
            anchors.left: parent.left
            anchors.leftMargin: theme.gap * 0.7
            anchors.verticalCenter: parent.verticalCenter
            text: actionRow.text
            color: actionRow.destructive ? theme.popupDanger : theme.popupText
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
        }

        MouseArea {
            id: actionHover

            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            hoverEnabled: true
            onClicked: actionRow.activate()
        }
    }
}
