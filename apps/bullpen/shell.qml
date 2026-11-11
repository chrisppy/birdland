// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Niri
import modules.util

ShellRoot {
    id: root

    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.info("Connected to niri")
        onErrorOccurred: function (error) {
            console.error("Niri error:", error);
        }
    }

    // One bar per monitor, following monitors being plugged in and out.
    Variants {
        id: bars

        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
            stats: sharedStats
            weather: sharedWeather
            feeds: sharedFeeds
            networkd: sharedNetworkd
            dnd: sharedDnd
            idle: sharedIdle
        }
    }

    // One sampler for all bars; it runs only while a bar shows a statistic.
    SystemStats {
        id: sharedStats

        readonly property var barList: Array.from(bars.instances)

        running: barList.some(bar => bar.usesStats)
        sampleGpu: barList.some(bar => bar.usesGpu)
        sampleCpuTemp: barList.some(bar => bar.usesTemperature)
    }

    // One weather fetch for all bars, while any of them shows the weather.
    // BULLPEN_WEATHER_LOCATION is "latitude,longitude"; without it the
    // weather stays hidden.
    WeatherData {
        id: sharedWeather

        location: Env.get("BULLPEN_WEATHER_LOCATION")
        imperial: Env.get("BULLPEN_UNITS").toLowerCase() === "imperial"
        running: sharedStats.barList.some(bar => bar.usesWeather)
    }

    // One pressbox poll for all bars, while any of them shows the feeds.
    FeedsData {
        id: sharedFeeds

        running: sharedStats.barList.some(bar => bar.usesFeeds)
        interval: Math.max(30, Number(Env.get("BULLPEN_FEEDS_INTERVAL", "120")) || 120)
        notifications: Env.get("BULLPEN_FEEDS_NOTIFICATIONS", "true") !== "false"
        openCommand: Env.get("BULLPEN_FEEDS_COMMAND", "xdg-terminal-exec pressbox")
    }

    // One networkctl poll for all bars, while any of them shows the network
    // and NetworkManager isn't running (it reports changes by itself).
    NetworkData {
        id: sharedNetworkd

        running: Networking.backend === NetworkBackendType.None && sharedStats.barList.some(bar => bar.usesNetwork)
    }

    // Announcer's do not disturb, read from (and set through) its state file.
    DoNotDisturb {
        id: sharedDnd
    }

    // Idle inhibition, for the idle-inhibitor indicator and IPC. Starts off
    // with each bullpen.
    IdleInhibit {
        id: sharedIdle
    }

    // birdland-bullpen ipc call bullpen <toggleIdleInhibitor | setIdleInhibitor BOOL | isIdleInhibited>
    // Works whether or not the idle-inhibitor indicator is in the layout.
    IpcHandler {
        target: "bullpen"

        // Idle inhibition on or off; returns the new state.
        function toggleIdleInhibitor(): bool {
            sharedIdle.toggle();
            return sharedIdle.inhibited;
        }

        function setIdleInhibitor(on: bool): void {
            sharedIdle.inhibited = on;
        }

        function isIdleInhibited(): bool {
            return sharedIdle.inhibited;
        }
    }
}
