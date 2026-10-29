// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.controls
import modules.theme
import modules.wallpaper

// The greeter screen: the time, who is logging in, a password field, the
// session to start (bottom left) and power buttons (bottom right).
Item {
    id: root

    // The shell: users, user, sessions, session, prompt, message, busy,
    // submit(), selectUser(), selectSession(), powerAction(), failed.
    required property var gate

    Wallpaper {
        anchors.fill: parent
        source: root.gate.wallpaper
        fill: root.gate.fill
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
            spacing: Theme.spacingSmall

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F0009}" // account_circle
                color: Theme.textBright
                font {
                    family: Fonts.icons
                    pixelSize: Fonts.sizeHeader + 8
                }
            }

            Selector {
                anchors.verticalCenter: parent.verticalCenter
                items: root.gate.users.map(u => u.realName || u.name)
                currentIndex: root.gate.userIndex
                pixelSize: Fonts.sizeHeader + 2
                color: Theme.textBright
                onMoved: index => {
                    root.gate.selectUser(index);
                    field.focusInput();
                }
            }
        }

        PasswordField {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            placeholder: root.gate.prompt
            echo: root.gate.promptEchoes
            busy: root.gate.busy
            onAccepted: text => root.gate.submit(text)

            Connections {
                target: root.gate
                function onFailed() {
                    field.error = true;
                    field.shake();
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: Fonts.size * 2
            text: root.gate.message
            color: root.gate.messageIsError ? Theme.primary : Theme.text
            font {
                family: Fonts.family
                pixelSize: Fonts.size + 1
            }
        }
    }

    Row {
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: Theme.spacingLarge * 2
        }
        spacing: Theme.spacingSmall
        visible: root.gate.sessions.length > 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0379}" // monitor
            color: Theme.text
            font {
                family: Fonts.icons
                pixelSize: Fonts.sizeHeader
            }
        }

        Selector {
            anchors.verticalCenter: parent.verticalCenter
            items: root.gate.sessions.map(s => s.name)
            currentIndex: root.gate.sessionIndex
            onMoved: index => {
                root.gate.selectSession(index);
                field.focusInput();
            }
        }
    }

    Row {
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Theme.spacingLarge * 2
        }
        spacing: Theme.spacingLarge
        visible: root.gate.power

        IconButton {
            icon: "\u{F0709}" // restart
            label: "Restart"
            onClicked: root.gate.powerAction("reboot")
        }

        IconButton {
            icon: "\u{F0425}" // power
            label: "Shut down"
            onClicked: root.gate.powerAction("poweroff")
        }
    }

    Component.onCompleted: field.focusInput()
}
