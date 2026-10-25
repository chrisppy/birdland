// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import modules.theme

Rectangle {
    id: root

    required property var app
    required property bool selected

    signal clicked
    signal hovered

    height: 46
    radius: Theme.radiusMedium
    color: selected ? Theme.surfaceAlt : "transparent"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: root.hovered()
        onClicked: root.clicked()
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Theme.spacingMedium + 2
            rightMargin: Theme.spacingMedium + 2
        }
        spacing: Theme.spacingMedium + 4

        IconImage {
            // implicitSize must be set: IconImage loads at its own size, and a
            // size of 0 makes Qt render large SVGs at their natural size.
            implicitSize: 28
            asynchronous: true
            source: Quickshell.iconPath(root.app.icon, "application-x-executable")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.app.name
                color: root.selected ? Theme.accent : Theme.textBright
                elide: Text.ElideRight
                font {
                    family: Fonts.family
                    pixelSize: Fonts.size + 2
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.app.comment || root.app.genericName || ""
                color: Theme.textMuted
                elide: Text.ElideRight
                font {
                    family: Fonts.family
                    pixelSize: Fonts.size - 2
                }
            }
        }
    }
}
