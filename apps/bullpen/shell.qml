// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
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
        }
    }

    // One sampler for all bars; it runs only while a bar shows a statistic.
    SystemStats {
        id: sharedStats

        readonly property var barList: Array.from(bars.instances)

        running: barList.some(bar => bar.usesStats)
        sampleGpu: barList.some(bar => bar.usesGpu)
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
}
