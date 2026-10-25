# SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import modules.theme

PanelWindow {
    id: bar

    // Screen edge the bar is attached to: top, bottom, left or right.
    // Set with the BULLPEN_POSITION environment variable (default: top).
    readonly property string edge: {
        const value = String(Quickshell.env("BULLPEN_POSITION") ?? "top").toLowerCase();
        return ["top", "bottom", "left", "right"].includes(value) ? value : "top";
    }
    readonly property bool vertical: edge === "left" || edge === "right"

    implicitWidth: vertical ? 48 : 0
    implicitHeight: vertical ? 0 : 30
    color: Theme.background

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        // Round the two corners on the side facing the screen.
        topLeftRadius: bar.edge === "bottom" || bar.edge === "right" ? 20 : 0
        topRightRadius: bar.edge === "bottom" || bar.edge === "left" ? 20 : 0
        bottomLeftRadius: bar.edge === "top" || bar.edge === "right" ? 20 : 0
        bottomRightRadius: bar.edge === "top" || bar.edge === "left" ? 20 : 0

        // start: workspaces, flush with the screen edge
        Loader {
            active: true
            sourceComponent: Workspaces {
                edge: bar.edge
            }

            anchors {
                top: bar.edge !== "bottom" ? parent.top : undefined
                bottom: bar.edge === "bottom" ? parent.bottom : undefined
                left: bar.edge !== "right" ? parent.left : undefined
                right: bar.edge === "right" ? parent.right : undefined
                leftMargin: bar.vertical ? 0 : Theme.spacingMedium
                topMargin: bar.vertical ? Theme.spacingMedium : 0
            }
        }
        // center: focused window title (horizontal bars only)
        RowLayout {
            visible: !bar.vertical
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
        // end: clock
        Loader {
            active: true
            sourceComponent: Clock {
                vertical: bar.vertical
            }

            anchors {
                right: bar.vertical ? undefined : parent.right
                rightMargin: Theme.spacingMedium
                verticalCenter: bar.vertical ? undefined : parent.verticalCenter
                bottom: bar.vertical ? parent.bottom : undefined
                bottomMargin: Theme.spacingMedium
                horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
            }
        }
    }
}
