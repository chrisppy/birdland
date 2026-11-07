## Outfield wallpapers

Outfield draws a wallpaper on every monitor, in place of tools like `swaybg`.
`wallpaper` and `outputs` take a Nix path (copied into the store, e.g.
`./wall.jpg`) or a string used where it is (e.g. `"~/Pictures/Wallpapers"`). A
folder shows its JPEG, PNG, WebP, BMP, GIF and TIFF images, rotating every
`interval` minutes with a crossfade, and picks up files you add or remove.
Images are decoded at the screen's resolution, so large photos stay sharp
without using much memory.

Control a running Outfield over IPC, e.g. from a Niri keybind:

```sh
birdland-outfield ipc call outfield next                       # next image from the folder
birdland-outfield ipc call outfield set ~/Pictures/beach.jpg   # every monitor, until reload
birdland-outfield ipc call outfield setOutput DP-1 ~/Pictures/wide
birdland-outfield ipc call outfield reload                     # back to the configured ones
birdland-outfield ipc call outfield current                    # what each monitor shows
```

To show the wallpaper in Niri's overview and between workspaces, add a layer
rule to your Niri config (needs Niri 25.05 or later):

```kdl
layer-rule {
    match namespace="^birdland-outfield$"
    place-within-backdrop true
}
```
