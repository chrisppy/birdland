// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// GPU usage, plus the GPU temperature when there is a sensor for it.
Indicator {
    required property SystemStats stats

    readonly property bool hasTemp: !isNaN(stats.gpuTemp)

    available: stats.gpuUsage >= 0
    icon: "\u{F08AE}" // expansion_card
    label: percent(stats.gpuUsage) + (hasTemp ? (vertical ? "\n" : " ") + degrees(stats.gpuTemp) : "")
    color: stats.gpuUsage >= 0.9 || stats.gpuTemp >= 85 ? Theme.accent : Theme.textBright
}
