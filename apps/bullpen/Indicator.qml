// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// One status item in the bar: an icon glyph and an optional label, side by
// side on top/bottom bars and stacked on left/right bars.
Item {
    id: root

    property bool vertical: false
    // A Symbols Nerd Font glyph.
    property string icon: ""
    property string label: ""
    property color color: Theme.textBright
    // False hides the indicator, e.g. no battery or no data yet. The bar uses
    // this rather than `visible`, which also turns false when a parent hides.
    property bool available: true
    // Shows a pointer cursor; set for indicators that react to input.
    property bool interactive: false
    // Show temperatures in °F instead of °C.
    property bool imperial: false

    signal clicked(var mouse)
    // Wheel movement in notches: positive is up/away.
    signal scrolled(real steps)

    function degrees(celsius) {
        return Math.round(imperial ? celsius * 9 / 5 + 32 : celsius) + "°";
    }

    function percent(fraction) {
        return Math.round(fraction * 100) + "%";
    }

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Grid {
        id: content

        anchors.centerIn: parent
        columns: root.vertical ? 1 : 2
        columnSpacing: Theme.spacingSmall
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Text {
            text: root.icon
            color: root.color
            font {
                family: Fonts.icons
                pixelSize: Fonts.size + 4
            }
        }

        Text {
            visible: root.label !== ""
            text: root.label
            color: root.color
            horizontalAlignment: Text.AlignHCenter
            font {
                family: Fonts.family
                pixelSize: root.vertical ? Fonts.size - 2 : Fonts.size
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel.angleDelta.y / 120)
    }
}
