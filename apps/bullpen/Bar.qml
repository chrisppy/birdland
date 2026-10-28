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

    // Status indicators shown before the clock, in order. Set with
    // BULLPEN_MODULES, a comma-separated list of the names in `indicators`.
    readonly property var modules: {
        const value = Quickshell.env("BULLPEN_MODULES");
        const list = value === null || value === undefined ? "cpu,memory,gpu,temperature,weather,network,volume,microphone,battery" : String(value);
        return list.split(",").map(s => s.trim()).filter(s => s !== "");
    }
    // BULLPEN_UNITS=imperial shows °F; the default is metric.
    readonly property bool imperial: String(Quickshell.env("BULLPEN_UNITS") ?? "").toLowerCase() === "imperial"
    // "latitude,longitude" for the weather; it stays hidden without one.
    readonly property string weatherLocation: String(Quickshell.env("BULLPEN_WEATHER_LOCATION") ?? "")

    readonly property var indicators: ({
            cpu: cpuIndicator,
            memory: memoryIndicator,
            gpu: gpuIndicator,
            temperature: temperatureIndicator,
            weather: weatherIndicator,
            network: networkIndicator,
            volume: volumeIndicator,
            microphone: microphoneIndicator,
            battery: batteryIndicator
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
        anchors.fill: parent
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        // Round the two corners on the side facing the screen.
        topLeftRadius: bar.edge === "bottom" || bar.edge === "right" ? Theme.radiusXLarge : 0
        topRightRadius: bar.edge === "bottom" || bar.edge === "left" ? Theme.radiusXLarge : 0
        bottomLeftRadius: bar.edge === "top" || bar.edge === "right" ? Theme.radiusXLarge : 0
        bottomRightRadius: bar.edge === "top" || bar.edge === "left" ? Theme.radiusXLarge : 0

        // start: workspaces, flush with the screen edge
        Workspaces {
            id: workspaces

            edge: bar.edge

            anchors {
                top: bar.edge !== "bottom" ? parent.top : undefined
                bottom: bar.edge === "bottom" ? parent.bottom : undefined
                left: bar.edge !== "right" ? parent.left : undefined
                right: bar.edge === "right" ? parent.right : undefined
                leftMargin: bar.vertical ? 0 : Theme.spacingMedium
                topMargin: bar.vertical ? Theme.spacingMedium : 0
            }
        }

        // center: focused window title (horizontal bars only). Its width keeps
        // it clear of the workspaces and clock on both sides, so it stays
        // centered and long titles are elided instead of overlapping them.
        Text {
            visible: !bar.vertical
            anchors.centerIn: parent
            width: Math.max(0, Math.min(implicitWidth, parent.width - 2 * (Math.max(workspaces.width, end.width) + Theme.spacingMedium + Theme.spacingLarge)))

            text: niri.focusedWindow?.title ?? ""
            color: Theme.textBright
            elide: Text.ElideRight
            font {
                family: Fonts.family
                pixelSize: Fonts.size
            }
        }

        // end: status indicators, then the clock. In a row on top/bottom bars,
        // in a column on the sides. Unavailable indicators (no battery, no
        // weather location...) take no space.
        Grid {
            id: end

            columns: bar.vertical ? 1 : -1
            rows: bar.vertical ? -1 : 1
            columnSpacing: Theme.spacingLarge
            rowSpacing: Theme.spacingMedium + Theme.spacingSmall
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            anchors {
                right: bar.vertical ? undefined : parent.right
                rightMargin: Theme.spacingMedium
                verticalCenter: bar.vertical ? undefined : parent.verticalCenter
                bottom: bar.vertical ? parent.bottom : undefined
                bottomMargin: Theme.spacingMedium
                horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
            }

            Repeater {
                model: bar.modules

                Loader {
                    required property string modelData

                    objectName: "indicator-" + modelData
                    sourceComponent: bar.indicators[modelData] ?? null
                    visible: item?.available ?? false

                    Component.onCompleted: {
                        if (!bar.indicators[modelData])
                            console.warn("bullpen: unknown module in BULLPEN_MODULES:", modelData);
                    }
                }
            }

            Clock {
                id: clock

                vertical: bar.vertical
            }
        }
    }

    // Shared by the cpu, memory, gpu and temperature indicators; only samples
    // while one of them is shown.
    SystemStats {
        id: systemStats

        running: ["cpu", "memory", "gpu", "temperature"].some(name => bar.modules.includes(name))
        sampleGpu: bar.modules.includes("gpu")
    }

    Component {
        id: cpuIndicator
        Cpu {
            stats: systemStats
            vertical: bar.vertical
        }
    }
    Component {
        id: memoryIndicator
        Memory {
            stats: systemStats
            vertical: bar.vertical
        }
    }
    Component {
        id: gpuIndicator
        Gpu {
            stats: systemStats
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: temperatureIndicator
        Temperature {
            stats: systemStats
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: weatherIndicator
        Weather {
            location: bar.weatherLocation
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: networkIndicator
        Network {
            vertical: bar.vertical
        }
    }
    Component {
        id: volumeIndicator
        Audio {
            vertical: bar.vertical
        }
    }
    Component {
        id: microphoneIndicator
        Audio {
            input: true
            vertical: bar.vertical
        }
    }
    Component {
        id: batteryIndicator
        Battery {
            vertical: bar.vertical
        }
    }
}
