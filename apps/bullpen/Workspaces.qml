// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme
import modules.util

Rectangle {
    id: root

    // Screen edge the bar sits on. The pill is rounded on the side facing
    // the screen, and runs vertically on left/right bars.
    property string edge: "top"
    readonly property bool vertical: ScreenEdges.vertical(edge)
    // The monitor (Niri output name) whose workspaces to show; "" shows all.
    property string output: ""
    // Sits flush against the screen edge, wherever it is in the bar.
    readonly property bool hugsEdge: true

    // Shows up to maxDots dots; the pill fits the dots shown.
    readonly property int maxDots: 11
    readonly property int dotSize: 15
    readonly property int thickness: 25
    readonly property int length: (vertical ? dots.implicitHeight : dots.implicitWidth) + 2 * Theme.spacingMedium

    color: Theme.surfaceAlt
    implicitWidth: vertical ? thickness : length
    implicitHeight: vertical ? length : thickness

    topLeftRadius: ScreenEdges.corner(edge, "topLeft", Theme.radiusMedium)
    topRightRadius: ScreenEdges.corner(edge, "topRight", Theme.radiusMedium)
    bottomLeftRadius: ScreenEdges.corner(edge, "bottomLeft", Theme.radiusMedium)
    bottomRightRadius: ScreenEdges.corner(edge, "bottomRight", Theme.radiusMedium)

    Flow {
        id: dots

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

                // Only this monitor's workspaces, up to maxDots of them; Niri
                // numbers each monitor's workspaces from 1.
                visible: (root.output === "" || modelData.output === root.output) && modelData.index <= root.maxDots
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
