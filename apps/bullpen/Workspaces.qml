// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme
import modules.util

Rectangle {
    id: root

    // Screen edge the bar sits on. The pill runs vertically on left/right
    // bars.
    property string edge: "top"
    readonly property bool vertical: ScreenEdges.vertical(edge)
    // The monitor (Niri output name) whose workspaces to show; "" shows all.
    property string output: ""
    // Draws its own pill, so the bar puts no island around it when alone.
    readonly property bool pill: true

    // Shows up to maxDots dots; the pill fits the dots shown.
    readonly property int maxDots: 11
    readonly property int dotSize: 15
    // Thickness of the pill: the bar's island thickness, so it matches the
    // other islands.
    property int thickness: 24
    // The end dots sit as far from the pill's ends as from its sides, so they
    // follow its rounded ends.
    readonly property real inset: (thickness - dotSize) / 2
    readonly property int length: Math.ceil((vertical ? dots.implicitHeight : dots.implicitWidth) + 2 * inset)

    color: Theme.backgroundAlt
    border.color: Theme.surfaceAlt
    border.width: 1
    radius: thickness / 2
    implicitWidth: vertical ? thickness : length
    implicitHeight: vertical ? length : thickness

    Flow {
        id: dots

        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: Theme.spacingSmall

        anchors {
            left: root.vertical ? undefined : parent.left
            leftMargin: root.inset
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            top: root.vertical ? parent.top : undefined
            topMargin: root.inset
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
