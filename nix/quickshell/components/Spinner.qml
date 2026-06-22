import QtQuick

// Generic indeterminate spinner: a rotating arc drawn from theme tokens.
// No hardcoded sizes/colors — everything derives from `theme` or the given size.
Item {
    id: root

    required property var theme
    property color color: theme.popupAccent
    property int size: theme.fontSize
    property real thickness: Math.max(1.5, size * 0.13)
    property bool running: visible

    width: size
    height: size

    Canvas {
        id: arc

        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2;
            const r = c - root.thickness;
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(c, c, r, 0, 2 * Math.PI);
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.22);
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(c, c, r, -Math.PI / 2, Math.PI * 0.9);
            ctx.strokeStyle = root.color;
            ctx.stroke();
        }

        onWidthChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    RotationAnimator {
        target: arc
        from: 0
        to: 360
        duration: 850
        loops: Animation.Infinite
        running: root.running
    }
}
