// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// Keeps the session awake: while on, idle timeouts (tarp's lock and screen
// off through swayidle) don't fire. A dim cup while off, a full one while on.
// Click to switch.
Indicator {
    id: root

    required property IdleInhibit idle

    interactive: true
    icon: idle.inhibited ? "\u{F0176}" : "\u{F06CA}" // coffee / coffee-outline
    color: idle.inhibited ? Theme.textBright : Theme.textMuted

    onClicked: idle.toggle()
}
