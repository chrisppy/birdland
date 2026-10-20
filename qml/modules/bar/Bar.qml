# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.base00
        bottomLeftRadius: 20
        bottomRightRadius: 20
        // left
        RowLayout {
            anchors {
                left: parent.left
                leftMargin: 25
            }
            Loader {
                active: true
                sourceComponent: Workspaces {}
            }
        }
        // center
        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            Text {
                text: niri.focusedWindow?.title ?? ""
                font {
                    family: Fonts.family
                    pixelSize: Fonts.size + 4
                }

                color: Theme.base04
                elide: Text.ElideRight
            }
        }
        // right
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 25
            }
            spacing: 10
            // Loader {
            //     active: true
            //     sourceComponent: Power {}
            // }
            Loader {
                active: true
                sourceComponent: Clock {}
            }
        }
    }
}
