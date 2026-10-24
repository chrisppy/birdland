# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import modules.theme

Rectangle {
    id: root

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

        anchors.verticalCenter: parent.verticalCenter

        text: Qt.formatDateTime(clock.date, "hh:mm dd MMM, yyyy")
    }
}
