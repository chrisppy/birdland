// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick

// Helpers for things attached to a screen edge (bars, docks).
QtObject {
    readonly property var all: ["top", "bottom", "left", "right"]

    function vertical(edge) {
        return edge === "left" || edge === "right";
    }

    // Radius for one corner ("topLeft", "bottomRight"...) of something on
    // `edge`: corners touching the screen edge stay square, the others get
    // `radius`.
    function corner(edge, corner, radius) {
        return corner.toLowerCase().includes(edge) ? 0 : radius;
    }
}
