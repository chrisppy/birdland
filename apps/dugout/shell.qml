// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Niri

// Dugout: application launcher. Runs as its own Quickshell instance, starts
// hidden, and is toggled with `birdland-dugout ipc call dugout toggle`.
ShellRoot {
    id: root

    property bool open: false
    // The monitor to open on: the one with Niri's focused workspace, chosen
    // each time Dugout opens. null lets Quickshell use the primary monitor.
    property var screen: null

    function focusedScreen() {
        const workspaces = niri.workspaces;
        for (let i = 0; i < workspaces.count; i++) {
            const workspace = workspaces.get(i);
            if (!workspace.isFocused)
                continue;
            const screens = Quickshell.screens;
            for (let j = 0; j < screens.length; j++) {
                if (screens[j].name === workspace.output)
                    return screens[j];
            }
        }
        return null;
    }

    function show() {
        if (open)
            return;
        screen = focusedScreen();
        open = true;
    }

    Niri {
        id: niri

        Component.onCompleted: connect()
    }

    IpcHandler {
        target: "dugout"

        function toggle(): void {
            if (root.open)
                root.open = false;
            else
                root.show();
        }
        function show(): void {
            root.show();
        }
        function hide(): void {
            root.open = false;
        }
    }

    // The window only exists while open, so state resets on every show.
    LazyLoader {
        active: root.open

        component: DugoutWindow {
            screen: root.screen
            onCloseRequested: root.open = false
        }
    }
}
