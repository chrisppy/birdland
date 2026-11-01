// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell

// Lineup: a dock of favorite and running apps on every monitor. Runs as its
// own Quickshell instance.
ShellRoot {
    Variants {
        model: Quickshell.screens

        LineupWindow {
            required property var modelData

            screen: modelData
        }
    }
}
