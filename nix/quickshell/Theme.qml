import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    readonly property string currentThemeNamePath: `${Quickshell.env("HOME")}/.local/state/theme-manager/current-theme-name.txt`
    readonly property string themeName: resolveThemeName(currentThemeName)
    readonly property string themeFilePath: `${Quickshell.env("HOME")}/.config/quickshell/cunbidun/themes/${themeName}.json`
    readonly property int fontSize: 12
    // Type scale — every text should use one of these, not an ad-hoc multiplier.
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeXLarge: 18
    // macOS UI font (SF Pro Text). Nerd Fonts ship weights as separate family
    // names, so emphasis is selected by family, not font.weight/font.bold.
    readonly property string fontFamily: "SFProText Nerd Font"
    readonly property string fontFamilyMedium: "SFProText Nerd Font Medium"
    readonly property string fontFamilyEmphasis: "SFProText Nerd Font SemiBold"
    readonly property string fontFamilyMono: "SFMono Nerd Font"

    readonly property real em: fontSize

    readonly property int barIconSize: Math.round(em * 1.23)
    readonly property int barItemHeight: Math.round(em * 1.85) - 2
    readonly property int barPaddingY: Math.max(0, Math.round((barItemHeight - barIconSize) / 2))
    readonly property int barHeight: barItemHeight + barPaddingY * 2
    // Must match Hyprland general.gaps_out (hyprland.lua) so the bar lines up
    // with the window grid: equal gap above the bar, below it, and on the sides.
    readonly property int barOuterSpacing: 2
    readonly property int barHorizontalSpacing: Math.round(em * 0.55)
    readonly property int generalRadius: Math.round(em * 0.45)
    readonly property int barRadius: generalRadius
    readonly property int barBorderWidth: 0

    readonly property int moduleGap: Math.round(em * 0.35)
    readonly property int modulePaddingX: Math.round(em * 0.6)
    readonly property int modulePaddingY: 0
    readonly property int moduleMarginY: Math.round(em * 0.1)
    readonly property int chipGap: Math.round(em * 0.35)
    readonly property int chipPaddingX: Math.round(em * 0.55)
    readonly property int chipPaddingY: barPaddingY
    readonly property int chipRadius: generalRadius
    readonly property int iconGap: Math.round(em * 0.35)
    readonly property int trayGap: Math.round(em * 0.55)
    readonly property int windowTitleMaxWidth: Math.round(em * 22)
    readonly property int weatherMaxWidth: Math.round(em * 12)
    readonly property int clockMaxWidth: Math.round(em * 14)
    readonly property int gap: Math.round(em * 0.69)
    readonly property int popupScreenMargin: Math.round(gap * 1.25)
    readonly property int popupSectionRadius: generalRadius
    readonly property int calendarCellWidth: Math.round(em * 2.95)
    readonly property int calendarCellHeight: Math.round(em * 1.9)
    readonly property int calendarCellSize: Math.round(em * 2.35)
    readonly property int popupElementSize: Math.round(em * 2.35)
    // Semantic row heights — use these instead of multiplying popupElementSize ad-hoc.
    readonly property int compactRowHeight: Math.round(popupElementSize * 1.12)
    readonly property int listRowHeight: Math.round(popupElementSize * 1.28)
    readonly property int sectionHeaderHeight: Math.round(popupElementSize * 1.45)
    readonly property int weatherHourlyCellWidth: Math.round(em * 5.4)
    readonly property int dashboardControlCell: Math.round(em * 4.3)
    readonly property int dashboardPopupWidth: dashboardControlCell * 6 + gap * 5 + gap * 2
    readonly property int popupWidth: dashboardPopupWidth
    readonly property int calendarPopupWidth: popupWidth
    readonly property int notificationPopupWidth: popupWidth
    readonly property int dashboardTileHeight: Math.round(em * 3.55)
    readonly property int dashboardSliderHeight: Math.round(em * 3.05)
    readonly property int dashboardSliderThumbSize: Math.round(em * 0.92)
    readonly property int notificationPopupHeight: Math.round(em * 52)
    readonly property int trayIconSize: barIconSize
    readonly property int trayItemSize: barItemHeight
    readonly property int statRowHeight: Math.round(em * 1.75)

    readonly property string weatherLocation: "10001"
    readonly property string weatherApiKeyPath: `${Quickshell.env("HOME")}/.config/quickshell/weather_api_key`
    readonly property bool weatherMetric: true

    readonly property int workspaceGap: Math.round(em * 0.375)
    readonly property int workspaceHeight: barItemHeight
    readonly property int workspaceRadius: generalRadius
    readonly property int workspaceInactivePaddingX: Math.round(em * 0.4)
    readonly property int workspaceActivePaddingX: Math.round(em * 0.4)
    readonly property int workspaceMinWidth: Math.round(em * 1.7)
    readonly property int workspaceActiveMinWidth: Math.round(em * 2.1)

    readonly property color transparentColor: "transparent"
    readonly property color selectedForeground: roleColor("selectedForeground")
    readonly property color selectedBackground: roleColor("selectedBackground")
    readonly property color notSelectedForeground: roleColor("notSelectedForeground")
    readonly property color notSelectedBackground: roleColor("notSelectedBackground")
    readonly property color unselectedForeground: notSelectedForeground
    readonly property color unselectedBackground: notSelectedBackground
    readonly property color barBackground: roleColor("barBackground")
    readonly property color barBorder: roleColor("barBorder")
    readonly property color moduleBackground: roleColor("moduleBackground")
    readonly property color moduleHoverBackground: roleColor("moduleHoverBackground")
    readonly property color workspaceAvailableBackground: notSelectedBackground
    readonly property color workspaceOccupiedBackground: notSelectedBackground
    readonly property color workspaceActiveBackground: selectedBackground
    readonly property color workspaceVirtualBackground: notSelectedBackground
    readonly property color workspaceText: notSelectedForeground
    readonly property color workspaceActiveText: selectedForeground
    readonly property color chipBackground: roleColor("chipBackground")
    readonly property color chipHoverBackground: roleColor("chipHoverBackground")
    readonly property color chipText: notSelectedForeground
    readonly property color iconColor: notSelectedForeground
    readonly property color iconActiveColor: selectedBackground
    readonly property color iconMutedColor: roleColor("iconMutedColor")
    readonly property color iconOnAccentColor: selectedForeground
    readonly property color chipIcon: iconColor
    readonly property color submapActiveBackground: selectedBackground
    readonly property color submapActiveText: selectedForeground
    readonly property color weatherIcon: iconActiveColor
    readonly property color clockIcon: iconColor
    readonly property color popupBackground: roleColor("popupBackground")
    readonly property color popupSectionBackground: roleColor("popupSectionBackground")
    readonly property color popupElevatedBackground: roleColor("popupElevatedBackground")
    readonly property color popupElevatedBorder: roleColor("popupElevatedBorder")
    readonly property color popupHoverBackground: roleColor("popupHoverBackground")
    readonly property color popupSelectedBackground: selectedBackground
    readonly property color popupBorder: roleColor("popupBorder")
    readonly property int popupBorderWidth: 1
    readonly property color popupText: roleColor("popupText")
    readonly property color popupMutedText: roleColor("popupMutedText")
    readonly property color popupAccent: iconActiveColor
    readonly property color calendarWeekendText: roleColor("calendarWeekendText")
    readonly property color popupSuccess: roleColor("popupSuccess")
    readonly property color popupWarning: roleColor("popupWarning")
    readonly property color popupDanger: roleColor("popupDanger")

    property string currentThemeName: currentThemeNameFile.text().trim()
    property var activeTheme: parseJson(themeFile.text())
    readonly property bool isLightTheme: activeTheme.variant === "light"

    FileView {
        id: currentThemeNameFile

        path: theme.currentThemeNamePath
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: theme.currentThemeName = currentThemeNameFile.text().trim()
    }

    FileView {
        id: themeFile

        path: theme.themeFilePath
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            theme.activeTheme = theme.parseJson(text());
            console.info(`QuickShell theme loaded: current='${theme.currentThemeName}' resolved='${theme.themeName}' name='${theme.activeTheme.name || "unknown"}' variant='${theme.activeTheme.variant || "unknown"}' file='${theme.themeFilePath}'`);
        }
    }

    IpcHandler {
        target: "theme"

        function reload(): string {
            return theme.reloadTheme();
        }
    }

    function reloadTheme() {
        currentThemeNameFile.reload();
        theme.currentThemeName = currentThemeNameFile.text().trim();
        themeFile.reload();
        theme.activeTheme = theme.parseJson(themeFile.text());
        console.info(`QuickShell theme loaded: current='${theme.currentThemeName}' resolved='${theme.themeName}' name='${theme.activeTheme.name || "unknown"}' variant='${theme.activeTheme.variant || "unknown"}' file='${theme.themeFilePath}'`);
        return theme.themeName;
    }

    function parseJson(rawText) {
        if (!rawText || rawText.length === 0) {
            return {};
        }

        try {
            return JSON.parse(rawText);
        } catch (error) {
            console.warn(`Failed to parse QuickShell theme JSON: ${error}`);
            return {};
        }
    }

    function resolveThemeName(name) {
        const normalized = String(name || "").trim();
        if (["default-dark", "default-light", "catppuccin-dark", "catppuccin-light", "everforest-dark", "everforest-light"].includes(normalized)) {
            return normalized;
        }
        return normalized.endsWith("-light") ? "default-light" : "default-dark";
    }

    function roleColor(name) {
        const roles = activeTheme && activeTheme.colors ? activeTheme.colors : {};
        return parseColor(roles[name]);
    }

    function parseColor(value) {
        if (typeof value === "string") {
            return value === "transparent" ? transparentColor : value;
        }
        if (value && typeof value === "object" && value.color !== undefined) {
            return withAlpha(value.color, value.alpha === undefined ? 1 : value.alpha);
        }
        return transparentColor;
    }

    function withAlpha(value, alpha) {
        const text = String(value || "");
        if (text === "transparent") {
            return Qt.rgba(0, 0, 0, 0);
        }
        const hex = text.startsWith("#") ? text.slice(1) : text;
        if (hex.length === 6) {
            return Qt.rgba(parseInt(hex.slice(0, 2), 16) / 255, parseInt(hex.slice(2, 4), 16) / 255, parseInt(hex.slice(4, 6), 16) / 255, alpha);
        }
        if (hex.length === 8) {
            return Qt.rgba(parseInt(hex.slice(2, 4), 16) / 255, parseInt(hex.slice(4, 6), 16) / 255, parseInt(hex.slice(6, 8), 16) / 255, alpha);
        }
        return Qt.rgba(0, 0, 0, 0);
    }
}
