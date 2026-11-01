// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import modules.theme

// System tray (StatusNotifierItem) icons. Passive items, which apps mark as
// idle, are hidden. Left click activates an item (or opens its menu, for
// menu-only items), middle click is its secondary action, right click opens
// its menu, and scrolling scrolls it.
Item {
    id: root

    // The bar window, which menus open from.
    required property var window
    property string edge: "top"
    readonly property bool vertical: edge === "left" || edge === "right"

    readonly property var items: SystemTray.items.values.filter(item => item.status !== Status.Passive)
    readonly property bool available: items.length > 0

    implicitWidth: icons.implicitWidth
    implicitHeight: icons.implicitHeight

    Grid {
        id: icons

        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, root.items.length)
        spacing: Theme.spacingMedium

        Repeater {
            model: root.items

            Item {
                id: slot

                required property var modelData

                // Opens the menu at the icon, just off the bar on the side
                // away from the screen edge.
                function openMenu() {
                    const point = mapToItem(null, 0, 0);
                    const x = root.edge === "left" ? root.window.width : root.edge === "right" ? 0 : point.x;
                    const y = root.edge === "top" ? root.window.height : root.edge === "bottom" ? 0 : point.y;
                    modelData.display(root.window, Math.round(x), Math.round(y));
                }

                width: 18
                height: 18

                IconImage {
                    anchors.fill: parent
                    asynchronous: true
                    source: slot.modelData.icon
                }

                // Draws attention to items that ask for it.
                Rectangle {
                    visible: slot.modelData.status === Status.NeedsAttention
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.primary
                    anchors {
                        right: parent.right
                        top: parent.top
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: mouse => {
                        const item = slot.modelData;
                        if (mouse.button === Qt.MiddleButton)
                            item.secondaryActivate();
                        else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                            if (item.hasMenu)
                                slot.openMenu();
                        } else
                            item.activate();
                    }
                    onWheel: wheel => {
                        const horizontal = wheel.angleDelta.x !== 0 && wheel.angleDelta.y === 0;
                        slot.modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
                    }
                }
            }
        }
    }
}
