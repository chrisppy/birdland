// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import modules.theme

PanelWindow {
    id: root

    signal closeRequested

    readonly property int maxRows: 8
    readonly property var results: filter(DesktopEntries.applications.values, search.text)

    // Score an entry against a lowercase query. Higher is better, 0 = no match.
    function score(app, q) {
        const name = (app.name || "").toLowerCase();

        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 800 - name.length;

        const idx = name.indexOf(q);
        if (idx >= 0)
            return 600 - idx;

        // in-order subsequence match on the name ("ffx" -> "firefox")
        let qi = 0;
        let gaps = 0;
        for (let i = 0; i < name.length && qi < q.length; i++) {
            if (name[i] === q[qi])
                qi++;
            else if (qi > 0)
                gaps++;
        }
        if (qi === q.length)
            return 300 - gaps;

        const extra = [app.genericName || "", app.comment || "", (app.keywords || []).join(" ")].join(" ").toLowerCase();
        return extra.indexOf(q) >= 0 ? 100 : 0;
    }

    // Visible apps matching `query`, best first. Empty query = alphabetical.
    function filter(entries, query) {
        const q = (query || "").trim().toLowerCase();
        const apps = entries.filter(a => !a.noDisplay);

        if (!q)
            return apps.sort((a, b) => a.name.localeCompare(b.name));

        return apps.map(app => ({
                    app: app,
                    s: score(app, q)
                })).filter(x => x.s > 0).sort((x, y) => y.s - x.s || x.app.name.localeCompare(y.app.name)).map(x => x.app);
    }

    function launch(app) {
        if (!app)
            return;
        app.execute();
        root.closeRequested();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "birdland-dugout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: search.forceActiveFocus()

    // Dimmed backdrop; click outside the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            opacity: 0.5
        }
    }

    Rectangle {
        id: card

        width: 560
        implicitHeight: content.implicitHeight + Theme.spacingMedium * 3
        height: implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2

        radius: Theme.radiusLarge + 4
        color: Theme.background
        border {
            width: 1
            color: Theme.border
        }

        Behavior on height {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        // Swallow clicks so they don't hit the backdrop.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.spacingMedium + 4
            }
            spacing: Theme.spacingMedium + 2

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: Theme.radiusLarge - 4
                color: Theme.surface

                TextInput {
                    id: search

                    anchors {
                        fill: parent
                        leftMargin: Theme.spacingLarge
                        rightMargin: Theme.spacingLarge
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.textBright
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.background
                    font {
                        family: Fonts.family
                        pixelSize: Fonts.sizeHeader
                    }

                    onTextChanged: list.currentIndex = 0

                    Text {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search applications…"
                        color: Theme.textMuted
                        font: search.font
                    }

                    Keys.onEscapePressed: root.closeRequested()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()
                    Keys.onBacktabPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
                    Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
                    Keys.onPressed: event => {
                        if (!(event.modifiers & Qt.ControlModifier))
                            return;
                        if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                            list.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                            list.decrementCurrentIndex();
                            event.accepted = true;
                        }
                    }
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, root.maxRows * 48)
                visible: count > 0
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: root.results

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: DugoutItem {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    app: modelData
                    selected: ListView.isCurrentItem

                    onHovered: list.currentIndex = index
                    onClicked: root.launch(modelData)
                }
            }
        }
    }
}
