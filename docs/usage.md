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
      clock.format = "h:mm AP  ddd MMM d"; # 12-hour time, US-style date
      weather = {
        latitude = 39.28;
        longitude = -76.62;
      };
      # What goes where, in order (these are the defaults)
      layout = {
        left = [ "workspaces" ];
        center = [ "title" ];
        # A list is one island: modules sharing a pill
        right = [ "media" [ "cpu" "memory" "gpu" "temperature" ] "weather" [ "network" "volume" "microphone" "battery" ] "tray" "clock" ];
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

    announcer = {
      enable = true;
      position = "top-right";
      timeout = 5; # seconds
    };

    jumbotron = {
      enable = true;
      position = "bottom";
    };

    tarp = {
      enable = true;
      lockAfter = 10;      # minutes without input; null to never lock on idle
      screenOffAfter = 15; # minutes without input; null to leave monitors on
    };
  };
}
```

## Configuration Options

| Option | Type | Default | Description |
| :----------------------------------------------- | :--------------------- | :----------------------------- | :--------------------------------------------------------------------------------------------------------------- |
| `programs.birdland.enable` | boolean | `false` | Enable the Birdland Quickshell suite. |
| `programs.birdland.systemd.enable` | boolean | `false` | Run suite components as user systemd services. |
| `programs.birdland.theme.scheme` | theme name / attrs | `"birdland"` | Bundled base24-themes theme name, or a custom theme attribute set. |
| `programs.birdland.font.family` | string | `"Inter"` | Default font family for the apps. |
| `programs.birdland.font.package` | package | `pkgs.inter` | Nix package for the font. |
| `programs.birdland.bullpen.enable` | boolean | `false` | Enable the Bullpen status bar. |
| `programs.birdland.bullpen.position` | enum | `"top"` | Screen edge (`top`, `bottom`, `left`, `right`). |
| `programs.birdland.bullpen.layout.left` | list of islands | `[ "workspaces" ]` | Left part of the bar (top on side bars), in order. An island is a module, or a list of modules sharing one pill. |
| `programs.birdland.bullpen.layout.center` | list of islands | `[ "title" ]` | Center of the bar, in order. |
| `programs.birdland.bullpen.layout.right` | list of islands | `[ "tray"  "clock" ]` | Right part of the bar (bottom on side bars), in order. |
| `programs.birdland.bullpen.clock.format` | string | `"hh:mm dd MMM, yyyy"` | Clock on top/bottom bars, in [Qt's date format](https://doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method). |
| `programs.birdland.bullpen.clock.verticalFormat` | string | time over date | Clock on side bars; each `\n` starts a new line. |
| `programs.birdland.bullpen.units` | enum | `"metric"` | Temperatures in °C (`metric`) or °F (`imperial`). |
| `programs.birdland.bullpen.weather.latitude` | number or null | `null` | Weather location; the weather is hidden until both are set. |
| `programs.birdland.bullpen.weather.longitude` | number or null | `null` | Weather location. |
| `programs.birdland.bullpen.feeds.command` | string | `"xdg-terminal-exec pressbox"` | Shell command run by clicking the `feeds` indicator. |
| `programs.birdland.bullpen.feeds.interval` | integer | `120` | Seconds between unread-count checks. |
| `programs.birdland.bullpen.feeds.notifications` | boolean | `true` | Notify when new feed items arrive. |
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
| `programs.birdland.announcer.enable` | boolean | `false` | Enable the Announcer notification popups. |
| `programs.birdland.announcer.position` | enum | `"top-right"` | Corner: `top-right`, `top-left`, `bottom-right` or `bottom-left`. |
| `programs.birdland.announcer.timeout` | integer | `5` | Seconds a popup stays when the app doesn't say; critical ones stay. |
| `programs.birdland.jumbotron.enable` | boolean | `false` | Enable the Jumbotron volume and brightness pop-ups. |
| `programs.birdland.jumbotron.position` | enum | `"bottom"` | Screen edge (`top`, `bottom`, `left`, `right`). |
| `programs.birdland.tarp.enable` | boolean | `false` | Enable the Tarp lock screen. Needs `systemd.enable`, or start it yourself. |
| `programs.birdland.tarp.lockAfter` | integer or null | `10` | Minutes without input before locking; `null` never locks on idle. |
| `programs.birdland.tarp.screenOffAfter` | integer or null | `15` | Minutes without input before the monitors turn off; `null` leaves them on. |
| `programs.birdland.tarp.swayidle` | boolean | `true` | Set up swayidle to lock on idle, before sleep and on `loginctl lock-session`. |
| `programs.birdland.tarp.pamService` | string | `"login"` | PAM service that checks the password. |
| `programs.birdland.tarp.wallpaper` | path / string or null | `null` | Image or folder behind the lock; `null` uses Outfield's. |
| `programs.birdland.tarp.fill` | enum | Outfield's | How the wallpaper fits the screen. |
