// SPDX-License-Identifier: GPL-3.0-only
import QtQuick

// Whether the session is kept from going idle, shared by every bar. Each bar
// holds an IdleInhibitor that follows this; see Bar.qml.
QtObject {
    property bool inhibited: false

    function toggle() {
        inhibited = !inhibited;
    }
}
