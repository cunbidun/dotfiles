import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    required property var theme

    property date visibleMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    property var weatherData: null
    property string weatherError: ""
    readonly property int calendarHeaderHeight: Math.round(theme.calendarCellHeight * 1.15)
    readonly property int calendarGridWidth: theme.calendarCellWidth * 7 + theme.gap * 6
    readonly property int calendarGridHeight: theme.calendarCellHeight * 6 + theme.gap * 5
    readonly property int weekdayHeight: Math.round(theme.calendarCellHeight * 0.85)
    readonly property int calendarSectionHeight: calendarHeaderHeight + weekdayHeight + calendarGridHeight + theme.gap * 2 + theme.gap * 2
    readonly property int weatherSectionHeight: theme.calendarCellSize * 4.65

    width: theme.calendarPopupWidth
    height: calendarSectionHeight + weatherSectionHeight + theme.gap + theme.gap * 2
    implicitWidth: width
    implicitHeight: height
    radius: theme.popupSectionRadius
    color: theme.popupBackground
    border.width: theme.popupBorderWidth
    border.color: theme.popupBorder

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Process {
        id: weatherQuery

        command: [
            "bash",
            "-lc",
            `key_path=${JSON.stringify(root.theme.weatherApiKeyPath)}; location=${JSON.stringify(root.theme.weatherLocation)}; key=$(tr -d '\\n' < "$key_path" 2>/dev/null || true); if [ -z "$key" ]; then exit 3; fi; curl -fsS --get --data-urlencode "key=$key" --data-urlencode "q=$location" --data-urlencode "days=2" --data-urlencode "aqi=no" --data-urlencode "alerts=no" https://api.weatherapi.com/v1/forecast.json`
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateWeather(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.weatherError = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && !root.weatherData) {
                root.weatherError = `weather exit ${exitCode}`;
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherQuery.running = true
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.theme.gap
        width: parent.width - root.theme.gap * 2
        height: root.height - root.theme.gap * 2
        spacing: root.theme.gap

        Rectangle {
            id: calendarSection

            width: content.width
            height: root.calendarSectionHeight
            radius: root.theme.popupSectionRadius
            color: root.theme.popupSectionBackground

            Column {
                id: calendarContent

                anchors.centerIn: parent
                spacing: root.theme.gap
                width: root.calendarGridWidth
                height: monthLabel.implicitHeight + weekdayGrid.height + calendarGrid.height + spacing * 2

                Row {
                    width: root.calendarGridWidth
                    height: root.calendarHeaderHeight
                    spacing: 0

                    Text {
                        id: monthLabel

                        width: root.calendarGridWidth - prevChevron.width - nextChevron.width
                        height: parent.height
                        text: root.visibleMonth.toLocaleString(Qt.locale(), "MMMM yyyy")
                        color: root.theme.popupText
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSizeMedium
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: prevChevron

                        text: "‹"
                        width: root.theme.calendarCellWidth
                        height: parent.height
                        color: root.theme.popupAccent
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 1.7
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.ArrowCursor
                            onClicked: root.shiftMonth(-1)
                        }
                    }

                    Text {
                        id: nextChevron

                        text: "›"
                        width: root.theme.calendarCellWidth
                        height: parent.height
                        color: root.theme.popupAccent
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 1.7
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.ArrowCursor
                            onClicked: root.shiftMonth(1)
                        }
                    }
                }

                Grid {
                    id: weekdayGrid

                    width: root.calendarGridWidth
                    height: root.weekdayHeight
                    columns: 7
                    rowSpacing: 0
                    columnSpacing: root.theme.gap

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]

                        Text {
                            required property string modelData

                            width: root.theme.calendarCellWidth
                            height: root.weekdayHeight
                            text: modelData
                            color: root.theme.popupMutedText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeSmall
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Grid {
                    id: calendarGrid

                    width: root.calendarGridWidth
                    height: root.calendarGridHeight
                    columns: 7
                    rowSpacing: root.theme.gap
                    columnSpacing: root.theme.gap

                    Repeater {
                        model: root.calendarCells(root.visibleMonth)

                        Rectangle {
                            required property var modelData

                            width: root.theme.calendarCellWidth
                            height: root.theme.calendarCellHeight
                            color: root.theme.transparentColor

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - root.theme.gap, parent.height - root.theme.gap)
                                height: width
                                radius: width / 2
                                color: modelData.today ? root.theme.popupAccent : root.theme.transparentColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: root.calendarDayColor(modelData)
                                    opacity: modelData.currentMonth || modelData.today ? 1 : 0.45
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: root.theme.fontSize
                                    font.bold: modelData.today
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: weatherSection

            width: content.width
            height: root.weatherSectionHeight
            radius: root.theme.popupSectionRadius
            color: root.theme.popupSectionBackground

            Column {
                id: weatherContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: root.theme.gap
                spacing: root.theme.gap

                Row {
                    width: parent.width
                    spacing: root.theme.gap

                    Text {
                        text: root.weatherData ? root.iconForCondition(root.weatherData.current.condition.code, root.weatherData.current.is_day) : "󰖐"
                        width: root.theme.calendarCellSize
                        color: root.theme.weatherIcon
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize * 2
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - root.theme.calendarCellSize - statsColumn.width - parent.spacing * 2
                        spacing: root.theme.gap * 0.35
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.weatherData ? `${Math.round(root.currentTemp())}° ${root.theme.weatherMetric ? "C" : "F"}` : "Weather"
                            color: root.theme.popupText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeXLarge
                            font.bold: true
                        }

                        Text {
                            text: root.weatherData ? root.weatherData.current.condition.text : root.weatherError
                            color: root.theme.popupMutedText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeSmall
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Column {
                        id: statsColumn

                        spacing: root.theme.gap * 0.3
                        width: root.theme.weatherHourlyCellWidth * 1.2
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.weatherData ? `󰖝 ${Math.round(root.weatherData.current.wind_kph)} km/h` : ""
                            color: root.theme.popupText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeSmall
                        }

                        Text {
                            text: root.weatherData ? `󰖎 ${root.weatherData.current.humidity}%` : ""
                            color: root.theme.popupText
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeSmall
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.theme.popupBorder
                }

                Row {
                    width: parent.width
                    spacing: Math.max(0, (width - root.hourlyForecast().length * root.theme.weatherHourlyCellWidth) / Math.max(1, root.hourlyForecast().length - 1))

                    Repeater {
                        model: root.hourlyForecast()

                        Column {
                            required property var modelData

                            width: root.theme.weatherHourlyCellWidth
                            spacing: root.theme.gap * 0.25

                            Text {
                                width: parent.width
                                text: modelData.time
                                color: root.theme.popupText
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeSmall
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width
                                text: root.iconForCondition(modelData.code, modelData.isDay)
                                color: root.theme.weatherIcon
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSize
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width
                                text: `${Math.round(modelData.temp)}° ${root.theme.weatherMetric ? "C" : "F"}`
                                color: root.theme.popupText
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    function shiftMonth(delta) {
        root.visibleMonth = new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() + delta, 1);
    }

    function calendarCells(monthDate) {
        const firstDay = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1);
        const start = new Date(firstDay);
        start.setDate(1 - firstDay.getDay());

        const today = new Date(clock.date);
        const cells = [];
        for (let index = 0; index < 42; index += 1) {
            const cellDate = new Date(start);
            cellDate.setDate(start.getDate() + index);
            cells.push({
                day: cellDate.getDate(),
                dayOfWeek: cellDate.getDay(),
                currentMonth: cellDate.getMonth() === monthDate.getMonth(),
                today: cellDate.getFullYear() === today.getFullYear() && cellDate.getMonth() === today.getMonth() && cellDate.getDate() === today.getDate()
            });
        }
        return cells;
    }

    function updateWeather(rawText) {
        if (!rawText || rawText.length === 0) {
            return;
        }

        try {
            root.weatherData = JSON.parse(rawText);
            root.weatherError = "";
        } catch (error) {
            root.weatherError = `weather parse ${error}`;
        }
    }

    function currentTemp() {
        return root.theme.weatherMetric ? root.weatherData.current.temp_c : root.weatherData.current.temp_f;
    }

    function calendarDayColor(cell) {
        if (cell.today) {
            return root.theme.selectedForeground;
        }

        if (!cell.currentMonth) {
            return root.theme.popupMutedText;
        }

        return root.theme.popupText;
    }

    function hourlyForecast() {
        if (!root.weatherData?.forecast?.forecastday) {
            return [];
        }

        const nowEpoch = Math.floor(clock.date.getTime() / 1000);
        const hours = [];
        for (const day of root.weatherData.forecast.forecastday) {
            for (const hour of day.hour) {
                if (hour.time_epoch >= nowEpoch) {
                    hours.push({
                        time: new Date(hour.time_epoch * 1000).toLocaleTimeString(Qt.locale(), "hAP"),
                        temp: root.theme.weatherMetric ? hour.temp_c : hour.temp_f,
                        code: hour.condition.code,
                        isDay: hour.is_day
                    });
                }
            }
        }
        return hours.slice(0, 4);
    }

    function iconForCondition(code, isDay) {
        if ([1000].includes(code)) {
            return isDay ? "󰖙" : "󰖔";
        }

        if ([1003, 1006, 1009].includes(code)) {
            return "󰖐";
        }

        if ([1030, 1135, 1147].includes(code)) {
            return "󰖑";
        }

        if ([1063, 1150, 1153, 1168, 1171, 1180, 1183, 1186, 1189, 1192, 1195, 1198, 1201, 1240, 1243, 1246].includes(code)) {
            return "󰖗";
        }

        if ([1066, 1069, 1072, 1114, 1117, 1204, 1207, 1210, 1213, 1216, 1219, 1222, 1225, 1237, 1249, 1252, 1255, 1258, 1261, 1264].includes(code)) {
            return "󰖘";
        }

        if ([1087, 1273, 1276, 1279, 1282].includes(code)) {
            return "󰖓";
        }

        return "󰖐";
    }
}
