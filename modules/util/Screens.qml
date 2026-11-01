// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick
import Quickshell

// Finding monitors.
QtObject {
    // The monitor with Niri's focused workspace (`niri`, a qml-niri Niri), or
    // null when it isn't known; a window given a null screen opens on the
    // primary monitor.
    function focused(niri) {
        const workspaces = niri?.workspaces;
        if (!workspaces)
            return null;
        for (let i = 0; i < workspaces.count; i++) {
            const workspace = workspaces.get(i);
            if (workspace.isFocused)
                return Array.from(Quickshell.screens).find(screen => screen.name === workspace.output) ?? null;
        }
        return null;
    }
}
