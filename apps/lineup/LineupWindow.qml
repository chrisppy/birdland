// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Wayland
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
    readonly property var favoriteEntries: {
        // Reading the app list makes this re-run once entries finish loading.
        if (DesktopEntries.applications.values.length === 0)
            return [];
        return favorites.map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id)).filter(e => !!e);
    }

    // Running apps that aren't favorites, one per app. A window whose app has
    // no desktop entry gets a stand-in so it still shows up.
    readonly property var runningEntries: {
        const found = [];
        if (DesktopEntries.applications.values.length === 0)
            return found;

        for (const toplevel of ToplevelManager.toplevels.values) {
            const appId = toplevel.appId;
            if (appId === "" || favoriteEntries.some(e => matches(e, appId)) || found.some(e => matches(e, appId)))
                continue;

            found.push(DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? ({
                    id: appId,
                    name: appId,
                    icon: appId,
                    startupClass: "",
                    execute: () => {}
                }));
        }
        return found;
    }

    // Window app IDs don't always equal the desktop entry ID (for example
    // "firefox" vs "org.mozilla.firefox"), so compare a few ways.
    function matches(entry, appId) {
        const app = appId.toLowerCase();
        if (app === "")
            return false;

        const id = entry.id.toLowerCase();
        const wmClass = entry.startupClass.toLowerCase();
        return app === id || (wmClass !== "" && app === wmClass) || id.endsWith("." + app) || app.endsWith("." + id);
    }

    // A zero-sized layer surface is invalid, so only show with something in it.
    visible: favoriteEntries.length + runningEntries.length > 0
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
                model: root.favoriteEntries

                LineupItem {
                    required property var modelData

                    entry: modelData
                    edge: root.edge
                    matcher: root.matches
                }
            }

            // Divider between favorites and the other running apps.
            Item {
                visible: root.favoriteEntries.length > 0 && root.runningEntries.length > 0
                width: root.vertical ? 44 : 1
                height: root.vertical ? 1 : 44

                Rectangle {
                    anchors.centerIn: parent
                    width: root.vertical ? 28 : 1
                    height: root.vertical ? 1 : 28
                    color: Theme.border
                }
            }

            Repeater {
                model: root.runningEntries

                LineupItem {
                    required property var modelData

                    entry: modelData
                    edge: root.edge
                    matcher: root.matches
                }
            }
        }
    }
}
