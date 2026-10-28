// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick

QtObject {
    readonly property string family: "Sans-Serif"
    // Icon glyphs. Provided by the nerd-fonts.symbols-only package.
    readonly property string icons: "Symbols Nerd Font"
    readonly property int size: 12
    readonly property int sizeHeader: 16
}
