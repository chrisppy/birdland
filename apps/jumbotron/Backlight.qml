// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io

// The screen's backlight from sysfs: `level` 0-1, and `adjusted()` when it
// changes. The kernel signals changes to actual_brightness, so this needs no
// polling. Without a backlight (desktop monitors), it stays at -1 and quiet.
Scope {
    id: root

    property string device: ""
    property real level: -1
    property int max: 0

    signal adjusted

    // Firmware interfaces first, as brightnessctl and desktops prefer them.
    Process {
        running: true
        command: ["sh", "-c", `
            for type in firmware platform raw; do
              for d in /sys/class/backlight/*; do
                [ "$(cat "$d/type" 2>/dev/null)" = "$type" ] && [ -r "$d/actual_brightness" ] && { echo "$d"; exit; }
              done
            done
            true`]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.device === "" ? "" : root.device + "/max_brightness"
        blockLoading: true
        onLoaded: {
            root.max = Number(text());
            current.reload();
        }
    }

    FileView {
        id: current

        path: root.device === "" ? "" : root.device + "/actual_brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.max <= 0)
                return;
            const level = Number(text()) / root.max;
            const first = root.level < 0;
            if (level === root.level)
                return;
            root.level = level;
            if (!first)
                root.adjusted();
        }
    }
}
