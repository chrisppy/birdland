// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."

Rectangle {
    id: root

    anchors.left: parent.left

    color: Theme.base03
    height: 25
    width: 215

    bottomLeftRadius: 10
    bottomRightRadius: 10

    Rectangle {
        id: workspaceLayout

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }

        color: "transparent"
        implicitHeight: workspaceRow.implicitHeight

        RowLayout {
            id: workspaceRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Repeater {
                model: niri.workspaces

                Rectangle {
                    required property int index
                    required property var modelData

                    visible: index < 11
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15

                    radius: 10
                    color: modelData.isActive ? Theme.base12 : Theme.base02

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
