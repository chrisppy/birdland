// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import modules.theme

PanelWindow {
    id: root

    // Screen edge the dock is attached to: top, bottom, left or right.
    // Set with the LINEUP_POSITION environment variable (default: bottom).
    readonly property string edge: {
        const value = String(Quickshell.env("LINEUP_POSITION") ?? "bottom").toLowerCase();
        return ["top", "bottom", "left", "right"].includes(value) ? value : "bottom";
    }
    readonly property bool vertical: edge === "left" || edge === "right"

    // Favorite desktop entry IDs, comma separated, in display order.
    // Set with the LINEUP_FAVORITES environment variable.
    readonly property var favorites: String(Quickshell.env("LINEUP_FAVORITES") ?? "").split(",").map(s => s.trim()).filter(s => s.length > 0)

    // The desktop entries for the favorites. IDs that match no installed app
    // are skipped.
    readonly property var entries: {
        // Reading the app list makes this re-run once entries finish loading.
        if (DesktopEntries.applications.values.length === 0)
            return [];
        return favorites.map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id)).filter(e => !!e);
    }

    // A zero-sized layer surface is invalid, so only show with something in it.
    visible: entries.length > 0
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // Anchoring to a single edge centers the dock along it.
    anchors {
        top: edge === "top"
        bottom: edge === "bottom"
        left: edge === "left"
        right: edge === "right"
    }

    // Float slightly off the screen edge.
    margins {
        top: edge === "top" ? Theme.spacingMedium : 0
        bottom: edge === "bottom" ? Theme.spacingMedium : 0
        left: edge === "left" ? Theme.spacingMedium : 0
        right: edge === "right" ? Theme.spacingMedium : 0
    }

    Rectangle {
        id: card

        anchors.fill: parent
        implicitWidth: items.implicitWidth + Theme.spacingMedium * 2
        implicitHeight: items.implicitHeight + Theme.spacingMedium * 2

        radius: Theme.radiusLarge + 4
        color: Theme.background
        border {
            width: 1
            color: Theme.border
        }

        Flow {
            id: items

            anchors.centerIn: parent
            flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
            spacing: Theme.spacingSmall

            Repeater {
                model: root.entries

                LineupItem {
                    required property var modelData

                    entry: modelData
                    edge: root.edge
                }
            }
        }
    }
}
