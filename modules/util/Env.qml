// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick
import Quickshell

// Reading settings from environment variables.
QtObject {
    // The variable's value, or `fallback` when it is unset. Set but empty is "".
    function get(name, fallback = "") {
        const value = Quickshell.env(name);
        return value === null || value === undefined ? fallback : String(value);
    }

    // "~/x" -> "$HOME/x"; other paths unchanged.
    function expandHome(path) {
        return path.startsWith("~/") ? get("HOME") + path.slice(1) : path;
    }

    // A comma-separated list, trimmed, without empty entries. `fallback` (also
    // comma-separated) is used only when the variable is unset, so setting it
    // empty gives an empty list.
    function list(name, fallback = "") {
        return get(name, fallback).split(",").map(s => s.trim()).filter(s => s !== "");
    }

    // A comma-separated list whose entries may join several names with "+":
    // "a+b,c" -> [["a", "b"], ["c"]]. Unset uses `fallback`, as in list().
    function groups(name, fallback = "") {
        return list(name, fallback).map(entry => entry.split("+").map(s => s.trim()).filter(s => s !== "")).filter(group => group.length > 0);
    }

    // A screen edge: top, bottom, left or right, else `fallback`.
    function edge(name, fallback) {
        const value = get(name).toLowerCase();
        return ScreenEdges.all.includes(value) ? value : fallback;
    }
}
