// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io

// systemd-networkd's view of the network, polled every 5 s while `running`:
// the links from `networkctl list`, and the Wi-Fi link quality from
// /proc/net/wireless. One for all bars (see shell.qml); the Network indicator
// uses it when NetworkManager isn't running, which needs no polling.
Scope {
    id: root

    property bool running: false

    // [{ name, type, state }], without loopback.
    property var links: []
    property bool found: false
    // 0-1, -1 when unknown.
    property real wifiQuality: -1

    function linkUp(link) {
        return link.state === "routable" || link.state === "degraded";
    }
    readonly property var wired: links.find(l => l.type === "ether" && linkUp(l)) ?? null
    readonly property var wifi: links.find(l => l.type === "wlan" && linkUp(l)) ?? links.find(l => l.type === "wlan") ?? null
    readonly property bool wifiUp: wifi !== null && linkUp(wifi)
    readonly property bool routable: links.some(l => l.state === "routable")

    function parseLinks(text) {
        try {
            const data = JSON.parse(text);
            const list = Array.isArray(data) ? data : (data.Interfaces ?? []);
            links = list.filter(l => l.Type !== "loopback").map(l => ({
                        name: l.Name,
                        type: l.Type,
                        state: l.OperationalState
                    }));
            found = true;
        } catch (e) {
            links = [];
            found = false;
        }
    }

    // /proc/net/wireless: two header lines, then
    // " wlan0: 0000   54.  -56.  -256 ..." where the third field is the link
    // quality out of 70.
    function parseWireless(text) {
        const name = wifi?.name;
        const line = text.split("\n").slice(2).find(l => name && l.trim().startsWith(name + ":"));
        const quality = line ? parseFloat(line.trim().split(/\s+/)[2]) : NaN;
        wifiQuality = isNaN(quality) ? -1 : Math.max(0, Math.min(1, quality / 70));
    }

    Process {
        id: networkctl

        command: ["networkctl", "--json=short", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseLinks(text)
        }
        onExited: code => {
            if (code !== 0) {
                root.links = [];
                root.found = false;
            }
        }
    }

    FileView {
        id: wireless

        path: root.running && root.wifiUp ? "/proc/net/wireless" : ""
        printErrors: false
        onLoaded: root.parseWireless(text())
    }

    Timer {
        interval: 5000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            networkctl.running = true;
            if (wireless.path !== "")
                wireless.reload();
        }
    }
}
