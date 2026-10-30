# Birdland

A modular, highly customizable desktop shell suite built with
[Quickshell](https://github.com/outfoxxed/quickshell) and managed entirely
through Nix Flakes and Home Manager. Designed with native support for the
[Niri](https://github.com/YaLTeR/niri) compositor and dynamically themed via
[base24-themes](https://github.com/chrisppy/base24-themes).

## Components

Birdland is split into six Quickshell applications, which can be used
individually or as a complete suite:

- **`bullpen`**: A flexible status bar attachable to any screen edge (`top`,
  `bottom`, `left`, `right`), with workspaces, the focused window, a clock, and
  status indicators for CPU, memory, GPU, temperature, weather, network, volume,
  microphone and battery.
- **`dugout`**: A quick application launcher.
- **`lineup`**: A customizable favorite apps dock for launching and managing
  pinned applications.
- **`outfield`**: Wallpapers on every monitor: an image, or a folder that
  rotates, with optional per-monitor choices.
- **`tarp`**: A lock screen that locks on idle, before sleep and on
  `loginctl lock-session`.
- **`gate`**: A login screen for greetd, set up through the NixOS module, with a
  user list, session list and power buttons.

______________________________________________________________________

## Installation

Add Birdland as an input to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    birdland.url = "github:chrisppy/birdland";
    # birdland.inputs.base24-themes.follows = "base24-themes";
  };

  outputs = { self, nixpkgs, birdland, ... }@inputs: {
    # Your flake outputs...
  };
}
```

______________________________________________________________________

## Home Manager Module Usage

Import the Home Manager module provided by the flake and enable the suite:

```nix
{ inputs, pkgs, ... }: {
  imports = [
    inputs.birdland.homeManagerModules.default
  ];

  programs.birdland = {
    enable = true;
    systemd.enable = true; # Manages apps as graphical-session systemd services

    # A theme bundled with base24-themes, or a custom attribute set
    theme.scheme = "birdland";

    font = {
      family = "Inter";
      package = pkgs.inter;
    };

    bullpen = {
      enable = true;
      position = "top";
      units = "imperial";
      weather = {
        latitude = 39.28;
        longitude = -76.62;
      };
      # What goes where, in order (these are the defaults)
      layout = {
        left = [ "workspaces" ];
        center = [ "title" ];
        right = [ "cpu" "memory" "gpu" "temperature" "weather" "network" "volume" "microphone" "battery" "clock" ];
      };
    };

    dugout = {
      enable = true;
    };

    lineup = {
      enable = true;
      position = "bottom";
      favorites = [
        "firefox"
        "foot"
        "org.gnome.Nautilus"
      ];
    };

    outfield = {
      enable = true;
      wallpaper = "~/Pictures/Wallpapers"; # an image or a folder
      outputs."DP-1" = ./ultrawide.jpg;    # optional, per monitor
      interval = 30;                       # minutes between images from a folder
    };

    tarp = {
      enable = true;
      lockAfter = 10; # minutes without input; null to never lock on idle
    };
  };
}
```

______________________________________________________________________

## Configuration Options

| Option | Type | Default | Description |
| :-------------------------------------------- | :--------------------- | :-------------------- | :---------------------------------------------------------------------------- |
| `programs.birdland.enable` | boolean | `false` | Enable the Birdland Quickshell suite. |
| `programs.birdland.systemd.enable` | boolean | `false` | Run suite components as user systemd services. |
| `programs.birdland.theme.scheme` | theme name / attrs | `"birdland"` | Bundled base24-themes theme name, or a custom theme attribute set. |
| `programs.birdland.font.family` | string | `"Inter"` | Default font family for the apps. |
| `programs.birdland.font.package` | package | `pkgs.inter` | Nix package for the font. |
| `programs.birdland.bullpen.enable` | boolean | `false` | Enable the Bullpen status bar. |
| `programs.birdland.bullpen.position` | enum | `"top"` | Screen edge (`top`, `bottom`, `left`, `right`). |
| `programs.birdland.bullpen.layout.left` | list of modules | `[ "workspaces" ]` | Left part of the bar (top on side bars), in order. |
| `programs.birdland.bullpen.layout.center` | list of modules | `[ "title" ]` | Center of the bar, in order. |
| `programs.birdland.bullpen.layout.right` | list of modules | indicators, `"clock"` | Right part of the bar (bottom on side bars), in order. |
| `programs.birdland.bullpen.units` | enum | `"metric"` | Temperatures in °C (`metric`) or °F (`imperial`). |
| `programs.birdland.bullpen.weather.latitude` | number or null | `null` | Weather location; the weather is hidden until both are set. |
| `programs.birdland.bullpen.weather.longitude` | number or null | `null` | Weather location. |
| `programs.birdland.dugout.enable` | boolean | `false` | Enable the Dugout app launcher. |
| `programs.birdland.lineup.enable` | boolean | `false` | Enable the Lineup favorite apps dock. |
| `programs.birdland.lineup.position` | enum | `"bottom"` | Screen edge (`top`, `bottom`, `left`, `right`). |
| `programs.birdland.lineup.favorites` | list of strings | `[]` | Desktop entry IDs of pinned apps in order. |
| `programs.birdland.outfield.enable` | boolean | `false` | Enable the Outfield wallpapers. |
| `programs.birdland.outfield.wallpaper` | path / string or null | `null` | Image or folder for every monitor; `null` shows the theme background. |
| `programs.birdland.outfield.outputs` | attrs of path / string | `{ }` | Per-monitor image or folder, by output name. |
| `programs.birdland.outfield.interval` | integer | `30` | Minutes between images from a folder; `0` keeps the first. |
| `programs.birdland.outfield.shuffle` | boolean | `true` | Random order instead of file-name order. |
| `programs.birdland.outfield.fill` | enum | `"fill"` | `fill` (crop to cover), `fit`, `stretch`, `center` or `tile`. |
| `programs.birdland.tarp.enable` | boolean | `false` | Enable the Tarp lock screen. Needs `systemd.enable`, or start it yourself. |
| `programs.birdland.tarp.lockAfter` | integer or null | `10` | Minutes without input before locking; `null` never locks on idle. |
| `programs.birdland.tarp.swayidle` | boolean | `true` | Set up swayidle to lock on idle, before sleep and on `loginctl lock-session`. |
| `programs.birdland.tarp.pamService` | string | `"login"` | PAM service that checks the password. |
| `programs.birdland.tarp.wallpaper` | path / string or null | `null` | Image or folder behind the lock; `null` uses Outfield's. |
| `programs.birdland.tarp.fill` | enum | Outfield's | How the wallpaper fits the screen. |

______________________________________________________________________

## Bullpen layout

`bullpen.layout` sets what goes in the left, center and right parts of the bar,
and in what order. On side bars, left is the top and right the bottom. Any
module can go in any part, a part can be empty (`[ ]`), and a module left out of
all three isn't shown.

The center stays centered on the bar. A long window title is shortened with "…"
to fit; outside the center it is capped at a quarter of the bar. The workspaces
pill stays flush against the screen edge wherever it is placed.

| Module | Shows | Needs |
| :-------------- | :--------------------------------------------- | :--------------------------------------------------------------- |
| `workspaces` | Niri workspaces; click one to switch | Niri |
| `title` | Focused window title (top/bottom bars only) | Niri |
| `clock` | Time and date | Nothing |
| `cpu`, `memory` | Usage | Nothing (`/proc`) |
| `gpu` | Usage, and temperature when available | AMD, Intel (`i915`, `xe`): nothing (sysfs). NVIDIA: `nvidia-smi` |
| `temperature` | CPU temperature | A hwmon sensor: `k10temp`, `zenpower`, `coretemp`... |
| `weather` | Current conditions from Open-Meteo | Internet access and `weather.latitude`/`longitude` |
| `network` | Wired, or Wi-Fi signal strength | NetworkManager |
| `volume` | Default output; click mutes, scroll changes it | PipeWire with WirePlumber |
| `microphone` | Default input; click mutes, scroll changes it | PipeWire with WirePlumber |
| `battery` | Charge and charging state | UPower: `services.upower.enable = true` in your NixOS config |

Modules with nothing to show (no battery, no GPU sensor, no weather location)
hide themselves. Icons come from the Symbols Nerd Font, which the Home Manager
module installs.

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

The weather request sends only the configured coordinates to
[Open-Meteo](https://open-meteo.com), every 15 minutes; click the weather to
refresh it.

______________________________________________________________________

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

______________________________________________________________________

## Tarp lock screen

Tarp runs in the background as a user service and locks every monitor when
asked; your password unlocks it. With `tarp.swayidle` (the default) it locks
after `lockAfter` minutes without input, before the machine sleeps, and on
`loginctl lock-session`. Before sleep, the lock command waits until Niri
confirms every monitor is covered, so the desktop never shows on resume. To lock
from a Niri keybind:

```kdl
Mod+Alt+L { spawn "birdland-tarp" "ipc" "call" "tarp" "lock"; }
```

The password is checked by PAM's `login` service, which exists on every NixOS
system and includes fingerprint login if you've enabled it there. To use a
dedicated service, add `security.pam.services.birdland-tarp = { };` to your
NixOS configuration and set `tarp.pamService = "birdland-tarp";`.

If Tarp crashes while locked, Niri keeps the screens locked (a solid color).
systemd restarts Tarp, which notices and locks again, so you can unlock as
usual. If it doesn't come back, switch to a text console (Ctrl+Alt+F2), log in,
and run `systemctl --user restart tarp`.

______________________________________________________________________

## Gate login screen (NixOS)

Gate is a login screen for [greetd](https://sr.ht/~kennylevinsen/greetd/), shown
by the [cage](https://github.com/cage-kiosk/cage) kiosk compositor, so it
appears on one monitor (the last one connected). Enable it in your NixOS
configuration, not Home Manager:

```nix
{ inputs, ... }: {
  imports = [ inputs.birdland.nixosModules.default ];

  programs.niri.enable = true;      # adds the Niri session to choose from
  programs.birdland.gate = {
    enable = true;
    wallpaper = ./login.jpg;         # copied into the store; optional
  };
}
```

It lists the users with `isNormalUser = true` (showing their `description`) and
the installed Wayland sessions, remembers the last user and session, and has
restart and shut down buttons.

| Option | Type | Default | Description |
| :-------------------------------------- | :----------------- | :------------------------ | :----------------------------------------------------------- |
| `programs.birdland.gate.enable` | boolean | `false` | Enable greetd with the Gate greeter. |
| `programs.birdland.gate.users` | list of strings | all normal users | Users to choose from, in order. |
| `programs.birdland.gate.defaultSession` | string or null | display manager's default | Session selected until someone picks another, e.g. `"niri"`. |
| `programs.birdland.gate.power` | boolean | `true` | Show restart and shut down buttons. |
| `programs.birdland.gate.wallpaper` | path or null | `null` | Image or folder behind the greeter. |
| `programs.birdland.gate.fill` | enum | `"fill"` | How the wallpaper fits the screen. |
| `programs.birdland.gate.theme.scheme` | theme name / attrs | `"birdland"` | Base24 theme, as in Home Manager. |
| `programs.birdland.gate.font.family` | string | `"Inter"` | Font family. |
| `programs.birdland.gate.font.package` | package or null | `pkgs.inter` | Package providing the font. |

______________________________________________________________________

## Theming

Birdland translates [Base24](https://github.com/tinted-theming/base24) color
schemes into QML properties via `base24-themes`. The generated palette is
written to `modules/theme/Base24Colors.qml` at build time, so the Home Manager
module rebuilds each app with your `theme.scheme` and `font.family`.

A custom theme is an attribute set of `base00`–`base17`, each six hex digits
without a leading `#`. Base16 themes work too; the Base24 extension colors fall
back to Base16 ones. See
[base24-themes](https://github.com/chrisppy/base24-themes#defining-your-own-theme)
for the format.

## Development

The dev shell can run any app straight from the checkout, and Quickshell reloads
it as you edit:

```sh
just dev                               # enter the dev shell
qs -p apps/bullpen                     # run an app
BULLPEN_POSITION=left qs -p apps/bullpen
BULLPEN_LEFT=clock BULLPEN_CENTER=workspaces BULLPEN_RIGHT=cpu,volume qs -p apps/bullpen
BULLPEN_WEATHER_LOCATION=39.28,-76.62 qs -p apps/bullpen
LINEUP_FAVORITES=firefox,foot qs -p apps/lineup
OUTFIELD_WALLPAPER=~/Pictures/Wallpapers OUTFIELD_INTERVAL=1 qs -p apps/outfield
qs -p apps/tarp &  qs -p apps/tarp ipc call tarp lock   # your password unlocks it
```

Gate needs greetd to log in; run outside it, it shows a warning and the screen.

Entering the shell generates the default theme into
`modules/theme/Base24Colors.qml` (gitignored) and puts the repo root on
`QML2_IMPORT_PATH`, so `import modules.theme` resolves.

## License

This project is licensed under the **GPL-3.0-only** license. See the
[LICENSE](./LICENSE) file for details.
