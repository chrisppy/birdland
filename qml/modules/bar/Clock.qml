# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."

Rectangle {
    id: root

    implicitWidth: timeBlock.implicitWidth
    implicitHeight: timeBlock.implicitHeight
    color: "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        id: timeBlock

        anchors.verticalCenter: parent.verticalCenter

        text: Qt.formatDateTime(clock.date, "hh:mm dd MMM, yyyy")
        color: Theme.base05

        font {
            family: Fonts.family
            pixelSize: Fonts.size
        }
    }
}
