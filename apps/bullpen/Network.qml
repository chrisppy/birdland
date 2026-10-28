// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Networking
import modules.theme

// Network status from NetworkManager: wired when connected, otherwise the
// Wi-Fi signal strength. Dimmed while disconnected, accent-colored when the
// connection is limited or behind a captive portal.
Indicator {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool connected: wired !== null || wifiNetwork !== null
    readonly property bool restricted: Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal

    available: Networking.backend !== NetworkBackendType.None
    color: !connected ? Theme.textMuted : restricted ? Theme.accent : Theme.textBright
    icon: {
        if (wired)
            return "\u{F0200}"; // ethernet
        if (wifiNetwork) {
            const bars = ["\u{F091F}", "\u{F0922}", "\u{F0925}", "\u{F0928}"]; // wifi_strength_1..4
            return bars[Math.min(3, Math.floor(wifiNetwork.signalStrength * 4))];
        }
        if (wifi)
            return Networking.wifiEnabled ? "\u{F092E}" : "\u{F05AA}"; // wifi_strength_off_outline / wifi_off
        return "\u{F0C9B}"; // network_off
    }
}
