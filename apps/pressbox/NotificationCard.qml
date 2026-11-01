// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import modules.theme

// One notification: icon or image, app, summary, body and action buttons.
// Click it for the app's default action, or the cross to dismiss it. It
// expires after its timeout unless the pointer is over it; critical
// notifications don't expire.
Rectangle {
    id: root

    required property var notification
    // Milliseconds, for notifications that don't set their own timeout.
    property int defaultTimeout: 5000

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: notification.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: notification.actions.filter(a => a.identifier !== "default")
    // An image sent with the notification (often a photo or album art), else
    // the app's icon (a name from the icon theme, or a path).
    readonly property string picture: {
        if (notification.image !== "")
            return notification.image;
        const icon = notification.appIcon;
        if (icon === "")
            return "";
        return icon.startsWith("/") || icon.includes("://") ? icon : Quickshell.iconPath(icon, true);
    }

    implicitHeight: content.implicitHeight + Theme.spacingLarge * 2
    radius: Theme.radiusLarge
    color: Theme.background
    border {
        width: 1
        color: critical ? Theme.primary : Theme.border
    }

    // -1 asks for the server's default, 0 for never.
    Timer {
        interval: root.notification.expireTimeout > 0 ? root.notification.expireTimeout : root.defaultTimeout
        running: !root.critical && root.notification.expireTimeout !== 0 && !hover.hovered
        onTriggered: root.notification.expire()
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.defaultAction)
                root.defaultAction.invoke();
            else
                root.notification.dismiss();
        }
    }

    Column {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.spacingLarge
        }
        spacing: Theme.spacingMedium

        Row {
            width: parent.width
            spacing: Theme.spacingMedium

            IconImage {
                id: picture

                visible: root.picture !== ""
                implicitSize: 40
                asynchronous: true
                source: root.picture
            }

            Column {
                width: parent.width - (picture.visible ? picture.width + parent.spacing : 0) - close.width - parent.spacing
                spacing: 2

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification.appName
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    font {
                        family: Fonts.family
                        pixelSize: Fonts.size - 1
                    }
                }

                Text {
                    width: parent.width
                    text: root.notification.summary
                    color: Theme.textBright
                    elide: Text.ElideRight
                    font {
                        family: Fonts.family
                        pixelSize: Fonts.size + 1
                        bold: true
                    }
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    // Plain text: the server tells apps it doesn't do markup.
                    text: root.notification.body
                    textFormat: Text.PlainText
                    color: Theme.text
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font {
                        family: Fonts.family
                        pixelSize: Fonts.size
                    }
                }
            }

            Text {
                id: close

                text: "\u{F0156}" // close
                color: closeMouse.containsMouse ? Theme.textBright : Theme.textMuted
                font {
                    family: Fonts.icons
                    pixelSize: Fonts.size + 2
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    anchors.margins: -Theme.spacingSmall
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notification.dismiss()
                }
            }
        }

        Flow {
            width: parent.width
            visible: root.buttons.length > 0
            spacing: Theme.spacingSmall

            Repeater {
                model: root.buttons

                Rectangle {
                    required property var modelData

                    implicitWidth: label.implicitWidth + Theme.spacingLarge * 2
                    implicitHeight: label.implicitHeight + Theme.spacingMedium * 2
                    radius: Theme.radiusMedium
                    color: buttonMouse.containsMouse ? Theme.surfaceAlt : Theme.surface

                    Text {
                        id: label

                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: Theme.textBright
                        font {
                            family: Fonts.family
                            pixelSize: Fonts.size
                        }
                    }

                    MouseArea {
                        id: buttonMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.invoke()
                    }
                }
            }
        }
    }
}
