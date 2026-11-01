// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Niri
import modules.theme
import modules.util

// Jumbotron: a short pop-up on the focused monitor when the volume, the
// microphone's mute or the screen brightness changes, however it was changed
// (keys bound to wpctl or brightnessctl, a mixer, the bar). It only shows
// changes; it doesn't change anything itself.
//
//   variable            meaning
//   JUMBOTRON_POSITION  top, bottom (default), left or right
ShellRoot {
    id: root

    readonly property string edge: Env.edge("JUMBOTRON_POSITION", "bottom")

    // What to show: "volume", "microphone" or "brightness".
    property string kind: ""
    property bool shown: false
    property var screen: null

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Changes in the first moments after start, or after the default device
    // changes, are the values arriving, not someone changing them.
    property bool armed: false

    function show(what) {
        if (!armed)
            return;
        if (!shown)
            screen = Screens.focused(niri);
        kind = what;
        shown = true;
        hideTimer.restart();
    }

    function settle() {
        armed = false;
        armTimer.restart();
    }

    onSinkChanged: settle()
    onSourceChanged: settle()

    Timer {
        id: armTimer

        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.shown = false
    }

    Niri {
        id: niri

        Component.onCompleted: connect()
    }

    // Volume and mute are only valid while the nodes are bound.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged() {
            root.show("volume");
        }
        function onMutedChanged() {
            root.show("volume");
        }
    }

    Connections {
        target: root.source?.audio ?? null

        function onMutedChanged() {
            root.show("microphone");
        }
    }

    Backlight {
        id: backlight

        onAdjusted: root.show("brightness")
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            screen: root.screen
            color: "transparent"
            implicitWidth: osd.implicitWidth
            implicitHeight: osd.implicitHeight
            exclusionMode: ExclusionMode.Ignore
            // Clicks go through to whatever is underneath.
            mask: Region {}

            anchors {
                top: root.edge === "top"
                bottom: root.edge === "bottom"
                left: root.edge === "left"
                right: root.edge === "right"
            }
            margins {
                top: 72
                bottom: 72
                left: 72
                right: 72
            }

            WlrLayershell.namespace: "birdland-jumbotron"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Level {
                id: osd

                vertical: Edges.vertical(root.edge)
                icon: {
                    if (root.kind === "brightness") {
                        const level = backlight.level;
                        return level < 0.34 ? "\u{F00DE}" : level < 0.67 ? "\u{F00DF}" : "\u{F00E0}"; // brightness_5..7
                    }
                    if (root.kind === "microphone")
                        return root.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"; // microphone_off / microphone
                    const audio = root.sink?.audio;
                    if (!audio || audio.muted || audio.volume === 0)
                        return "\u{F0581}"; // volume_off
                    return audio.volume < 0.34 ? "\u{F057F}" : audio.volume < 0.67 ? "\u{F0580}" : "\u{F057E}"; // low / medium / high
                }
                // The microphone shows its mute state only.
                value: root.kind === "brightness" ? backlight.level : root.kind === "microphone" ? -1 : (root.sink?.audio?.volume ?? 0)
                muted: root.kind === "volume" ? (root.sink?.audio?.muted ?? false) : root.kind === "microphone" ? (root.source?.audio?.muted ?? false) : false
            }
        }
    }
}
