// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io

// Dugout: application launcher. Runs as its own Quickshell instance, starts
// hidden, and is toggled with `birdland-dugout ipc call dugout toggle`.
ShellRoot {
    id: root

    property bool open: false

    IpcHandler {
        target: "dugout"

        function toggle(): void {
            root.open = !root.open;
        }
        function show(): void {
            root.open = true;
        }
        function hide(): void {
            root.open = false;
        }
    }

    // The window only exists while open, so state resets on every show.
    LazyLoader {
        active: root.open

        component: DugoutWindow {
            onCloseRequested: root.open = false
        }
    }
}
