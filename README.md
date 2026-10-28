# Birdland

A modular, highly customizable desktop shell suite built with
[Quickshell](https://github.com/outfoxxed/quickshell) and managed entirely
through Nix Flakes and Home Manager. Designed with native support for the
[Niri](https://github.com/YaLTeR/niri) compositor and dynamically themed via
[base24-themes](https://github.com/chrisppy/base24-themes).

## Components

Birdland is split into three core Quickshell applications, which can be used
individually or as a complete suite:

- **`bullpen`**: A flexible status bar attachable to any screen edge (`top`,
  `bottom`, `left`, `right`), with workspaces, the focused window, a clock, and
  status indicators for CPU, memory, GPU, temperature, weather, network, volume,
  microphone and battery.
- **`dugout`**: A quick application launcher.
- **`lineup`**: A customizable favorite apps dock for launching and managing
  pinned applications.

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
  };
}
```

______________________________________________________________________

## Configuration Options

| Option | Type | Default | Description |
| :----------------------------------- | :----------------- | :----------- | :----------------------------------------------------------------- |
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

______________________________________________________________________

## Bullpen layout

`bullpen.layout` sets what goes in the left, center and right parts of the bar,
and in what order. On side bars, left is the top and right the bottom. Any
module can go in any part, a part can be empty (`[ ]`), and a module left out of
all three isn't shown.

The center stays centered on the bar. A long window title is shortened with
"…" to fit; outside the center it is capped at a quarter of the bar. The
workspaces pill stays flush against the screen edge wherever it is placed.

| Module | Shows | Needs |
| :-------------- | :------------------------------------------- | :--------------------------------------------------------------------- |
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
```

Entering the shell generates the default theme into
`modules/theme/Base24Colors.qml` (gitignored) and puts the repo root on
`QML2_IMPORT_PATH`, so `import modules.theme` resolves.

## License

This project is licensed under the **GPL-3.0-only** license. See the
[LICENSE](./LICENSE) file for details.
