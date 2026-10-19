# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../.."

Rectangle {
    id: root

    implicitWidth: powerDisplay.implicitWidth
    implicitHeight: powerDisplay.implicitHeight
    color: "transparent"

    Text {
        id: powerDisplay

        anchors.verticalCenter: parent.verticalCenter

        text: Number(UPower.displayDevice.percentage * 100).toFixed(2) + "%"
        color: Theme.base05

        font {
            family: Fonts.family
            pixelSize: Fonts.size + 4
        }
    }
}
