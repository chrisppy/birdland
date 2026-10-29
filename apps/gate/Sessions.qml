// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQml.Models
import Qt.labs.folderlistmodel
import Quickshell.Io

// The Wayland sessions described by the .desktop files in `dir`, sorted by
// name: [{ id, name, exec, desktopNames }]. Entries marked Hidden or
// NoDisplay are left out.
Item {
    id: root

    property string dir: ""
    property var sessions: []

    // The [Desktop Entry] section of a .desktop file, as a key -> value map.
    function parseDesktopEntry(text) {
        const entry = {};
        let inEntry = false;
        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line.startsWith("[")) {
                inEntry = line === "[Desktop Entry]";
                continue;
            }
            const eq = line.indexOf("=");
            if (!inEntry || line.startsWith("#") || eq < 0)
                continue;
            const key = line.slice(0, eq).trim();
            // Unlocalized keys only ("Name", not "Name[de]").
            if (!key.includes("["))
                entry[key] = line.slice(eq + 1).trim();
        }
        return entry;
    }

    function rebuild() {
        const list = [];
        for (let i = 0; i < readers.count; i++) {
            const reader = readers.objectAt(i);
            if (!reader || !reader.ready)
                continue;
            const entry = parseDesktopEntry(reader.text());
            if (!entry.Exec || entry.Hidden === "true" || entry.NoDisplay === "true")
                continue;
            list.push({
                id: reader.sessionId,
                name: entry.Name || reader.sessionId,
                exec: entry.Exec,
                desktopNames: (entry.DesktopNames || "").split(";").filter(s => s !== "").join(":")
            });
        }
        list.sort((a, b) => a.name.localeCompare(b.name));
        sessions = list;
    }

    FolderListModel {
        id: files

        folder: root.dir === "" ? "" : "file://" + root.dir
        nameFilters: ["*.desktop"]
        showDirs: false
    }

    Instantiator {
        id: readers

        model: files

        delegate: FileView {
            required property string filePath
            required property string fileName
            // "niri.desktop" -> "niri"; names may contain other dots.
            readonly property string sessionId: fileName.replace(/\.desktop$/, "")

            property bool ready: false

            path: filePath
            blockLoading: true
            onLoaded: {
                ready = true;
                root.rebuild();
            }
        }

        onObjectAdded: root.rebuild()
        onObjectRemoved: root.rebuild()
    }
}
