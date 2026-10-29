// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// A rounded entry for passwords and other login prompts. Enter emits
// `accepted(text)` and clears the field at once, so the text never lingers.
Rectangle {
    id: root

    property string placeholder: "Password"
    // Show the typed text, for prompts that aren't secret (a one-time code).
    property bool echo: false
    // While a check runs: input is disabled and the placeholder says so.
    property bool busy: false
    property bool error: false

    signal accepted(string text)

    function focusInput() {
        input.forceActiveFocus();
    }

    function shake() {
        shakeAnimation.restart();
    }

    implicitWidth: 320
    implicitHeight: 46
    radius: Theme.radiusLarge
    color: Theme.surface
    border.width: 1
    border.color: error ? Theme.primary : input.activeFocus ? Theme.accent : Theme.border

    transform: Translate {
        id: shakeOffset
    }

    SequentialAnimation {
        id: shakeAnimation

        loops: 2
        NumberAnimation {
            target: shakeOffset
            property: "x"
            to: -8
            duration: 40
        }
        NumberAnimation {
            target: shakeOffset
            property: "x"
            to: 8
            duration: 80
        }
        NumberAnimation {
            target: shakeOffset
            property: "x"
            to: 0
            duration: 40
        }
    }

    TextInput {
        id: input

        anchors {
            fill: parent
            leftMargin: Theme.spacingLarge
            rightMargin: Theme.spacingLarge
        }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        enabled: !root.busy
        focus: true
        echoMode: root.echo ? TextInput.Normal : TextInput.Password
        passwordCharacter: "●"
        color: Theme.textBright
        selectionColor: Theme.accent
        selectedTextColor: Theme.background
        font {
            family: Fonts.family
            pixelSize: Fonts.sizeHeader
        }

        onTextEdited: root.error = false
        // An empty submission would only count as a failed attempt.
        onAccepted: {
            if (text === "")
                return;
            const value = text;
            text = "";
            root.accepted(value);
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.busy ? "Checking…" : root.placeholder
            color: Theme.textMuted
            font: input.font
            elide: Text.ElideRight
            width: parent.width
        }
    }
}
