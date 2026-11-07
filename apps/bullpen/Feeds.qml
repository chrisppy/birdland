// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// Unread items on a pressbox feed server, from the shared FeedsData. Click
// opens the reader; right click asks the server to fetch every feed now.
Indicator {
    id: root

    required property FeedsData feeds

    readonly property bool problem: ["offline", "unauthorized", "error"].includes(feeds.status)

    // Hidden until there is something to say: before the first answer, and
    // on machines that were never paired.
    available: feeds.status !== "loading" && feeds.status !== "unpaired"
    interactive: true
    icon: "\u{F046B}" // rss
    label: problem ? "!" : feeds.unread > 0 ? (feeds.unread > 999 ? "999+" : String(feeds.unread)) : ""
    color: problem ? Theme.primary : feeds.unread > 0 ? Theme.textBright : Theme.textMuted

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            feeds.refresh();
        else
            feeds.open();
    }
}
