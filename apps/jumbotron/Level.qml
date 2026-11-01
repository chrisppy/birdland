// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// The pop-up itself: an icon and a bar filled to `value` (0-1, or above 1
// for boosted volume), with the percentage. A negative value shows the icon
// alone.
Rectangle {
    id: root

    property bool vertical: false
    property string icon: ""
    property real value: 0
    property bool muted: false

    readonly property int length: 200
    readonly property bool hasLevel: value >= 0

    implicitWidth: vertical ? 56 : content.implicitWidth + Theme.spacingLarge * 2
    implicitHeight: vertical ? content.implicitHeight + Theme.spacingLarge * 2 : 56
    radius: Theme.radiusXLarge
    color: Theme.background
    border {
        width: 1
        color: Theme.border
    }

    Grid {
        id: content

        anchors.centerIn: parent
        columns: root.vertical ? 1 : 3
        spacing: Theme.spacingMedium + Theme.spacingSmall
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Text {
            text: root.icon
            color: root.muted ? Theme.textMuted : Theme.textBright
            font {
                family: Fonts.icons
                pixelSize: Fonts.sizeHeader + 6
            }
        }

        Rectangle {
            visible: root.hasLevel
            width: root.vertical ? 6 : root.length
            height: root.vertical ? root.length : 6
            radius: 3
            color: Theme.surface

            Rectangle {
                readonly property real fraction: Math.max(0, Math.min(1, root.value))

                anchors {
                    left: parent.left
                    bottom: parent.bottom
                }
                width: root.vertical ? parent.width : parent.width * fraction
                height: root.vertical ? parent.height * fraction : parent.height
                radius: 3
                color: root.muted ? Theme.textMuted : Theme.accent
            }
        }

        Text {
            id: percent

            visible: root.hasLevel
            text: Math.round(root.value * 100) + "%"
            color: root.muted ? Theme.textMuted : Theme.textBright
            horizontalAlignment: Text.AlignHCenter
            // Room for "100%", so the pop-up doesn't change size.
            width: Math.max(implicitWidth, metrics.width)
            font {
                family: Fonts.family
                pixelSize: Fonts.size + 1
            }

            TextMetrics {
                id: metrics

                font: percent.font
                text: "100%"
            }
        }
    }
}
