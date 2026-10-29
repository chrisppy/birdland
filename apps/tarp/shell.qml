// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import modules.theme

// Tarp: the lock screen. It runs in the background and locks every monitor
// with `birdland-tarp ipc call tarp lock`; the user's password, checked by
// PAM, unlocks it. There is deliberately no IPC call that unlocks.
//
// If tarp dies while locked, the compositor keeps the screens locked. A
// state file in $XDG_RUNTIME_DIR records that, so the next tarp (systemd
// restarts it) locks again at once and the password can unlock the session.
//
// Settings come from TARP_CONFIG, a JSON file (the Home Manager module writes
// one), or else from single environment variables:
//
//   JSON key    variable           meaning
//   pamService  TARP_PAM_SERVICE   PAM service in /etc/pam.d (default "login")
//   wallpaper   TARP_WALLPAPER     image or folder behind the lock ("~/" = home)
//   fill        -                  wallpaper fill: fill, fit, stretch, center, tile
ShellRoot {
    id: root

    function env(name) {
        const value = Quickshell.env(name);
        return value === null || value === undefined ? "" : String(value);
    }

    function expandHome(path) {
        return path.startsWith("~/") ? env("HOME") + path.slice(1) : path;
    }

    FileView {
        id: configFile

        path: root.env("TARP_CONFIG")
        blockLoading: true
    }

    readonly property var config: {
        if (configFile.path === "")
            return {};
        try {
            return JSON.parse(configFile.text());
        } catch (e) {
            console.warn("tarp: could not read", configFile.path, e);
            return {};
        }
    }

    readonly property string pamService: config.pamService ?? (env("TARP_PAM_SERVICE") || "login")
    readonly property string wallpaper: expandHome(String(config.wallpaper ?? env("TARP_WALLPAPER")))
    readonly property string fill: String(config.fill ?? "fill")
    readonly property string userName: env("USER")

    // Authentication state, shown on every monitor.
    property string prompt: "Password"
    property bool promptEchoes: false
    property string message: ""
    property bool messageIsError: false
    readonly property bool busy: pam.active && !pam.responseRequired
    // Typed before PAM asked for it; handed over at PAM's first question.
    property var pendingResponse: null

    signal failed

    function lock() {
        if (sessionLock.locked)
            return;
        reset();
        message = "";
        stateFile.setText("locked\n");
        sessionLock.locked = true;
    }

    function submit(text) {
        message = "";
        if (pam.active && pam.responseRequired) {
            pam.respond(text);
            return;
        }
        if (pam.active)
            return;
        pendingResponse = text;
        if (!pam.start()) {
            pendingResponse = null;
            showError("Could not start authentication (PAM service \"" + pamService + "\")");
        }
    }

    function reset() {
        pendingResponse = null;
        prompt = "Password";
        promptEchoes = false;
    }

    function showError(text) {
        reset();
        message = text;
        messageIsError = true;
        failed();
    }

    function unlock() {
        reset();
        message = "";
        sessionLock.locked = false;
        stateFile.setText("unlocked\n");
    }

    PamContext {
        id: pam

        config: root.pamService

        onPamMessage: {
            if (responseRequired) {
                if (root.pendingResponse !== null) {
                    const response = root.pendingResponse;
                    root.pendingResponse = null;
                    respond(response);
                } else {
                    // A further question, such as a one-time code.
                    root.prompt = message.replace(/:\s*$/, "");
                    root.promptEchoes = responseVisible;
                }
            } else if (message !== "") {
                root.message = message;
                root.messageIsError = messageIsError;
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success)
                root.unlock();
            else
                root.showError(result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password");
        }

        onError: error => root.showError("Authentication error: " + PamError.toString(error))
    }

    // "locked" while locked; see the comment at the top.
    FileView {
        id: stateFile

        path: root.env("XDG_RUNTIME_DIR") === "" ? "" : root.env("XDG_RUNTIME_DIR") + "/birdland-tarp.state"
        blockLoading: true
        blockWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        if (stateFile.path !== "" && stateFile.text().trim() === "locked") {
            console.warn("tarp: the previous lock screen exited while locked; locking again");
            lock();
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface

            color: Theme.background

            LockView {
                anchors.fill: parent
                lock: root
            }
        }
    }

    IpcHandler {
        target: "tarp"

        // Lock every monitor. Returns at once; see isSecure.
        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return sessionLock.locked;
        }

        // True once the compositor confirms every monitor is covered.
        function isSecure(): bool {
            return sessionLock.secure;
        }
    }
}
