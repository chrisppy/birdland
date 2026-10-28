// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import modules.theme

PanelWindow {
    id: bar

    // Screen edge the bar is attached to: top, bottom, left or right.
    // Set with the BULLPEN_POSITION environment variable (default: top).
    readonly property string edge: {
        const value = String(Quickshell.env("BULLPEN_POSITION") ?? "top").toLowerCase();
        return ["top", "bottom", "left", "right"].includes(value) ? value : "top";
    }
    readonly property bool vertical: edge === "left" || edge === "right"

    // One line of text on top/bottom bars; room for the stacked clock on the sides.
    readonly property int thickness: vertical ? 48 : 30

    // What goes in each part of the bar, in order: comma-separated names from
    // `modules`, set with BULLPEN_LEFT, BULLPEN_CENTER and BULLPEN_RIGHT. On
    // side bars, left is the top and right the bottom. An empty value leaves
    // that part empty; unset uses the default.
    function sectionModules(variable, fallback) {
        const value = Quickshell.env(variable);
        const list = value === null || value === undefined ? fallback : String(value);
        return list.split(",").map(s => s.trim()).filter(s => s !== "");
    }
    readonly property var leftModules: sectionModules("BULLPEN_LEFT", "workspaces")
    readonly property var centerModules: sectionModules("BULLPEN_CENTER", "title")
    readonly property var rightModules: sectionModules("BULLPEN_RIGHT", "cpu,memory,gpu,temperature,weather,network,volume,microphone,battery,clock")
    readonly property var allModules: leftModules.concat(centerModules, rightModules)

    // BULLPEN_UNITS=imperial shows °F; the default is metric.
    readonly property bool imperial: String(Quickshell.env("BULLPEN_UNITS") ?? "").toLowerCase() === "imperial"
    // "latitude,longitude" for the weather; it stays hidden without one.
    readonly property string weatherLocation: String(Quickshell.env("BULLPEN_WEATHER_LOCATION") ?? "")

    readonly property var modules: ({
            workspaces: workspacesModule,
            title: titleModule,
            clock: clockModule,
            cpu: cpuModule,
            memory: memoryModule,
            gpu: gpuModule,
            temperature: temperatureModule,
            weather: weatherModule,
            network: networkModule,
            volume: volumeModule,
            microphone: microphoneModule,
            battery: batteryModule
        })

    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? 0 : thickness
    // Transparent, so the screen shows through the panel's rounded corners.
    color: "transparent"

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }

    Rectangle {
        id: panel

        // Both sides get the size of the larger one, so the center part stays
        // centered on the bar.
        readonly property real sideSize: bar.vertical ? Math.max(leftSection.implicitHeight, rightSection.implicitHeight) : Math.max(leftSection.implicitWidth, rightSection.implicitWidth)

        anchors.fill: parent
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        // Round the two corners on the side facing the screen.
        topLeftRadius: bar.edge === "bottom" || bar.edge === "right" ? Theme.radiusXLarge : 0
        topRightRadius: bar.edge === "bottom" || bar.edge === "left" ? Theme.radiusXLarge : 0
        bottomLeftRadius: bar.edge === "top" || bar.edge === "right" ? Theme.radiusXLarge : 0
        bottomRightRadius: bar.edge === "top" || bar.edge === "left" ? Theme.radiusXLarge : 0

        // left (top on side bars)
        Item {
            id: leftArea

            width: panel.sideSize
            height: panel.sideSize

            anchors {
                left: parent.left
                top: parent.top
                bottom: bar.vertical ? undefined : parent.bottom
                right: bar.vertical ? parent.right : undefined
                leftMargin: bar.vertical ? 0 : Theme.spacingMedium
                topMargin: bar.vertical ? Theme.spacingMedium : 0
            }

            Section {
                id: leftSection

                owner: bar
                names: bar.leftModules

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: bar.vertical ? undefined : parent.bottom
                    right: bar.vertical ? parent.right : undefined
                }
            }
        }

        // center: between the two sides, centered on the bar
        Item {
            id: centerArea

            anchors {
                left: bar.vertical ? parent.left : leftArea.right
                right: bar.vertical ? parent.right : rightArea.left
                top: bar.vertical ? leftArea.bottom : parent.top
                bottom: bar.vertical ? rightArea.top : parent.bottom
                leftMargin: bar.vertical ? 0 : Theme.spacingLarge
                rightMargin: bar.vertical ? 0 : Theme.spacingLarge
                topMargin: bar.vertical ? Theme.spacingLarge : 0
                bottomMargin: bar.vertical ? Theme.spacingLarge : 0
            }

            Section {
                id: centerSection

                owner: bar
                names: bar.centerModules
                center: true

                anchors.centerIn: parent
                width: bar.vertical ? parent.width : Math.max(0, Math.min(implicitWidth, parent.width))
                height: bar.vertical ? Math.max(0, Math.min(implicitHeight, parent.height)) : parent.height
            }
        }

        // right (bottom on side bars)
        Item {
            id: rightArea

            width: panel.sideSize
            height: panel.sideSize

            anchors {
                right: parent.right
                bottom: parent.bottom
                top: bar.vertical ? undefined : parent.top
                left: bar.vertical ? parent.left : undefined
                rightMargin: bar.vertical ? 0 : Theme.spacingMedium
                bottomMargin: bar.vertical ? Theme.spacingMedium : 0
            }

            Section {
                id: rightSection

                owner: bar
                names: bar.rightModules

                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    top: bar.vertical ? undefined : parent.top
                    left: bar.vertical ? parent.left : undefined
                }
            }
        }
    }

    // Shared by the cpu, memory, gpu and temperature modules; only samples
    // while one of them is in the bar.
    SystemStats {
        id: systemStats

        running: ["cpu", "memory", "gpu", "temperature"].some(name => bar.allModules.includes(name))
        sampleGpu: bar.allModules.includes("gpu")
    }

    Component {
        id: workspacesModule
        Workspaces {
            edge: bar.edge
        }
    }
    // Focused window title. Top/bottom bars only; long titles are elided.
    Component {
        id: titleModule
        Text {
            readonly property bool available: !bar.vertical
            // Set by the section: the room it has. Longer titles are elided.
            property real maxWidth: Number.POSITIVE_INFINITY

            width: Math.min(implicitWidth, maxWidth)
            text: niri.focusedWindow?.title ?? ""
            color: Theme.textBright
            elide: Text.ElideRight
            font {
                family: Fonts.family
                pixelSize: Fonts.size
            }
        }
    }
    Component {
        id: clockModule
        Clock {
            vertical: bar.vertical
        }
    }
    Component {
        id: cpuModule
        Cpu {
            stats: systemStats
            vertical: bar.vertical
        }
    }
    Component {
        id: memoryModule
        Memory {
            stats: systemStats
            vertical: bar.vertical
        }
    }
    Component {
        id: gpuModule
        Gpu {
            stats: systemStats
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: temperatureModule
        Temperature {
            stats: systemStats
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: weatherModule
        Weather {
            location: bar.weatherLocation
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: networkModule
        Network {
            vertical: bar.vertical
        }
    }
    Component {
        id: volumeModule
        Audio {
            vertical: bar.vertical
        }
    }
    Component {
        id: microphoneModule
        Audio {
            input: true
            vertical: bar.vertical
        }
    }
    Component {
        id: batteryModule
        Battery {
            vertical: bar.vertical
        }
    }
}
