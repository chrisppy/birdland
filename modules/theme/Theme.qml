# SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 16

    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 16

    readonly property color background: Base24Colors.base00
    readonly property color backgroundAlt: Base24Colors.base01
    readonly property color surface: Base24Colors.base02
    readonly property color surfaceAlt: Base24Colors.base03
    readonly property color border: Base24Colors.base04
    // Base16 slots: base04 muted foreground, base05 foreground, base06 bright.
    readonly property color textMuted: Base24Colors.base04
    readonly property color text: Base24Colors.base05
    readonly property color textBright: Base24Colors.base06

    readonly property color primary: Base24Colors.base08
    readonly property color secondary: Base24Colors.base09
    readonly property color accent: Base24Colors.base0A
    readonly property color success: Base24Colors.base0B
    readonly property color cyan: Base24Colors.base0C
    readonly property color blue: Base24Colors.base0D
    readonly property color magenta: Base24Colors.base0E
    readonly property color brown: Base24Colors.base0F

    readonly property color activeWorkspace: Base24Colors.base12
    readonly property color inactiveWorkspace: Base24Colors.base02
}
