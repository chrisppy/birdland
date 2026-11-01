// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import modules.theme
import modules.util

// The time and date, in Qt's date format (doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method).
// BULLPEN_CLOCK_FORMAT sets it for top/bottom bars and
// BULLPEN_CLOCK_VERTICAL_FORMAT for side bars, where "\n" starts a new line.
Item {
    id: root

    // Stack the time and date on side bars, where there is no room for one line.
    property bool vertical: false

    readonly property string format: vertical ? Env.get("BULLPEN_CLOCK_VERTICAL_FORMAT", "hh\\nmm\\n\\ndd\\nMMM").replace(/\\n/g, "\n") : Env.get("BULLPEN_CLOCK_FORMAT", "hh:mm dd MMM, yyyy")
    // Wake up every second only for a format that shows seconds ("s" outside
    // quoted text).
    readonly property bool showsSeconds: /s/.test(format.replace(/'[^']*'/g, ""))

    implicitWidth: timeBlock.implicitWidth
    implicitHeight: timeBlock.implicitHeight

    SystemClock {
        id: clock
        precision: root.showsSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Text {
        id: timeBlock

        color: Theme.textBright
        font {
            family: Fonts.family
            pixelSize: Fonts.size
        }

        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter

        text: Qt.formatDateTime(clock.date, root.format)
    }
}
