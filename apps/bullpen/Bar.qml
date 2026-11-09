// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import modules.theme
import modules.util

PanelWindow {
    id: bar

    // Screen edge the bar is attached to: top, bottom, left or right.
    // Set with the BULLPEN_POSITION environment variable (default: top).
    readonly property string edge: Env.edge("BULLPEN_POSITION", "top")
    readonly property bool vertical: ScreenEdges.vertical(edge)

    // One line of text on top/bottom bars; room for the stacked clock on the sides.
    readonly property int thickness: vertical ? 48 : 34
    // The bar has no background of its own: its modules sit in floating pills
    // ("islands"), this far from the screen edge and this thick.
    readonly property int islandGap: 6
    readonly property int islandThickness: thickness - 10

    // What goes in each part of the bar, in order: comma-separated islands set
    // with BULLPEN_LEFT, BULLPEN_CENTER and BULLPEN_RIGHT, each one name from
    // `modules` or several joined with "+" to share a pill
    // ("cpu+memory,clock"). On side bars, left is the top and right the
    // bottom. An empty value leaves that part empty; unset uses the default.
    readonly property var leftGroups: Env.groups("BULLPEN_LEFT", "workspaces")
    readonly property var centerGroups: Env.groups("BULLPEN_CENTER", "title")
    readonly property var rightGroups: Env.groups("BULLPEN_RIGHT", "media,cpu+memory+gpu+temperature,weather,network+volume+microphone+battery,tray,clock")
    readonly property var allModules: [].concat(...leftGroups, ...centerGroups, ...rightGroups)

    // BULLPEN_UNITS=imperial shows °F; the default is metric.
    readonly property bool imperial: Env.get("BULLPEN_UNITS").toLowerCase() === "imperial"

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
            battery: batteryModule,
            tray: trayModule,
            media: mediaModule,
            feeds: feedsModule
        })

    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? 0 : thickness
    // Transparent, so the screen shows around the islands.
    color: "transparent"

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }

    // Lays out the three parts; draws nothing itself, so the screen shows
    // between the islands.
    Item {
        id: panel

        // Both sides get the size of the larger one, so the center part stays
        // centered on the bar.
        readonly property real sideSize: bar.vertical ? Math.max(leftSection.implicitHeight, rightSection.implicitHeight) : Math.max(leftSection.implicitWidth, rightSection.implicitWidth)

        anchors.fill: parent

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
                leftMargin: bar.vertical ? 0 : bar.islandGap
                topMargin: bar.vertical ? bar.islandGap : 0
            }

            Section {
                id: leftSection

                owner: bar
                groups: bar.leftGroups

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
                groups: bar.centerGroups
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
                rightMargin: bar.vertical ? 0 : bar.islandGap
                bottomMargin: bar.vertical ? bar.islandGap : 0
            }

            Section {
                id: rightSection

                owner: bar
                groups: bar.rightGroups

                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    top: bar.vertical ? undefined : parent.top
                    left: bar.vertical ? parent.left : undefined
                }
            }
        }
    }

    // System statistics, shared by every bar (see shell.qml), and whether
    // this bar shows any of them.
    required property SystemStats stats
    readonly property bool usesStats: ["cpu", "memory", "gpu", "temperature"].some(name => allModules.includes(name))
    readonly property bool usesGpu: allModules.includes("gpu")
    readonly property bool usesTemperature: allModules.includes("temperature")
    // The weather, also shared by every bar.
    required property WeatherData weather
    readonly property bool usesWeather: allModules.includes("weather")
    // Unread feed items, also shared.
    required property FeedsData feeds
    readonly property bool usesFeeds: allModules.includes("feeds")
    // systemd-networkd's links, also shared.
    required property NetworkData networkd
    readonly property bool usesNetwork: allModules.includes("network")

    Component {
        id: workspacesModule
        Workspaces {
            edge: bar.edge
            thickness: bar.islandThickness
            output: bar.screen?.name ?? ""
        }
    }
    // Focused window title. Top/bottom bars only; long titles are elided.
    // Hidden while empty, so it leaves no gap on the other monitors' bars.
    Component {
        id: titleModule
        Text {
            readonly property bool available: !bar.vertical && text !== ""
            // Set by the section: the room it has. Longer titles are elided.
            property real maxWidth: Number.POSITIVE_INFINITY

            // Only the bar on the focused window's monitor shows its title.
            readonly property var window: niri.focusedWindow
            readonly property bool here: {
                if (!window)
                    return false;
                const workspaces = niri.workspaces;
                workspaces.count; // re-evaluate as workspaces come and go
                const i = workspaces.indexOfId(window.workspaceId);
                return i < 0 || !bar.screen || workspaces.get(i).output === bar.screen.name;
            }

            width: Math.min(implicitWidth, maxWidth)
            text: here ? window.title : ""
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
            stats: bar.stats
            vertical: bar.vertical
        }
    }
    Component {
        id: memoryModule
        Memory {
            stats: bar.stats
            vertical: bar.vertical
        }
    }
    Component {
        id: gpuModule
        Gpu {
            stats: bar.stats
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: temperatureModule
        Temperature {
            stats: bar.stats
            vertical: bar.vertical
            imperial: bar.imperial
        }
    }
    Component {
        id: weatherModule
        Weather {
            weather: bar.weather
            vertical: bar.vertical
        }
    }
    Component {
        id: networkModule
        Network {
            networkd: bar.networkd
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
    Component {
        id: trayModule
        Tray {
            window: bar
            edge: bar.edge
        }
    }
    Component {
        id: mediaModule
        Media {
            vertical: bar.vertical
        }
    }
    Component {
        id: feedsModule
        Feeds {
            feeds: bar.feeds
            vertical: bar.vertical
        }
    }
}
