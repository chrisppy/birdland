// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import modules.theme

// One part of the bar (left, center or right): its islands in order, in a row
// on top/bottom bars and a column on side bars. An island is a floating pill
// holding one or more modules, a little way off the screen edge. A module
// with `pill` (the workspaces dots) draws its own, so alone it gets no island
// around it. An island whose modules all have nothing to show hides.
GridLayout {
    id: root

    // The Bar that owns this part: edge, vertical, width, islandGap,
    // islandThickness and `modules` (module name -> Component).
    required property var owner
    // Islands, in order: each a list of module names sharing one pill.
    required property var groups
    // In the center section the title may use the free space; elsewhere it is
    // capped at a quarter of the bar.
    property bool center: false

    // Room at an island's ends, and between the modules in it.
    readonly property int islandPadding: Theme.spacingMedium + 2
    readonly property int islandSpacing: Theme.spacingMedium + 2

    flow: owner.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
    columnSpacing: owner.islandGap
    rowSpacing: owner.islandGap

    Repeater {
        model: root.groups

        // Spans the bar's thickness; the pill inside sits off the screen edge.
        Item {
            id: island

            required property var modelData

            // Shown while any of its modules has something to show. Worked out
            // from the modules rather than the layout, which leaves hidden
            // items out and would keep a hidden island hidden.
            readonly property bool shown: {
                for (let i = 0; i < slots.count; i++) {
                    if (slots.itemAt(i)?.shown)
                        return true;
                }
                return false;
            }
            // A lone module that draws its own pill.
            readonly property bool bare: slots.count === 1 && (slots.itemAt(0)?.item?.pill ?? false)
            readonly property bool stretches: {
                for (let i = 0; i < slots.count; i++) {
                    if (slots.itemAt(i)?.stretches)
                        return true;
                }
                return false;
            }
            readonly property real padding: bare ? 0 : root.islandPadding
            // Length along the bar with every module at its natural size.
            readonly property real naturalLength: Math.ceil(root.owner.vertical ? modules.implicitHeight : modules.implicitWidth) + 2 * padding

            objectName: "island-" + modelData.join("+")
            visible: shown

            Layout.fillHeight: !root.owner.vertical
            Layout.fillWidth: root.owner.vertical || stretches
            Layout.preferredWidth: root.owner.vertical ? -1 : naturalLength
            Layout.preferredHeight: root.owner.vertical ? naturalLength : -1
            Layout.maximumWidth: !stretches || root.owner.vertical ? Number.POSITIVE_INFINITY : root.center ? naturalLength : root.owner.width / 4

            Rectangle {
                id: pill

                readonly property int thickness: root.owner.islandThickness

                // Across the bar: islandGap from the screen edge.
                x: !root.owner.vertical ? 0 : root.owner.edge === "left" ? root.owner.islandGap : island.width - width - root.owner.islandGap
                y: root.owner.vertical ? 0 : root.owner.edge === "top" ? root.owner.islandGap : island.height - height - root.owner.islandGap
                width: root.owner.vertical ? thickness : island.width
                height: root.owner.vertical ? island.height : thickness

                radius: thickness / 2
                color: island.bare ? "transparent" : Theme.backgroundAlt
                border.color: Theme.surfaceAlt
                border.width: island.bare ? 0 : 1

                GridLayout {
                    id: modules

                    flow: root.owner.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                    columnSpacing: root.islandSpacing
                    rowSpacing: root.islandSpacing

                    anchors {
                        fill: parent
                        leftMargin: root.owner.vertical ? 0 : island.padding
                        rightMargin: root.owner.vertical ? 0 : island.padding
                        topMargin: root.owner.vertical ? island.padding : 0
                        bottomMargin: root.owner.vertical ? island.padding : 0
                    }

                    Repeater {
                        id: slots

                        model: island.modelData

                        Item {
                            id: slot

                            required property string modelData

                            readonly property var item: loader.item
                            // Modules without an `available` property are always shown.
                            readonly property bool shown: item ? (item.available ?? true) : false
                            // The window title (anything with `maxWidth`) shrinks to
                            // fit, eliding its text.
                            readonly property bool stretches: item !== null && item.maxWidth !== undefined
                            // Sizes come from the module's natural size, rounded up so
                            // the layout's whole-pixel sizes never cut it short.
                            readonly property real naturalWidth: Math.ceil(item?.implicitWidth ?? 0)
                            readonly property real naturalHeight: Math.ceil(item?.implicitHeight ?? 0)

                            objectName: "module-" + modelData
                            visible: shown

                            Layout.fillHeight: !root.owner.vertical
                            Layout.fillWidth: root.owner.vertical || stretches
                            Layout.preferredWidth: root.owner.vertical ? -1 : naturalWidth
                            Layout.preferredHeight: root.owner.vertical ? naturalHeight : -1
                            Layout.maximumWidth: stretches && !root.owner.vertical ? naturalWidth : Number.POSITIVE_INFINITY

                            // Positioned, never sized: a Loader that sizes its item can
                            // shrink it to nothing. Along the island it starts at the
                            // slot's start; across it, it is centered.
                            Loader {
                                id: loader

                                sourceComponent: root.owner.modules[slot.modelData] ?? null

                                x: root.owner.vertical ? (slot.width - width) / 2 : 0
                                y: root.owner.vertical ? 0 : (slot.height - height) / 2

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
            }
        }
    }
}
