// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import modules.theme

// One part of the bar (left, center or right): its modules in order, in a row
// on top/bottom bars and a column on side bars. Each module gets the full bar
// thickness and is centered in it, except modules with `hugsEdge` (the
// workspaces pill), which sit flush against the screen edge.
GridLayout {
    id: root

    // The Bar that owns this part: edge, vertical, width and `modules`
    // (module name -> Component).
    required property var owner
    // Module names, in order.
    required property var names
    // In the center section the title may use the free space; elsewhere it is
    // capped at a quarter of the bar.
    property bool center: false

    flow: owner.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
    columnSpacing: Theme.spacingLarge
    rowSpacing: Theme.spacingMedium + Theme.spacingSmall

    Repeater {
        model: root.names

        Item {
            id: slot

            required property string modelData

            readonly property var item: loader.item
            // The window title (anything with `maxWidth`) shrinks to fit,
            // eliding its text.
            readonly property bool stretches: item !== null && item.maxWidth !== undefined
            readonly property bool hugsEdge: item?.hugsEdge ?? false
            // Sizes come from the module's natural size, rounded up so the
            // layout's whole-pixel sizes never cut it short.
            readonly property real naturalWidth: Math.ceil(item?.implicitWidth ?? 0)
            readonly property real naturalHeight: Math.ceil(item?.implicitHeight ?? 0)

            objectName: "module-" + modelData
            // Modules without an `available` property are always shown.
            visible: item ? (item.available ?? true) : false

            Layout.fillHeight: !root.owner.vertical
            Layout.fillWidth: root.owner.vertical || stretches
            Layout.preferredWidth: root.owner.vertical ? -1 : naturalWidth
            Layout.preferredHeight: root.owner.vertical ? naturalHeight : -1
            Layout.maximumWidth: !stretches || root.owner.vertical ? Number.POSITIVE_INFINITY : root.center ? naturalWidth : root.owner.width / 4

            // Positioned, never sized: a Loader that sizes its item can shrink
            // it to nothing. Along the bar it starts at the slot's start;
            // across it, it is flush against the screen edge or centered.
            Loader {
                id: loader

                sourceComponent: root.owner.modules[slot.modelData] ?? null

                x: !root.owner.vertical ? 0 : !slot.hugsEdge ? (slot.width - width) / 2 : root.owner.edge === "left" ? 0 : slot.width - width
                y: root.owner.vertical ? 0 : !slot.hugsEdge ? (slot.height - height) / 2 : root.owner.edge === "top" ? 0 : slot.height - height

                Component.onCompleted: {
                    if (!root.owner.modules[slot.modelData])
                        console.warn("bullpen: unknown module:", slot.modelData);
                }
            }

            Binding {
                target: loader.item
                property: "maxWidth"
                value: slot.width
                when: slot.stretches
            }
        }
    }
}
