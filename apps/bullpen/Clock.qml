# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import modules.theme

Rectangle {
    id: root

    // Stack the time and date on side bars, where there is no room for one line.
    property bool vertical: false

    implicitWidth: timeBlock.implicitWidth
    implicitHeight: timeBlock.implicitHeight
    color: Theme.background

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
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

        text: Qt.formatDateTime(clock.date, root.vertical ? "hh\nmm\n\ndd\nMMM" : "hh:mm dd MMM, yyyy")
    }
}
