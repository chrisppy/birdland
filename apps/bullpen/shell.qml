// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Niri

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
        }
    }

    // One sampler for all bars; it runs only while a bar shows a statistic.
    SystemStats {
        id: sharedStats

        readonly property var barList: Array.from(bars.instances)

        running: barList.some(bar => bar.usesStats)
        sampleGpu: barList.some(bar => bar.usesGpu)
    }
}
