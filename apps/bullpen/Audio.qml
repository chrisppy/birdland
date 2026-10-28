// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Services.Pipewire
import modules.theme

// Volume of the default output, or with `input` the default microphone.
// PipeWire's defaults are the ones WirePlumber picks, so this follows
// whatever device WirePlumber (or wpctl, pavucontrol...) makes the default.
// Click to mute, scroll to change the volume.
Indicator {
    id: root

    property bool input: false

    readonly property var node: input ? Pipewire.defaultAudioSource : Pipewire.defaultAudioSink
    readonly property var audio: node?.audio ?? null
    readonly property bool muted: audio?.muted ?? false
    readonly property real volume: audio?.volume ?? 0

    // Volume and mute are only valid while the node is bound.
    PwObjectTracker {
        objects: root.node ? [root.node] : []
    }

    available: audio !== null
    interactive: true
    color: muted ? Theme.textMuted : Theme.textBright
    label: Math.round(volume * 100) + "%"
    icon: {
        if (input)
            return muted ? "\u{F036D}" : "\u{F036C}"; // microphone_off / microphone
        if (muted || volume === 0)
            return "\u{F0581}"; // volume_off
        return volume < 0.34 ? "\u{F057F}" : volume < 0.67 ? "\u{F0580}" : "\u{F057E}"; // low / medium / high
    }

    onClicked: {
        if (audio)
            audio.muted = !audio.muted;
    }

    // 5% per wheel notch, up to 100%. Turning the volume up also unmutes.
    onScrolled: steps => {
        if (!audio)
            return;
        audio.volume = Math.max(0, Math.min(1, volume + steps * 0.05));
        if (steps > 0)
            audio.muted = false;
    }
}
