// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

Rectangle {
    id: root

    // Screen edge the bar sits on. The pill is rounded on the side facing
    // the screen, and runs vertically on left/right bars.
    property string edge: "top"
    readonly property bool vertical: edge === "left" || edge === "right"

    // The pill always has room for maxDots workspace dots.
    readonly property int maxDots: 11
    readonly property int dotSize: 15
    readonly property int thickness: 25
    readonly property int length: maxDots * dotSize + (maxDots - 1) * Theme.spacingSmall + 2 * Theme.spacingMedium

    color: Theme.surfaceAlt
    implicitWidth: vertical ? thickness : length
    implicitHeight: vertical ? length : thickness

    topLeftRadius: edge === "bottom" || edge === "right" ? Theme.radiusMedium : 0
    topRightRadius: edge === "bottom" || edge === "left" ? Theme.radiusMedium : 0
    bottomLeftRadius: edge === "top" || edge === "right" ? Theme.radiusMedium : 0
    bottomRightRadius: edge === "top" || edge === "left" ? Theme.radiusMedium : 0

    Flow {
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: Theme.spacingSmall

        anchors {
            left: root.vertical ? undefined : parent.left
            leftMargin: Theme.spacingMedium
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            top: root.vertical ? parent.top : undefined
            topMargin: Theme.spacingMedium
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        }

        Repeater {
            model: niri.workspaces

            Rectangle {
                required property int index
                required property var modelData

                visible: index < root.maxDots
                width: root.dotSize
                height: root.dotSize

                radius: width / 2
                color: modelData.isActive ? Theme.activeWorkspace : Theme.inactiveWorkspace

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: niri.focusWorkspaceById(modelData.id)
                }
            }
        }
    }
}
