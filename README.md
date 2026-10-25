# Birdland

A modular, highly customizable desktop shell suite built with [Quickshell](https://github.com/outfoxxed/quickshell) and managed entirely through Nix Flakes and Home Manager. Designed with native support for the [Niri](https://github.com/sodiboo/niri) compositor and dynamically themed via [base24-themes](https://github.com/chrisppy/base24-themes).

## Components

Birdland is split into three core Quickshell applications, which can be used individually or as a complete suite:

* **`bullpen`**: A flexible status bar attachable to any screen edge (`top`, `bottom`, `left`, `right`).
* **`dugout`**: A quick application launcher.
* **`lineup`**: A customizable favorite apps dock for launching and managing pinned applications.

---

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

---

## Home Manager Module Usage

Import the Home Manager module provided by the flake and enable the suite:

```nix
{ inputs, ... }: {
  imports = [
    inputs.birdland.homeManagerModules.default
  ];

  programs.birdland = {
    enable = true;
    systemd.enable = true; # Manages apps as graphical-session systemd services

    # Choose a Base24 theme name or pass a custom attribute set
    theme.scheme = "birdland"; 

    font = {
      family = "Inter";
      package = pkgs.inter;
    };

    bullpen = {
      enable = true;
      position = "top";
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

---

## Configuration Options

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `programs.birdland.enable` | boolean | `false` | Enable the Birdland Quickshell suite. |
| `programs.birdland.systemd.enable` | boolean | `false` | Run suite components as user systemd services. |
| `programs.birdland.theme.scheme` | string / attrs | `"birdland"` | Base24 color scheme name or custom attribute set. |
| `programs.birdland.font.family` | string | `"Inter"` | Default font family for the apps. |
| `programs.birdland.font.package` | package | `pkgs.inter` | Nix package for the font. |
| `programs.birdland.bullpen.enable` | boolean | `false` | Enable the Bullpen status bar. |
| `programs.birdland.bullpen.position` | enum | `"top"` | Screen edge (`top`, `bottom`, `left`, `right`). |
| `programs.birdland.dugout.enable` | boolean | `false` | Enable the Dugout app launcher. |
| `programs.birdland.lineup.enable` | boolean | `false` | Enable the Lineup favorite apps dock. |
| `programs.birdland.lineup.position` | enum | `"bottom"` | Screen edge (`top`, `bottom`, `left`, `right`). |
| `programs.birdland.lineup.favorites` | list of strings | `[]` | Desktop entry IDs of pinned apps in order. |

---

## Theming

Birdland dynamically translates [Base24](https://github.com/tinted-theming/base24) color schemes into QML properties via `base24-themes`. The generated palette is injected directly into `modules/theme/Base24Colors.qml` during build time.

## License

This project is licensed under the **GPL-3.0-only** license. See the [LICENSE](./LICENSE) file for details.
