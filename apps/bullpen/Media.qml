// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Services.Mpris
import modules.theme

// The media player that is playing (else the first one that can be
// controlled), from MPRIS: its play state and, on top/bottom bars, the track.
// Click to play or pause, right click for the next track and middle click for
// the previous one. Hidden while no player is open.
Indicator {
    id: root

    // Longer "title – artist" labels are cut short.
    property int maxLength: 40

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players.find(p => p.canControl) ?? null
    readonly property string track: {
        if (!player)
            return "";
        const title = player.trackTitle || player.identity;
        return player.trackArtist ? title + " – " + player.trackArtist : title;
    }

    available: player !== null
    interactive: true
    color: player?.isPlaying ? Theme.textBright : Theme.textMuted
    icon: player?.isPlaying ? "\u{F03E4}" : "\u{F040A}" // pause / play
    label: vertical || track === "" ? "" : track.length > maxLength ? track.slice(0, maxLength - 1).replace(/\s+$/, "") + "…" : track

    onClicked: mouse => {
        if (!player)
            return;
        if (mouse.button === Qt.RightButton) {
            if (player.canGoNext)
                player.next();
        } else if (mouse.button === Qt.MiddleButton) {
            if (player.canGoPrevious)
                player.previous();
        } else if (player.canTogglePlaying) {
            player.togglePlaying();
        }
    }
}
