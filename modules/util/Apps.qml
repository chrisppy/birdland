// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick

// Starting apps from desktop entries.
QtObject {
    // Start `entry`'s app. With a connected Niri (`niri`, a qml-niri Niri),
    // Niri spawns it: the app then gets its own systemd scope and Niri's
    // environment, so it outlives the service that launched it (Home Manager
    // restarts changed services) and inherits none of that service's
    // variables. Otherwise, or for entries that need a working directory,
    // which Niri's spawn can't set, the entry starts it directly.
    function launch(entry, niri) {
        if (!entry)
            return;
        const command = Array.from(entry.command ?? [], String);
        if (niri && niri.isConnected() && command.length > 0 && !entry.workingDirectory) {
            const result = niri.sendRawAction({
                Spawn: {
                    command: command
                }
            });
            if (result.ok)
                return;
            console.warn("could not launch through niri:", result.error);
        }
        entry.execute();
    }
}
