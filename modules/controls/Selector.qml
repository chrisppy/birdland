// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// Picks one of `items` (strings) with arrows on either side; it wraps around.
// The arrows hide when there is only one item.
Row {
    id: root

    property var items: []
    property int currentIndex: 0
    property int pixelSize: Fonts.size
    property color color: Theme.text

    signal moved(int index)

    function step(delta) {
        if (items.length < 2)
            return;
        currentIndex = (currentIndex + delta + items.length) % items.length;
        moved(currentIndex);
    }

    spacing: Theme.spacingSmall

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.items.length > 1
        icon: "\u{F0141}" // chevron_left
        size: root.pixelSize * 2
        onClicked: root.step(-1)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.items[root.currentIndex] ?? ""
        color: root.color
        font {
            family: Fonts.family
            pixelSize: root.pixelSize
        }
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.items.length > 1
        icon: "\u{F0142}" // chevron_right
        size: root.pixelSize * 2
        onClicked: root.step(1)
    }
}
