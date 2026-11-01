// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import modules.theme
import modules.util
import modules.wallpaper

// Outfield: wallpapers. One background-layer window per monitor, showing an
// image or a rotating folder of images.
//
// Settings come from OUTFIELD_CONFIG, a JSON file (the Home Manager module
// writes one), or else from single environment variables:
//
//   JSON key   variable            meaning
//   wallpaper  OUTFIELD_WALLPAPER  image or folder for every monitor ("~/" = home)
//   outputs    -                   per-monitor overrides: {"DP-1": "~/Pictures/wide"}
//   interval   OUTFIELD_INTERVAL   minutes between images from a folder (default 30, 0 = never)
//   shuffle    OUTFIELD_SHUFFLE    false for file-name order (default random)
//   fill       OUTFIELD_FILL       fill (default), fit, stretch, center or tile
//
// IPC: birdland-outfield ipc call outfield <next | set PATH | setOutput NAME PATH | reload | current>
ShellRoot {
    id: root

    JsonSettings {
        id: settings

        variable: "OUTFIELD_CONFIG"
    }

    readonly property var config: settings.values

    readonly property string wallpaper: Env.expandHome(String(config.wallpaper ?? Env.get("OUTFIELD_WALLPAPER")))
    readonly property var outputs: config.outputs ?? {}
    readonly property int interval: config.interval ?? Number(Env.get("OUTFIELD_INTERVAL", "30"))
    readonly property bool shuffle: config.shuffle ?? Env.get("OUTFIELD_SHUFFLE").toLowerCase() !== "false"
    readonly property string fill: String(config.fill ?? Env.get("OUTFIELD_FILL", "fill")).toLowerCase()

    // The wallpaper windows, one per monitor, as a plain array.
    function windows() {
        return Array.from(screens.instances);
    }

    // The configured image or folder for a monitor.
    function sourceFor(output) {
        return outputs[output] !== undefined ? Env.expandHome(String(outputs[output])) : wallpaper;
    }

    Variants {
        id: screens

        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property alias wallpaper: wallpaperItem

            screen: modelData
            color: Theme.background
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "birdland-outfield"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Wallpaper {
                id: wallpaperItem

                anchors.fill: parent
                source: root.sourceFor(window.modelData.name)
                interval: root.interval
                shuffle: root.shuffle
                fill: root.fill
            }
        }
    }

    IpcHandler {
        target: "outfield"

        // Next image on every monitor (folders only).
        function next(): void {
            for (const window of root.windows())
                window.wallpaper.next();
        }

        // Show an image or folder on every monitor until `reload`.
        function set(path: string): void {
            for (const window of root.windows())
                window.wallpaper.source = Env.expandHome(path);
        }

        // Show an image or folder on one monitor (e.g. "DP-1") until `reload`.
        function setOutput(output: string, path: string): void {
            const window = root.windows().find(w => w.modelData.name === output);
            if (window)
                window.wallpaper.source = Env.expandHome(path);
            else
                console.warn("outfield: no monitor named", output);
        }

        // Go back to the configured wallpapers.
        function reload(): void {
            for (const window of root.windows()) {
                const w = window;
                w.wallpaper.source = Qt.binding(() => root.sourceFor(w.modelData.name));
            }
        }

        // What each monitor shows, one "NAME: PATH" per line.
        function current(): string {
            return root.windows().map(w => w.modelData.name + ": " + (w.wallpaper.current || "(none)")).join("\n");
        }
    }
}
