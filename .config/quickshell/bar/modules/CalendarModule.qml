// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C   A   L   E   N   D   A   R       M   O   D   U   L   E              │
// │   date · the month when open                                             │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// The date and its month; a clicked day is rung until another is picked.
Item {
    id: root

    // Minute precision is enough to catch midnight.
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
    }

    readonly property date today: root.clock.date

    // Weeks start on Monday. Cells outside the month stay blank so every date
    // keeps its weekday column.
    readonly property var cells: {
        const year = root.today.getFullYear()
        const month = root.today.getMonth()
        const shift = (new Date(year, month, 1).getDay() + 6) % 7
        const total = new Date(year, month + 1, 0).getDate()
        const list = []
        for (let blank = 0; blank < shift; blank++)
            list.push(0)
        for (let date = 1; date <= total; date++)
            list.push(date)
        while (list.length % 7 !== 0)
            list.push(0)
        return list
    }

    readonly property var weekdays: ["M", "T", "W", "T", "F", "S", "S"]

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        Item {
            id: page

            // Selected day: today unless another was clicked; reset whenever
            // the detail is rebuilt.
            property int picked: 0

            readonly property int day: page.picked > 0 ? page.picked : root.today.getDate()

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(root.clock.date, "MMMM yyyy")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(root.clock.date, "dddd d")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                    }
                }

                Grid {
                    id: month

                    width: parent.width
                    height: 150
                    columns: 7

                    readonly property real cellWidth: width / 7
                    readonly property real cellHeight: height / 7

                    Repeater {
                        model: root.weekdays

                        Item {
                            required property var modelData

                            width: month.cellWidth
                            height: month.cellHeight

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: Font.DemiBold
                                color: Theme.textMuted
                            }
                        }
                    }

                    Repeater {
                        model: root.cells

                        Item {
                            id: cell

                            required property int modelData

                            readonly property bool today:
                                cell.modelData === root.today.getDate()
                            readonly property bool picked:
                                cell.modelData > 0 && cell.modelData === page.day && !cell.today

                            width: month.cellWidth
                            height: month.cellHeight

                            // Today takes the accent; the selected day gets an
                            // accent ring.
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 2
                                height: width
                                radius: width / 2
                                visible: cell.today || cell.picked
                                color: cell.today ? Theme.accent : "transparent"
                                border.color: Theme.accent
                                border.width: cell.picked ? 1 : 0
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: cell.modelData > 0
                                text: `${cell.modelData}`
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: cell.today ? Font.DemiBold : Font.Normal
                                color: cell.today ? Theme.accentText : Theme.text
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: cell.modelData > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.picked = cell.today ? 0 : cell.modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
