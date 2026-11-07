// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Io
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

    // systemd-networkd: [{ name, type, state }] from `networkctl list`, and the
    // Wi-Fi link quality (0-1) from /proc/net/wireless, -1 when unknown.
    property var links: []
    property bool networkdFound: false
    property real wifiQuality: -1

    function linkUp(link) {
        return link.state === "routable" || link.state === "degraded";
    }
    readonly property var ndWired: links.find(l => l.type === "ether" && linkUp(l)) ?? null
    readonly property var ndWifi: links.find(l => l.type === "wlan" && linkUp(l)) ?? links.find(l => l.type === "wlan") ?? null
    readonly property bool ndWifiUp: ndWifi !== null && linkUp(ndWifi)

    function parseLinks(text) {
        try {
            const data = JSON.parse(text);
            const list = Array.isArray(data) ? data : (data.Interfaces ?? []);
            root.links = list.filter(l => l.Type !== "loopback").map(l => ({
                        name: l.Name,
                        type: l.Type,
                        state: l.OperationalState
                    }));
            root.networkdFound = true;
        } catch (e) {
            root.links = [];
            root.networkdFound = false;
        }
    }

    // /proc/net/wireless: two header lines, then
    // " wlan0: 0000   54.  -56.  -256 ..." where the third field is the link
    // quality out of 70.
    function parseWireless(text) {
        const name = root.ndWifi?.name;
        const line = text.split("\n").slice(2).find(l => name && l.trim().startsWith(name + ":"));
        const quality = line ? parseFloat(line.trim().split(/\s+/)[2]) : NaN;
        root.wifiQuality = isNaN(quality) ? -1 : Math.max(0, Math.min(1, quality / 70));
    }

    readonly property bool wired: nm ? nmWired !== null : ndWired !== null
    readonly property bool hasWifi: nm ? nmWifi !== null : ndWifi !== null
    readonly property bool wifiConnected: nm ? nmWifiNetwork !== null : ndWifiUp
    readonly property real signal: nm ? (nmWifiNetwork?.signalStrength ?? 0) : Math.max(0, wifiQuality)
    readonly property bool wifiEnabled: nm ? Networking.wifiEnabled : true
    readonly property bool connected: wired || wifiConnected
    // networkd has no portal check; "degraded" (an address but no route) is the
    // nearest thing to limited.
    readonly property bool restricted: nm ? (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal) : connected && !links.some(l => l.state === "routable")

    available: nm || (networkdFound && links.length > 0)
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

    Process {
        id: networkctl

        running: !root.nm
        command: ["networkctl", "--json=short", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseLinks(text)
        }
        onExited: code => {
            if (code !== 0) {
                root.links = [];
                root.networkdFound = false;
            }
        }
    }

    FileView {
        id: wireless

        path: !root.nm && root.ndWifiUp ? "/proc/net/wireless" : ""
        printErrors: false
        onLoaded: root.parseWireless(text())
    }

    Timer {
        interval: 5000
        running: !root.nm
        repeat: true
        onTriggered: {
            networkctl.running = true;
            if (wireless.path !== "")
                wireless.reload();
        }
    }
}
