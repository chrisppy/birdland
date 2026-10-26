// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
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

    // One line of text on top/bottom bars; room for the stacked clock on the sides.
    readonly property int thickness: vertical ? 48 : 30

    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? 0 : thickness
    // Transparent, so the screen shows through the panel's rounded corners.
    color: "transparent"

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
        topLeftRadius: bar.edge === "bottom" || bar.edge === "right" ? Theme.radiusXLarge : 0
        topRightRadius: bar.edge === "bottom" || bar.edge === "left" ? Theme.radiusXLarge : 0
        bottomLeftRadius: bar.edge === "top" || bar.edge === "right" ? Theme.radiusXLarge : 0
        bottomRightRadius: bar.edge === "top" || bar.edge === "left" ? Theme.radiusXLarge : 0

        // start: workspaces, flush with the screen edge
        Workspaces {
            id: workspaces

            edge: bar.edge

            anchors {
                top: bar.edge !== "bottom" ? parent.top : undefined
                bottom: bar.edge === "bottom" ? parent.bottom : undefined
                left: bar.edge !== "right" ? parent.left : undefined
                right: bar.edge === "right" ? parent.right : undefined
                leftMargin: bar.vertical ? 0 : Theme.spacingMedium
                topMargin: bar.vertical ? Theme.spacingMedium : 0
            }
        }

        // center: focused window title (horizontal bars only). Its width keeps
        // it clear of the workspaces and clock on both sides, so it stays
        // centered and long titles are elided instead of overlapping them.
        Text {
            visible: !bar.vertical
            anchors.centerIn: parent
            width: Math.max(0, Math.min(implicitWidth, parent.width - 2 * (Math.max(workspaces.width, clock.width) + Theme.spacingMedium + Theme.spacingLarge)))

            text: niri.focusedWindow?.title ?? ""
            color: Theme.textBright
            elide: Text.ElideRight
            font {
                family: Fonts.family
                pixelSize: Fonts.size
            }
        }

        // end: clock
        Clock {
            id: clock

            vertical: bar.vertical

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
