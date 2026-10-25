// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import modules.theme

Item {
    id: root

    required property var entry
    // Decides if a window's app ID belongs to an entry: (entry, appId) => bool.
    required property var matcher
    property string edge: "bottom"
    readonly property bool vertical: edge === "left" || edge === "right"

    // Open windows that belong to this app.
    readonly property var windows: ToplevelManager.toplevels.values.filter(t => matcher(entry, t.appId))
    readonly property bool running: windows.length > 0
    readonly property bool focused: windows.some(t => t.activated)

    // Launch the app if it isn't running, otherwise focus its next window.
    function activate() {
        if (!running) {
            entry.execute();
            return;
        }
        const current = windows.findIndex(t => t.activated);
        windows[(current + 1) % windows.length].activate();
    }

    implicitWidth: 44
    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: mouse.containsMouse ? Theme.surface : "transparent"
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 32
        asynchronous: true
        source: Quickshell.iconPath(root.entry.icon, "application-x-executable")
    }

    // Running indicator on the side facing the screen edge; wider when focused.
    Rectangle {
        visible: root.running
        width: root.vertical ? 3 : (root.focused ? 14 : 4)
        height: root.vertical ? (root.focused ? 14 : 4) : 3
        radius: 2
        color: root.focused ? Theme.accent : Theme.textMuted

        anchors {
            top: root.edge === "top" ? parent.top : undefined
            bottom: root.edge === "bottom" ? parent.bottom : undefined
            left: root.edge === "left" ? parent.left : undefined
            right: root.edge === "right" ? parent.right : undefined
            horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
            verticalCenter: root.vertical ? parent.verticalCenter : undefined
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // Left click launches or focuses; middle click always opens a new instance.
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                root.entry.execute();
            else
                root.activate();
        }
    }
}
