import QtQuick

Text {
    required property var theme

    color: theme.popupText
    font.family: theme.fontFamilyEmphasis
    font.pixelSize: theme.fontSizeSmall
}
