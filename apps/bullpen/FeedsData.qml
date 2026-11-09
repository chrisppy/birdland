// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import modules.util

// Unread counts from a pressbox feed server (github.com/chrisppy/pressbox),
// shared by every bar's feeds indicator. The server and token come from the
// reader's own files: ~/.config/pressbox/client.json (written by pressbox's
// Home Manager module) and the token `pressbox pair` saves. Polls every
// `interval` seconds while `running`, and on refresh().
Scope {
    id: root

    property bool running: true
    property int interval: 120
    property bool notifications: true
    // A shell command; clicking the indicator runs it.
    property string openCommand: "xdg-terminal-exec pressbox"

    readonly property string configPath: (Env.get("XDG_CONFIG_HOME") || Env.get("HOME") + "/.config") + "/pressbox/client.json"
    readonly property string defaultTokenFile: (Env.get("XDG_STATE_HOME") || Env.get("HOME") + "/.local/state") + "/pressbox/token"
    property string server: Env.get("PRESSBOX_SERVER", "http://127.0.0.1:8470")
    property string tokenFile: Env.get("PRESSBOX_TOKEN_FILE", defaultTokenFile)
    property string token: ""
    property bool configLoaded: false
    property bool tokenLoaded: false

    // "loading", "ok", "unpaired", "offline", "unauthorized" or "error".
    property string status: "loading"
    property string lastError: ""
    property int unread: 0
    // Feed id -> unread count at the last poll; null before the first.
    property var known: null

    // For tests: function (method, url, headers, done(status, text)).
    property var transport: null

    function request(method, path, done) {
        const url = root.server.replace(/\/+$/, "") + path;
        const headers = {
            "Authorization": "Bearer " + root.token
        };
        const finish = (status, text) => {
            if (status >= 200 && status < 300) {
                root.lastError = "";
                try {
                    if (done)
                        done(text ? JSON.parse(text) : null);
                } catch (e) {
                    root.status = "error";
                    root.lastError = "unexpected answer: " + e;
                }
            } else if (status === 0) {
                root.status = "offline";
                root.lastError = "cannot reach " + root.server;
            } else if (status === 401) {
                root.status = "unauthorized";
                root.lastError = "the server rejected the token; run pressbox pair";
            } else {
                root.status = "error";
                root.lastError = "server returned " + status;
            }
            if (root.status !== "ok")
                console.warn("bullpen: feeds:", root.lastError);
        };
        if (root.transport) {
            root.transport(method, url, headers, finish);
            return;
        }
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE)
                finish(xhr.status, xhr.responseText);
        };
        xhr.open(method, url);
        for (const name in headers)
            xhr.setRequestHeader(name, headers[name]);
        xhr.send();
    }

    // Fetches the unread counts now.
    function poll() {
        if (!root.running || !root.configLoaded || !root.tokenLoaded)
            return;
        if (root.token === "") {
            root.status = "unpaired";
            return;
        }
        request("GET", "/api/v1/feeds", feeds => {
            root.status = "ok";
            root.unread = feeds.reduce((sum, f) => sum + (f.archived ? 0 : f.unread), 0);
            root.notifyNew(feeds);
        });
    }

    // Asks the server to fetch every feed, then polls again.
    function refresh() {
        if (root.token === "")
            return;
        request("POST", "/api/v1/refresh", () => refreshed.restart());
    }

    // Opens the reader.
    function open() {
        opener.command = ["sh", "-c", root.openCommand];
        opener.startDetached();
    }

    function notifyNew(feeds) {
        const counts = {};
        const grew = [];
        let added = 0;
        for (const f of feeds) {
            counts[f.id] = f.unread;
            const before = root.known ? (root.known[f.id] || 0) : f.unread;
            if (f.unread > before) {
                grew.push(f.title + " +" + (f.unread - before));
                added += f.unread - before;
            }
        }
        root.known = counts;
        if (added > 0 && root.notifications) {
            notify.command = ["notify-send", "--app-name=pressbox", "--icon=application-rss+xml", added === 1 ? "1 new item" : added + " new items", grew.join("\n")];
            notify.running = true;
        }
    }

    onRunningChanged: poll()

    Timer {
        interval: root.interval * 1000
        running: root.running && root.configLoaded
        repeat: true
        // Unpaired: the token file may not have existed when it was first
        // read, and a missing file can't be watched, so look for it again.
        // Its onLoaded polls, so pairing while the bar runs shows up here.
        onTriggered: root.token === "" ? tokenView.reload() : root.poll()
    }

    // The server needs a moment to fetch after a refresh.
    Timer {
        id: refreshed

        interval: 5000
        onTriggered: root.poll()
    }

    Process {
        id: notify
    }

    Process {
        id: opener
    }

    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const config = JSON.parse(text());
                if (config.server && !Env.get("PRESSBOX_SERVER"))
                    root.server = config.server;
                if (config.tokenFile && !Env.get("PRESSBOX_TOKEN_FILE"))
                    root.tokenFile = config.tokenFile;
            } catch (e) {
                console.warn("bullpen: feeds: invalid", root.configPath + ":", e);
            }
            root.configLoaded = true;
            root.poll();
        }
        // No config file: the defaults and environment.
        onLoadFailed: {
            root.configLoaded = true;
            root.poll();
        }
    }

    FileView {
        id: tokenView

        path: root.tokenFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.token = text().trim();
            root.tokenLoaded = true;
            root.poll();
        }
        onLoadFailed: {
            root.token = "";
            root.tokenLoaded = true;
            root.poll();
        }
    }
}
