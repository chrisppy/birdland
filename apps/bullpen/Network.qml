// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Networking
import modules.theme

// Network status: wired when connected, otherwise the Wi-Fi signal strength.
// Dimmed while disconnected, accent-colored when the connection is limited or
// behind a captive portal. Read from NetworkManager when it is running, else
// from systemd-networkd (`networkctl` and /proc/net/wireless).
Indicator {
    id: root

    readonly property bool nm: Networking.backend !== NetworkBackendType.None

    // NetworkManager.
    readonly property var devices: nm ? Networking.devices.values : []
    readonly property var nmWired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var nmWifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var nmWifiNetwork: nmWifi?.networks.values.find(n => n.connected) ?? null

    // systemd-networkd, polled once for all bars (see shell.qml).
    required property NetworkData networkd

    readonly property bool wired: nm ? nmWired !== null : networkd.wired !== null
    readonly property bool hasWifi: nm ? nmWifi !== null : networkd.wifi !== null
    readonly property bool wifiConnected: nm ? nmWifiNetwork !== null : networkd.wifiUp
    readonly property real signal: nm ? (nmWifiNetwork?.signalStrength ?? 0) : Math.max(0, networkd.wifiQuality)
    readonly property bool wifiEnabled: nm ? Networking.wifiEnabled : true
    readonly property bool connected: wired || wifiConnected
    // networkd has no portal check; "degraded" (an address but no route) is the
    // nearest thing to limited.
    readonly property bool restricted: nm ? (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal) : connected && !networkd.routable

    available: nm || (networkd.found && networkd.links.length > 0)
    color: !connected ? Theme.textMuted : restricted ? Theme.accent : Theme.textBright
    icon: {
        if (wired)
            return "\u{F0200}"; // ethernet
        if (wifiConnected) {
            const bars = ["\u{F091F}", "\u{F0922}", "\u{F0925}", "\u{F0928}"]; // wifi_strength_1..4
            return bars[Math.min(3, Math.floor(signal * 4))];
        }
        if (hasWifi)
            return wifiEnabled ? "\u{F092E}" : "\u{F05AA}"; // wifi_strength_off_outline / wifi_off
        return "\u{F0C9B}"; // network_off
    }

}
