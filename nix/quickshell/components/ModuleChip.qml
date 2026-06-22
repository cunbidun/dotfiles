import QtQuick

Rectangle {
    id: root

    required property var theme
    property string icon: ""
    property string label: ""
    property bool active: false
    property int maxLabelWidth: 0
    property bool labelFixedWidth: false
    property bool labelTabularFigures: false
    property color iconColor: active ? theme.selectedForeground : theme.chipIcon
    property var activate: () => {}

    visible: label.length > 0 || icon.length > 0
    implicitWidth: content.implicitWidth + theme.chipPaddingX * 2
    implicitHeight: theme.barItemHeight
    width: implicitWidth
    height: implicitHeight
    radius: theme.chipRadius
    color: {
        if (hoverArea.containsMouse) {
            return theme.chipHoverBackground;
        }

        return active ? theme.selectedBackground : theme.chipBackground;
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: root.icon.length > 0 && root.label.length > 0 ? root.theme.iconGap : 0
        height: root.height

        Text {
            id: iconText

            visible: root.icon.length > 0
            height: parent.height
            text: root.icon
            color: root.iconColor
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.barIconSize
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
        }

        Text {
            id: labelText

            visible: root.label.length > 0
            width: root.labelFixedWidth && root.maxLabelWidth > 0
                ? root.maxLabelWidth
                : (root.maxLabelWidth > 0 ? Math.min(implicitWidth, root.maxLabelWidth) : implicitWidth)
            height: parent.height
            text: root.label
            color: root.active ? root.theme.selectedForeground : root.theme.chipText
            elide: Text.ElideRight
            horizontalAlignment: root.labelFixedWidth ? Text.AlignHCenter : Text.AlignLeft
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.features: root.labelTabularFigures ? ({ "tnum": 1 }) : ({})
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.activate()
    }

    function popupX(popupWidth, popupWindowWidth) {
        const minX = root.theme.popupScreenMargin;
        const maxX = Math.max(minX, popupWindowWidth - popupWidth - root.theme.popupScreenMargin);
        return maxX;
    }
}
