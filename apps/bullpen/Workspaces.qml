// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import modules.theme

Rectangle {
    id: root

    anchors.left: parent.left

    color: Theme.surfaceAlt
    height: 25
    width: 215

    bottomLeftRadius: Theme.radiusMedium
    bottomRightRadius: Theme.radiusMedium

    Rectangle {
        id: workspaceLayout

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: Theme.spacingMedium
            rightMargin: Theme.spacingMedium
        }

        color: Theme.surfaceAlt
        implicitHeight: workspaceRow.implicitHeight

        RowLayout {
            id: workspaceRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingSmall

            Repeater {
                model: niri.workspaces

                Rectangle {
                    required property int index
                    required property var modelData

                    visible: index < 11
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15

                    radius: Theme.radiusLarge
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
}
