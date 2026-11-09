// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Wayland
import modules.theme
import modules.util

PanelWindow {
    id: root

    // Screen edge the dock is attached to: top, bottom, left or right.
    // Set with the LINEUP_POSITION environment variable (default: bottom).
    readonly property string edge: Env.edge("LINEUP_POSITION", "bottom")
    readonly property bool vertical: ScreenEdges.vertical(edge)

    // Favorite desktop entry IDs, comma separated, in display order.
    // Set with the LINEUP_FAVORITES environment variable.
    readonly property var favorites: Env.list("LINEUP_FAVORITES")

    // Icon size in pixels, set with LINEUP_ICON_SIZE (default: 32). Each slot
    // is the icon plus room for the hover highlight and running indicator,
    // so the dock's thickness follows the icon size.
    readonly property int iconSize: Math.max(16, Math.min(256, Number(Env.get("LINEUP_ICON_SIZE", "32")) || 32))
    readonly property int itemSize: iconSize + 12

    // The desktop entries for the favorites. IDs that match no installed app
    // are skipped.
    readonly property var favoriteEntries: {
        // Reading the app list makes this re-run once entries finish loading.
        if (DesktopEntries.applications.values.length === 0)
            return [];
        const entries = [];
        for (const id of favorites) {
            const entry = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
            // Two favorites can name the same app ("firefox", "org.mozilla.firefox").
            if (entry && !entries.some(e => e.id === entry.id))
                entries.push(entry);
        }
        return entries;
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
    // "firefox" vs "org.mozilla.firefox"), so compare a few ways, ending with
    // the lookup runningEntries uses to find an app ID's entry.
    function matches(entry, appId) {
        const app = appId.toLowerCase();
        if (app === "")
            return false;

        const id = entry.id.toLowerCase();
        const wmClass = entry.startupClass.toLowerCase();
        if (app === id || (wmClass !== "" && app === wmClass) || id.endsWith("." + app) || app.endsWith("." + id))
            return true;
        return (DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId))?.id === entry.id;
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

        radius: Theme.radiusXLarge
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
                // Keeps existing icons when the list changes, instead of
                // recreating them all; entries match by desktop entry id.
                model: ScriptModel {
                    values: root.favoriteEntries
                    objectProp: "id"
                }

                LineupItem {
                    required property var modelData

                    entry: modelData
                    edge: root.edge
                    matcher: root.matches
                    iconSize: root.iconSize
                }
            }

            // Divider between favorites and the other running apps.
            Item {
                visible: root.favoriteEntries.length > 0 && root.runningEntries.length > 0
                width: root.vertical ? root.itemSize : 1
                height: root.vertical ? 1 : root.itemSize

                Rectangle {
                    anchors.centerIn: parent
                    width: root.vertical ? root.iconSize - 4 : 1
                    height: root.vertical ? 1 : root.iconSize - 4
                    color: Theme.border
                }
            }

            Repeater {
                // Keeps existing icons when the list changes, instead of
                // recreating them all; entries match by desktop entry id.
                model: ScriptModel {
                    values: root.runningEntries
                    objectProp: "id"
                }

                LineupItem {
                    required property var modelData

                    entry: modelData
                    edge: root.edge
                    matcher: root.matches
                    iconSize: root.iconSize
                }
            }
        }
    }
}
