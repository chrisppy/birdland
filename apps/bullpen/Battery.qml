// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Services.UPower
import modules.theme

// Laptop battery from UPower. Hidden on machines without one.
Indicator {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge || device.state === UPowerDeviceState.FullyCharged

    available: device.ready && device.isLaptopBattery
    label: Math.round(level * 100) + "%"
    color: {
        if (charging)
            return Theme.textBright;
        if (level <= 0.1)
            return Theme.primary;
        return level <= 0.2 ? Theme.accent : Theme.textBright;
    }
    // One glyph per 10%: battery_outline/alert, battery_10..90, battery (full),
    // and the matching battery_charging_* glyphs.
    icon: {
        const step = Math.max(0, Math.min(10, Math.round(level * 10)));
        const discharging = ["\u{F0083}", "\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}", "\u{F007E}", "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}"];
        const charge = ["\u{F089F}", "\u{F089C}", "\u{F0086}", "\u{F0087}", "\u{F0088}", "\u{F089D}", "\u{F0089}", "\u{F089E}", "\u{F008A}", "\u{F008B}", "\u{F0085}"];
        return (charging ? charge : discharging)[step];
    }
}
