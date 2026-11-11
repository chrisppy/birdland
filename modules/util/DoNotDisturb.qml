// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io

// Announcer's do not disturb, kept in $XDG_RUNTIME_DIR/birdland-announcer.dnd
// ("on" or "off") so other apps can show and change it: Announcer reads it to
// decide which notifications to drop, and Bullpen's `dnd` indicator shows it
// and flips it on click. Either side writing the file updates the other.
//
// The file lasts until logout, so do not disturb survives Announcer
// restarting. Announcer creates it when it starts (`owner`); until then other
// apps see `available` false.
Scope {
    id: root

    // True in Announcer: creates the file, "off", if it is missing.
    property bool owner: false

    // Do not disturb is on.
    property bool enabled: false
    // The file exists: Announcer has run in this session.
    property bool available: false

    readonly property string path: Env.get("XDG_RUNTIME_DIR") === "" ? "" : Env.get("XDG_RUNTIME_DIR") + "/birdland-announcer.dnd"

    function set(on) {
        enabled = on;
        if (path === "") {
            available = owner;
            return;
        }
        available = true;
        file.setText(on ? "on\n" : "off\n");
    }

    function toggle() {
        set(!enabled);
    }

    FileView {
        id: file

        path: root.path
        // Watches the folder too, so a file created later is still noticed.
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            const value = text().trim();
            // Anything else is a write still in progress; wait for the next change.
            if (value !== "on" && value !== "off")
                return;
            root.enabled = value === "on";
            root.available = true;
        }
        onLoadFailed: {
            if (root.owner)
                root.set(false);
            else
                root.available = false;
        }
    }

    Component.onCompleted: {
        // Without XDG_RUNTIME_DIR there is no file: Announcer keeps the state
        // to itself and the bar indicator stays hidden.
        if (path === "")
            available = owner;
    }
}
