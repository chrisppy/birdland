// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import modules.theme

// Large time with the date underneath, for the greeter and lock screen.
Column {
    spacing: Theme.spacingSmall

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: Theme.textBright
        font {
            family: Fonts.family
            pixelSize: 96
            weight: Font.Light
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        color: Theme.text
        font {
            family: Fonts.family
            pixelSize: Fonts.sizeHeader + 4
        }
    }
}
