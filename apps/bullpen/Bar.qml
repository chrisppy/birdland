# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import modules.theme

PanelWindow {
    id: bar
    implicitHeight: 30
    color: Theme.background

    anchors {
        top: true
        left: true
        right: true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        bottomLeftRadius: 20
        bottomRightRadius: 20
        border.color: Theme.border
        border.width: 1

        // left
        RowLayout {
            anchors {
                left: parent.left
                leftMargin: Theme.spacingMedium
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
                    pixelSize: Fonts.size
                }

                color: Theme.textBright
                elide: Text.ElideRight
            }
        }
        // right
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Theme.spacingMedium
            }
            spacing: Theme.spacingMedium
            Loader {
                active: true
                sourceComponent: Clock {}
            }
        }
    }
}
