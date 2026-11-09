// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import modules.theme

// The current time or date, in Qt's date format
// (doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method). The bar uses it
// for both the `clock` and `date` modules, with their own formats.
Item {
    id: root

    // Side bars use verticalFormat, where there is no room for one line.
    property bool vertical: false
    // Formats for top/bottom bars and for side bars; in the vertical one a
    // line break or "\n" starts a new line.
    property string horizontalFormat: "hh:mm"
    property string verticalFormat: "hh\nmm"

    readonly property string format: vertical ? verticalFormat.replace(/\\n/g, "\n") : horizontalFormat
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
