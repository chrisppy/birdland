// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

Indicator {
    required property SystemStats stats

    available: stats.cpuUsage >= 0
    icon: "\u{F0EE0}" // cpu_64_bit
    label: percent(stats.cpuUsage)
    color: stats.cpuUsage >= 0.9 ? Theme.accent : Theme.textBright
}
