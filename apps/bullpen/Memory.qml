// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

Indicator {
    required property SystemStats stats

    available: stats.memoryUsage >= 0
    icon: "\u{F035B}" // memory
    label: percent(stats.memoryUsage)
    color: stats.memoryUsage >= 0.9 ? Theme.accent : Theme.textBright
}
