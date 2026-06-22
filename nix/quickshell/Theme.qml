import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    readonly property string stylixColorsPath: `${Quickshell.env("HOME")}/.local/state/stylix/colors.json`
    readonly property string stylixThemeNamePath: `${Quickshell.env("HOME")}/.local/state/stylix/current-theme-name.txt`
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
    readonly property color appleSystemBlue: isLightTheme ? "#007AFF" : "#0A84FF"
    readonly property color appleLabel: isLightTheme ? "#000000" : "#FFFFFF"
    readonly property color appleSecondaryLabel: isLightTheme ? "#3C3C43" : "#EBEBF5"
    readonly property color appleTertiaryLabel: isLightTheme ? "#8E8E93" : "#8E8E93"
    readonly property color appleSystemBackground: isLightTheme ? "#FFFFFF" : "#1C1C1E"
    readonly property color appleSecondarySystemBackground: isLightTheme ? "#F2F2F7" : "#2C2C2E"
    readonly property color appleTertiarySystemBackground: isLightTheme ? "#FFFFFF" : "#3A3A3C"
    readonly property color appleSeparator: isLightTheme ? withAlpha("#3C3C43", 0.22) : withAlpha("#545458", 0.65)
    readonly property color appleFill: isLightTheme ? withAlpha("#787880", 0.20) : withAlpha("#787880", 0.36)
    readonly property color appleFillHover: isLightTheme ? withAlpha("#787880", 0.28) : withAlpha("#787880", 0.44)
    readonly property color selectedForeground: "#FFFFFF"
    readonly property color selectedBackground: appleSystemBlue
    readonly property color notSelectedForeground: appleLabel
    readonly property color notSelectedBackground: appleFill
    readonly property color unselectedForeground: notSelectedForeground
    readonly property color unselectedBackground: notSelectedBackground
    readonly property color barBackground: transparentColor
    readonly property color barBorder: appleSeparator
    readonly property color moduleBackground: withAlpha(appleSecondarySystemBackground, isLightTheme ? 0.78 : 0.62)
    readonly property color moduleHoverBackground: appleFillHover
    readonly property color workspaceAvailableBackground: notSelectedBackground
    readonly property color workspaceOccupiedBackground: notSelectedBackground
    readonly property color workspaceActiveBackground: selectedBackground
    readonly property color workspaceVirtualBackground: notSelectedBackground
    readonly property color workspaceText: notSelectedForeground
    readonly property color workspaceActiveText: selectedForeground
    readonly property color chipBackground: withAlpha(appleSecondarySystemBackground, isLightTheme ? 0.78 : 0.62)
    readonly property color chipHoverBackground: appleFillHover
    readonly property color chipText: notSelectedForeground
    readonly property color iconColor: notSelectedForeground
    readonly property color iconActiveColor: selectedBackground
    readonly property color iconMutedColor: appleTertiaryLabel
    readonly property color iconOnAccentColor: selectedForeground
    readonly property color chipIcon: iconColor
    readonly property color submapActiveBackground: selectedBackground
    readonly property color submapActiveText: selectedForeground
    readonly property color weatherIcon: iconActiveColor
    readonly property color clockIcon: iconColor
    readonly property color popupBackground: withAlpha(appleSystemBackground, isLightTheme ? 0.55 : 0.40)
    readonly property color popupSectionBackground: withAlpha(appleSecondarySystemBackground, isLightTheme ? 0.45 : 0.30)
    readonly property color popupElevatedBackground: withAlpha(appleSecondarySystemBackground, isLightTheme ? 0.82 : 0.72)
    readonly property color popupElevatedBorder: isLightTheme ? withAlpha("#000000", 0.12) : withAlpha("#FFFFFF", 0.16)
    readonly property color popupHoverBackground: appleFillHover
    readonly property color popupSelectedBackground: selectedBackground
    readonly property color popupBorder: appleSeparator
    readonly property int popupBorderWidth: 1
    readonly property color popupText: appleLabel
    readonly property color popupMutedText: appleTertiaryLabel
    readonly property color popupAccent: iconActiveColor
    readonly property color calendarWeekendText: color("color9")
    readonly property color popupSuccess: color("color10")
    readonly property color popupWarning: color("color11")
    readonly property color popupDanger: color("color9")

    property var stylix: parseJson(stylixColors.text())
    property string stylixThemeName: stylixThemeNameFile.text().trim()
    readonly property bool isLightTheme: stylixThemeName.endsWith("-light")

    FileView {
        id: stylixColors

        path: theme.stylixColorsPath
        blockLoading: true
        printErrors: true
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: theme.stylix = theme.parseJson(text())
    }

    FileView {
        id: stylixThemeNameFile

        path: theme.stylixThemeNamePath
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: theme.stylixThemeName = stylixThemeNameFile.text().trim()
    }

    function parseJson(rawText) {
        if (!rawText || rawText.length === 0) {
            return {};
        }

        try {
            return JSON.parse(rawText);
        } catch (error) {
            console.warn(`Failed to parse Stylix colors: ${error}`);
            return {};
        }
    }

    function color(name) {
        const palette = stylix && stylix.colors ? stylix.colors : {};
        return palette[name] || palette.color0 || transparentColor;
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
