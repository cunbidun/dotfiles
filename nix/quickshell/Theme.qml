import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    readonly property string stylixColorsPath: `${Quickshell.env("HOME")}/.local/state/stylix/colors.json`
    readonly property int fontSize: 13
    readonly property string fontFamily: "SFMono Nerd Font"

    readonly property real em: fontSize
    readonly property real rem: fontSize

    readonly property int barHeight: Math.round(em * 2.25)
    readonly property int barOuterSpacing: Math.round(em * 0.5)
    readonly property int barRadius: 0
    readonly property int barBorderWidth: 0

    readonly property int moduleGap: Math.round(em * 0.35)
    readonly property int modulePaddingX: Math.round(rem * 0.6)
    readonly property int modulePaddingY: 0
    readonly property int moduleMarginY: Math.round(em * 0.1)

    readonly property int workspaceGap: Math.round(rem * 0.375)
    readonly property int workspaceHeight: Math.round(em * 1.7)
    readonly property int workspaceRadius: Math.round(em * 0.7)
    readonly property int workspaceInactivePaddingX: Math.round(em * 0.4)
    readonly property int workspaceActivePaddingX: Math.round(em * 0.4)
    readonly property int workspaceMinWidth: Math.round(em * 1.7)
    readonly property int workspaceActiveMinWidth: Math.round(em * 2.1)

    readonly property color transparentColor: "transparent"
    readonly property color barBackground: color("color0")
    readonly property color barBorder: color("color2")
    readonly property color moduleBackground: color("color1")
    readonly property color moduleHoverBackground: color("color2")
    readonly property color workspaceAvailableBackground: color("color2")
    readonly property color workspaceOccupiedBackground: color("color4")
    readonly property color workspaceActiveBackground: color("color12")
    readonly property color workspaceVirtualBackground: color("color13")
    readonly property color workspaceText: color("color6")
    readonly property color workspaceActiveText: color("color0")

    property var stylix: parseJson(stylixColors.text())

    FileView {
        id: stylixColors

        path: theme.stylixColorsPath
        blockLoading: true
        printErrors: true
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: theme.stylix = theme.parseJson(text())
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
}
