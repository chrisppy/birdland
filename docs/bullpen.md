## Bullpen layout

`bullpen.layout` sets what goes in the left, center and right parts of the bar,
and in what order. On side bars, left is the top and right the bottom. Any
module can go in any part, a part can be empty (`[ ]`), and a module left out of
all three isn't shown.

The center stays centered on the bar. A long window title is shortened with "…"
to fit; outside the center it is capped at a quarter of the bar. The workspaces
pill stays flush against the screen edge wherever it is placed.

| Module | Shows | Needs |
| :-------------- | :----------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| `workspaces` | Niri workspaces; click one to switch | Niri |
| `title` | Focused window title, on its monitor's bar (top/bottom bars only) | Niri |
| `clock` | Time and date | Nothing |
| `cpu`, `memory` | Usage | Nothing (`/proc`) |
| `gpu` | Usage, and temperature when available | AMD, Intel (`i915`, `xe`): nothing (sysfs). NVIDIA: `nvidia-smi` |
| `temperature` | CPU temperature | A hwmon sensor: `k10temp`, `zenpower`, `coretemp`... |
| `weather` | Current conditions from Open-Meteo | Internet access and `weather.latitude`/`longitude` |
| `network` | Wired, or Wi-Fi signal strength | NetworkManager, or systemd-networkd (`networkctl`; no captive-portal check) |
| `volume` | Default output; click mutes, scroll changes it | PipeWire with WirePlumber |
| `microphone` | Default input; click mutes, scroll changes it | PipeWire with WirePlumber |
| `battery` | Charge and charging state | UPower: `services.upower.enable = true` in your NixOS config |
| `media` | The playing track; click plays/pauses, right click next, middle click previous | A player with MPRIS (most do) |
| `tray` | Tray icons; click activates, right click opens the menu | Apps with StatusNotifierItem icons |
| `feeds` | Unread items; click opens the reader, right click refreshes the feeds | A paired [pressbox](https://github.com/chrisppy/pressbox) client |

Modules with nothing to show (no battery, no GPU sensor, no weather location, no
media player, no tray icons, no paired pressbox) hide themselves. Icons come
from the Symbols Nerd Font, which the Home Manager module installs.

The `feeds` indicator shows unread items on a
[pressbox](https://github.com/chrisppy/pressbox) server. It reads the server and
token from pressbox's own client files, `~/.config/pressbox/client.json`
(written by pressbox's Home Manager module) and the token saved by
`pressbox pair`, so there is nothing to set up in Birdland beyond adding
`"feeds"` to a layout. It stays hidden until the machine is paired, shows a dim
icon when everything is read, and a red `!` when the server can't be reached or
rejects the token. With `feeds.notifications`, new items also send a
notification (shown by Scoreboard, if you use it).

The `gpu` indicator uses the first GPU it can read: AMD (`gpu_busy_percent`),
then Intel, then NVIDIA. Intel usage is the share of time the render engine is
out of its idle state (RC6 on `i915`, gt-c6 on `xe`). The engine stays awake
briefly after each burst of work, so this can read higher than `intel_gpu_top`
at light load. Integrated Intel GPUs have no temperature sensor of their own;
their heat shows in the CPU temperature.

Reading usage wakes a sleeping GPU. That doesn't matter for the GPU driving your
screen, which is awake anyway. NVIDIA is only polled when there is no AMD or
Intel GPU, so Intel + NVIDIA laptops leave the NVIDIA GPU asleep. On a machine
whose only readable GPU is a discrete one that sleeps, leave `gpu` out of the
layout to save power.

The clock uses Qt's date format: the default `hh:mm dd MMM, yyyy` shows "17:24
01 Nov, 2026", and `h:mm AP  ddd MMM d` shows "5:24 PM Sun Nov 1". A format with
seconds (`ss`) updates every second. The tray hides icons their apps mark as
idle ("passive"), as Waybar does.

The weather request sends only the configured coordinates to
[Open-Meteo](https://open-meteo.com), every 15 minutes (a minute after a failed
request); click the weather to refresh it.
