// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell

// Lineup: a dock of favorite and running apps. Runs as its own Quickshell instance.
ShellRoot {
    LazyLoader {
        active: true
        component: LineupWindow {}
    }
}
