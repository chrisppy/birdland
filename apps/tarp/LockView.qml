// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Io
import modules.controls
import modules.theme
import modules.wallpaper

// What one locked monitor shows: the wallpaper dimmed, the time, the user and
// a password field, and a suspend button.
Item {
    id: root

    // The shell: prompt, message, busy, userName, submit(), failed.
    required property var lock

    Wallpaper {
        anchors.fill: parent
        source: root.lock.wallpaper
        fill: root.lock.fill
        interval: 0
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: 0.55
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingLarge

        BigClock {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: Theme.spacingLarge * 2
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingMedium

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F0009}" // account_circle
                color: Theme.textBright
                font {
                    family: Fonts.icons
                    pixelSize: Fonts.sizeHeader + 8
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.lock.userName
                color: Theme.textBright
                font {
                    family: Fonts.family
                    pixelSize: Fonts.sizeHeader + 2
                }
            }
        }

        PasswordField {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            placeholder: root.lock.prompt
            echo: root.lock.promptEchoes
            busy: root.lock.busy
            onAccepted: text => root.lock.submit(text)

            Connections {
                target: root.lock
                function onFailed() {
                    field.error = true;
                    field.shake();
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: Fonts.size * 2
            text: root.lock.message
            color: root.lock.messageIsError ? Theme.primary : Theme.text
            font {
                family: Fonts.family
                pixelSize: Fonts.size + 1
            }
        }
    }

    IconButton {
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Theme.spacingLarge * 2
        }
        icon: "\u{F0904}" // power_sleep
        label: "Suspend"
        onClicked: suspend.running = true
    }

    // The screen stays locked through suspend.
    Process {
        id: suspend

        command: ["systemctl", "suspend"]
    }

    Component.onCompleted: field.focusInput()
}
