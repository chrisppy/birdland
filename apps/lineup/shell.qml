// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Niri

// Lineup: a dock of favorite and running apps on every monitor. Runs as its
// own Quickshell instance.
ShellRoot {
    // Apps are launched through Niri; see Apps.launch.
    Niri {
        id: niri

        Component.onCompleted: connect()
    }

    Variants {
        model: Quickshell.screens

        LineupWindow {
            required property var modelData

            screen: modelData
        }
    }
}
