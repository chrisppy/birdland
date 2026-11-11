// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme
import modules.util

// Announcer's do not disturb: a dim bell while notifications show, a bright
// crossed-out bell while they are held back. Click to switch. Hidden until
// Announcer has run in this session, since nothing else reads the setting.
Indicator {
    id: root

    required property DoNotDisturb dnd

    available: dnd.available
    interactive: true
    icon: dnd.enabled ? "\u{F009B}" : "\u{F009C}" // bell-off / bell-outline
    color: dnd.enabled ? Theme.textBright : Theme.textMuted

    onClicked: dnd.toggle()
}
