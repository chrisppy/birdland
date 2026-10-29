// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// A round button showing a Symbols Nerd Font glyph, with an optional label
// underneath.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property int size: 44

    signal clicked

    implicitWidth: Math.max(size, labelText.implicitWidth)
    implicitHeight: size + (label === "" ? 0 : labelText.implicitHeight + Theme.spacingSmall)

    Rectangle {
        id: circle

        anchors.horizontalCenter: parent.horizontalCenter
        width: root.size
        height: root.size
        radius: width / 2
        color: mouse.pressed ? Theme.surfaceAlt : mouse.containsMouse ? Theme.surface : "transparent"

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: Theme.textBright
            font {
                family: Fonts.icons
                pixelSize: root.size / 2
            }
        }
    }

    Text {
        id: labelText

        anchors {
            top: circle.bottom
            topMargin: Theme.spacingSmall
            horizontalCenter: parent.horizontalCenter
        }
        visible: root.label !== ""
        text: root.label
        color: Theme.textMuted
        font {
            family: Fonts.family
            pixelSize: Fonts.size - 1
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
