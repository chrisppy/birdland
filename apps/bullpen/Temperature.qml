// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// CPU temperature.
Indicator {
    required property SystemStats stats

    available: !isNaN(stats.cpuTemp)
    icon: "\u{F050F}" // thermometer
    label: degrees(stats.cpuTemp)
    color: stats.cpuTemp >= 90 ? Theme.primary : stats.cpuTemp >= 80 ? Theme.accent : Theme.textBright
}
