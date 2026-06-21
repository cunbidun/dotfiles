import QtQuick

Text {
    required property var theme

    color: theme.popupText
    font.family: theme.fontFamily
    font.pixelSize: theme.fontSizeSmall
    font.bold: true
}
