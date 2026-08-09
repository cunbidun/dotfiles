import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    required property var theme
    property var connections: []
    property string fetchError: ""
    property bool loading: false
    property var lastUpdated: null
    property var refresh: () => {}

    readonly property string assetRoot: `${Quickshell.env("HOME")}/dotfiles/nix/quickshell/assets`
    readonly property string iconRoot: `${assetRoot}/icons`
    // Brand name/color/monogram per provider, lifted from 9Router's own client
    // registry so providers we have no logo for still get their real colors.
    property var providerBadges: ({})
    readonly property int listHeight: Math.min(theme.aiQuotaMaxListHeight,
                                               Math.max(theme.listRowHeight, cardsColumn.implicitHeight))

    width: theme.aiQuotaPopupWidth
    height: theme.gap * 2 + theme.sectionHeaderHeight + theme.gap + listHeight
    implicitWidth: width
    implicitHeight: height
    radius: theme.popupSectionRadius
    color: theme.popupBackground
    border.width: theme.popupBorderWidth
    border.color: theme.popupBorder

    // Drives the reset countdowns and the "updated Nm ago" line.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    FileView {
        id: providerBadgeFile

        path: `${root.assetRoot}/provider-badges.json`
        blockLoading: true
        printErrors: false
        onTextChanged: {
            try {
                root.providerBadges = JSON.parse(text());
            } catch (error) {
                console.warn(`[ai-quota] provider-badges.json: ${error}`);
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.theme.gap
        spacing: root.theme.gap

        Rectangle {
            id: header

            width: parent.width
            height: root.theme.sectionHeaderHeight
            radius: root.theme.popupSectionRadius
            color: root.theme.popupSectionBackground

            Column {
                anchors.left: parent.left
                anchors.leftMargin: root.theme.gap
                anchors.right: refreshButton.left
                anchors.rightMargin: root.theme.gap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "AI Quota"
                    color: root.theme.popupText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamilyEmphasis
                    font.pixelSize: root.theme.fontSizeSmall
                }

                Text {
                    width: parent.width
                    text: root.statusLine()
                    color: root.fetchError.length > 0 ? root.theme.popupDanger : root.theme.popupMutedText
                    elide: Text.ElideRight
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                }
            }

            IconButton {
                id: refreshButton

                theme: root.theme
                enabled: !root.loading
                anchors.right: parent.right
                anchors.rightMargin: root.theme.gap
                anchors.verticalCenter: parent.verticalCenter
                icon: "󰑐"
                activate: () => root.refresh()
            }
        }

        Flickable {
            width: parent.width
            height: root.listHeight
            contentWidth: width
            contentHeight: cardsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: cardsColumn

                width: parent.width
                spacing: root.theme.gap

                SettingsEmptyState {
                    theme: root.theme
                    visible: root.connections.length === 0
                    width: parent.width
                    text: root.fetchError.length > 0 ? "Quota unavailable" : (root.loading ? "Loading…" : "No metered accounts")
                }

                Repeater {
                    model: root.connections

                    Rectangle {
                        id: connectionCard

                        required property var modelData

                        width: cardsColumn.width
                        height: cardContent.implicitHeight + root.theme.gap * 2
                        radius: root.theme.popupSectionRadius
                        color: root.theme.popupSectionBackground

                        Column {
                            id: cardContent

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: root.theme.gap
                            spacing: Math.round(root.theme.gap * 0.75)

                            Row {
                                width: parent.width
                                spacing: root.theme.gap

                                Item {
                                    id: providerIcon

                                    readonly property string logo: root.providerIconSource(connectionCard.modelData.provider)
                                    readonly property string glyph: root.providerGlyph(connectionCard.modelData.provider)

                                    width: root.theme.aiQuotaProviderIconSize
                                    height: root.theme.aiQuotaProviderIconSize
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.fill: parent
                                        visible: providerIcon.logo !== ""
                                        source: providerIcon.logo
                                        sourceSize.width: width * 3
                                        sourceSize.height: height * 3
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: providerIcon.logo === "" && providerIcon.glyph !== ""
                                        text: providerIcon.glyph
                                        color: root.theme.popupText
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: root.theme.fontSizeLarge
                                    }

                                    // No bundled logo: fall back to the provider's
                                    // own brand color and monogram.
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: providerIcon.logo === "" && providerIcon.glyph === ""
                                        radius: Math.round(width * 0.24)
                                        color: root.providerColor(connectionCard.modelData.provider)

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.providerMonogram(connectionCard.modelData.provider)
                                            color: "#FFFFFF"
                                            font.family: root.theme.fontFamilyEmphasis
                                            font.pixelSize: Math.round(root.theme.aiQuotaProviderIconSize * 0.46)
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width - root.theme.aiQuotaProviderIconSize - parent.spacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: root.providerLabel(connectionCard.modelData.provider)
                                        color: root.theme.popupText
                                        elide: Text.ElideRight
                                        font.family: root.theme.fontFamilyEmphasis
                                        font.pixelSize: root.theme.fontSizeSmall
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.accountLine(connectionCard.modelData)
                                        color: root.theme.popupMutedText
                                        elide: Text.ElideRight
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: root.theme.fontSizeSmall
                                    }
                                }
                            }

                            Repeater {
                                model: connectionCard.modelData.quotas

                                Column {
                                    id: quotaEntry

                                    required property var modelData

                                    width: cardContent.width
                                    spacing: 3

                                    Row {
                                        width: parent.width
                                        spacing: root.theme.gap

                                        Text {
                                            width: parent.width - valueLabel.width - parent.spacing
                                            text: quotaEntry.modelData.name
                                            color: root.theme.popupText
                                            elide: Text.ElideRight
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: root.theme.fontSizeSmall
                                        }

                                        Text {
                                            id: valueLabel

                                            text: root.valueText(quotaEntry.modelData)
                                            color: root.theme.popupText
                                            font.family: root.theme.fontFamilyMono
                                            font.pixelSize: root.theme.fontSizeSmall
                                            font.features: ({ "tnum": 1 })
                                        }
                                    }

                                    Rectangle {
                                        id: track

                                        visible: !quotaEntry.modelData.unlimited
                                        width: parent.width
                                        height: root.theme.aiQuotaBarHeight
                                        radius: height / 2
                                        color: root.theme.popupElevatedBackground

                                        Rectangle {
                                            width: Math.max(parent.height,
                                                            parent.width * Math.max(0, Math.min(100, quotaEntry.modelData.percent)) / 100)
                                            height: parent.height
                                            radius: height / 2
                                            color: root.quotaColor(quotaEntry.modelData.percent)

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 220
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        visible: text.length > 0
                                        text: root.formatReset(quotaEntry.modelData.resetAt)
                                        color: root.theme.popupMutedText
                                        elide: Text.ElideRight
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: root.theme.fontSizeSmall
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function statusLine() {
        if (root.loading) {
            return "Refreshing…";
        }

        if (root.fetchError.length > 0) {
            return root.fetchError;
        }

        if (!root.lastUpdated) {
            return "Not loaded yet";
        }

        const count = root.connections.length;
        const accounts = `${count} account${count === 1 ? "" : "s"}`;
        const minutes = Math.floor((clock.date.getTime() - root.lastUpdated.getTime()) / 60000);
        return minutes < 1 ? `${accounts} · updated just now` : `${accounts} · updated ${minutes}m ago`;
    }

    function accountLine(connection) {
        const account = connection.account ? String(connection.account) : "";
        // Some providers echo the product name back as the plan (claude reports
        // plan "Claude Code"), which would just repeat the card title.
        const plan = connection.plan ? String(connection.plan) : "";
        const redundant = plan.toLowerCase() === root.providerLabel(connection.provider).toLowerCase();
        if (plan.length > 0 && !redundant && account.length > 0) {
            return `${account} · ${plan}`;
        }

        return plan.length > 0 && !redundant ? plan : account;
    }

    function valueText(quota) {
        if (quota.unlimited) {
            return root.formatNumber(quota.remaining);
        }

        // Percentage-based buckets (codex, claude) are already out of 100 —
        // printing "85 / 100  85%" says the same thing twice.
        if (quota.total === 100) {
            return `${Math.round(quota.percent)}%`;
        }

        return `${root.formatNumber(quota.remaining)} / ${root.formatNumber(quota.total)}  ${Math.round(quota.percent)}%`;
    }

    function formatNumber(value) {
        if (Math.round(value) === value) {
            return String(Math.round(value)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        }

        return value.toFixed(2);
    }

    function formatReset(resetAt) {
        if (!resetAt) {
            return "";
        }

        const target = new Date(resetAt);
        const deltaMs = target.getTime() - clock.date.getTime();
        if (isNaN(deltaMs)) {
            return "";
        }

        if (deltaMs <= 0) {
            return "resetting";
        }

        const minutes = Math.floor(deltaMs / 60000);
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor((minutes % 1440) / 60);
        if (days > 0) {
            return `resets in ${days}d ${hours}h`;
        }

        if (hours > 0) {
            return `resets in ${hours}h ${minutes % 60}m`;
        }

        return `resets in ${minutes}m`;
    }

    function quotaColor(percent) {
        if (percent <= root.theme.aiQuotaDangerPercent) {
            return root.theme.popupDanger;
        }

        if (percent <= root.theme.aiQuotaWarnPercent) {
            return root.theme.popupWarning;
        }

        return root.theme.popupSuccess;
    }

    function providerIconSource(provider) {
        const polarity = root.theme.isLightTheme ? "light" : "dark";
        if (provider === "claude") {
            return `file://${root.iconRoot}/systray/${polarity}/claude.svg`;
        }

        if (provider === "codex") {
            return `file://${root.iconRoot}/codex-tray.svg`;
        }

        return "";
    }

    function providerGlyph(provider) {
        // Only where the nerd font carries the actual brand mark.
        return provider === "github" ? "󰊤" : "";
    }

    function providerBadge(provider) {
        return root.providerBadges[String(provider || "")] || null;
    }

    function providerColor(provider) {
        const badge = root.providerBadge(provider);
        return badge && badge.color ? badge.color : root.theme.popupMutedText;
    }

    function providerMonogram(provider) {
        const badge = root.providerBadge(provider);
        if (badge && badge.textIcon) {
            return String(badge.textIcon).toUpperCase();
        }

        const key = String(provider || "");
        return key.length > 0 ? key.slice(0, 2).toUpperCase() : "?";
    }

    function providerLabel(provider) {
        // OAuth connection types 9Router does not list in its provider registry.
        const labels = {
            codex: "Codex",
            claude: "Claude Code",
            github: "GitHub Copilot"
        };
        const key = String(provider || "");
        if (labels[key]) {
            return labels[key];
        }

        const badge = root.providerBadge(key);
        if (badge && badge.name) {
            return badge.name;
        }

        return key.length > 0 ? key[0].toUpperCase() + key.slice(1) : "Unknown";
    }
}
