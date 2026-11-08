// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Niri
import modules.theme
import modules.util

// Announcer: notification popups. It is the session's notification server
// (org.freedesktop.Notifications), so stop other notification daemons such as
// mako or dunst. Popups show in a corner of the focused monitor, newest first,
// and close after a timeout; critical ones stay until dismissed.
//
//   variable            meaning
//   ANNOUNCER_POSITION top-right (default), top-left, bottom-right or bottom-left
//   ANNOUNCER_TIMEOUT  seconds a popup stays when the app doesn't say (default 5)
//
// IPC: birdland-announcer ipc call announcer <toggleDnd | setDnd BOOL | isDnd | dismissAll>
// Do not disturb drops all but critical notifications.
ShellRoot {
    id: root

    readonly property string position: ["top-right", "top-left", "bottom-right", "bottom-left"].includes(Env.get("ANNOUNCER_POSITION")) ? Env.get("ANNOUNCER_POSITION") : "top-right"
    readonly property bool atTop: position.startsWith("top")
    readonly property bool atLeft: position.endsWith("left")
    readonly property int timeout: Math.max(1, Number(Env.get("ANNOUNCER_TIMEOUT", "5")) || 5) * 1000
    readonly property int maxPopups: 5

    property bool dnd: false
    // The monitor popups show on, chosen when the first of them arrives.
    property var screen: null

    // Newest first; older ones wait until there is room.
    readonly property var popups: server.trackedNotifications.values.slice().reverse().slice(0, maxPopups)

    Niri {
        id: niri

        Component.onCompleted: connect()
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        imageSupported: true
        // Popups only; there is no history to keep notifications in.
        persistenceSupported: false

        onNotification: notification => {
            if (root.dnd && notification.urgency !== NotificationUrgency.Critical)
                return; // untracked, so dropped
            if (trackedNotifications.values.length === 0)
                root.screen = Screens.focused(niri);
            notification.tracked = true;
        }
    }

    LazyLoader {
        active: root.popups.length > 0

        PanelWindow {
            screen: root.screen
            color: "transparent"
            implicitWidth: 380
            implicitHeight: cards.implicitHeight

            anchors {
                top: root.atTop
                bottom: !root.atTop
                left: root.atLeft
                right: !root.atLeft
            }
            margins {
                top: Theme.spacingMedium
                bottom: Theme.spacingMedium
                left: Theme.spacingMedium
                right: Theme.spacingMedium
            }
            // Below bars rather than over them.
            exclusionMode: ExclusionMode.Normal

            WlrLayershell.namespace: "birdland-announcer"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Column {
                id: cards

                width: parent.width
                spacing: Theme.spacingMedium

                Repeater {
                    model: ScriptModel {
                        values: root.atTop ? root.popups : root.popups.slice().reverse()
                    }

                    NotificationCard {
                        required property var modelData

                        width: cards.width
                        notification: modelData
                        defaultTimeout: root.timeout
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "announcer"

        // Do not disturb on or off; returns the new state.
        function toggleDnd(): bool {
            root.dnd = !root.dnd;
            return root.dnd;
        }

        function setDnd(on: bool): void {
            root.dnd = on;
        }

        function isDnd(): bool {
            return root.dnd;
        }

        function dismissAll(): void {
            for (const notification of server.trackedNotifications.values.slice())
                notification.dismiss();
        }
    }
}
