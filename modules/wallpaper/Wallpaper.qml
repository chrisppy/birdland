// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import modules.theme

// Shows `source`: an image file, or a folder of images that changes every
// `interval` minutes. New images crossfade in. With no source, or nothing to
// show, it is a plain theme-colored background.
Item {
    id: root

    // An image file or a folder, as an absolute path.
    property string source: ""
    // Minutes between images when `source` is a folder; 0 keeps the first.
    property int interval: 30
    // Random order instead of by file name.
    property bool shuffle: true
    // fill (cover, cropping), fit, stretch, center or tile.
    property string fill: "fill"

    // The image on screen, as a path.
    readonly property string current: priv.current

    readonly property bool isFolder: source !== "" && !/\.(jpe?g|png|webp|bmp|gif|tiff?)$/i.test(source)

    // Show the next image from the folder (or the same file again).
    function next() {
        if (!isFolder) {
            show(source);
            return;
        }
        const images = priv.images;
        if (images.length === 0) {
            show("");
            return;
        }
        let index;
        if (shuffle && images.length > 1) {
            do
                index = Math.floor(Math.random() * images.length);
            while (images[index] === priv.current)
        } else {
            index = (images.indexOf(priv.current) + 1) % images.length;
        }
        show(images[index]);
    }

    // Load `path` into the hidden image; it fades in once it has loaded.
    function show(path) {
        priv.current = path;
        const toA = !priv.frontIsA;
        const back = toA ? imageA : imageB;
        priv.pending = path === "" ? "" : toA ? "a" : "b";
        back.source = fileUrl(path);
        // Nothing to load: an empty source, or the same image already loaded.
        if (path === "" || back.status === Image.Ready)
            promote(toA);
    }

    // Bring a layer to the front (the other fades out).
    function promote(toA) {
        priv.pending = "";
        priv.frontIsA = toA;
    }

    // A file:// URL for an absolute path. Each segment is percent-encoded so
    // spaces, '#' and '?' in names survive.
    function fileUrl(path) {
        return path === "" ? "" : "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function load() {
        priv.current = "";
        if (!isFolder)
            show(source);
        else if (source.includes("#"))
            // Qt's folder listing finds nothing in such folders, whatever the
            // URL encoding; files with '#' in their names are fine.
            console.warn("outfield: can't list a folder whose path contains '#':", source);
    }

    onSourceChanged: load()
    Component.onCompleted: load()

    QtObject {
        id: priv

        property string current: ""
        property bool frontIsA: true
        // The layer loading the image just asked for ("a" or "b"). Only it may
        // come to the front: the other layer also reloads when the screen size
        // or fill mode changes, and must stay behind.
        property string pending: ""
        property var images: []
    }

    FolderListModel {
        id: folder

        folder: root.isFolder ? root.fileUrl(root.source) : ""
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif", "*.tif", "*.tiff"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name

        // Rebuild the list when the folder loads or its files change; pick an
        // image if none is shown yet, or if the shown one was removed.
        function refresh() {
            if (status !== FolderListModel.Ready)
                return;
            const list = [];
            for (let i = 0; i < count; i++)
                list.push(get(i, "filePath"));
            priv.images = list;
            if (priv.current === "" || !list.includes(priv.current))
                root.next();
        }

        onStatusChanged: refresh()
        onCountChanged: refresh()
    }

    Timer {
        interval: root.interval * 60 * 1000
        running: root.isFolder && root.interval > 0 && priv.images.length > 1
        repeat: true
        onTriggered: root.next()
    }

    // Theme background, seen with no image or around a "fit"/"center" image.
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    component Layer: Image {
        // "a" or "b".
        required property string name
        required property bool front

        anchors.fill: parent
        asynchronous: true
        cache: false
        smooth: true
        fillMode: ({
                fill: Image.PreserveAspectCrop,
                fit: Image.PreserveAspectFit,
                stretch: Image.Stretch,
                center: Image.Pad,
                tile: Image.Tile
            })[root.fill] ?? Image.PreserveAspectCrop
        // Decode at the screen's size in device pixels, not the file's: a 6K
        // photo then costs no more memory than the screen, and stays sharp on
        // scaled displays. "center" and "tile" use the image's own size.
        sourceSize: root.fill === "center" || root.fill === "tile" ? undefined : Qt.size(Math.ceil(root.width * Screen.devicePixelRatio), Math.ceil(root.height * Screen.devicePixelRatio))

        opacity: front ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 800
                easing.type: Easing.InOutQuad
            }
        }

        onStatusChanged: {
            if (priv.pending !== name)
                return;
            if (status === Image.Ready) {
                root.promote(name === "a");
            } else if (status === Image.Error) {
                console.warn("outfield: could not load", source);
                priv.pending = "";
            }
        }
    }

    Layer {
        id: imageA

        name: "a"
        front: priv.frontIsA
    }

    Layer {
        id: imageB

        name: "b"
        front: !priv.frontIsA
    }
}
