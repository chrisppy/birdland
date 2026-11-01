// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Io

// A JSON settings file whose path is in the environment variable `variable`,
// as written by the Home Manager and NixOS modules. `values` is its contents,
// or {} when the variable is unset or the file can't be read.
FileView {
    id: root

    required property string variable
    readonly property var values: {
        if (path === "")
            return {};
        try {
            return JSON.parse(text());
        } catch (e) {
            console.warn("could not read settings from", path, e);
            return {};
        }
    }

    path: Env.get(variable)
    blockLoading: true
}
