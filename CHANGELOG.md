# Changelog

All notable changes to Birdland are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Birdland has no tagged releases yet, so changes are grouped by date under
Unreleased. Routine flake input updates and formatting commits are left out.

## Unreleased

### 2026-11-11

#### Added

- bullpen: a `dnd` module showing Announcer's do not disturb; click to switch
  it.
- bullpen: an `idle-inhibitor` module; click to keep the session from idling (no
  lock or screen off on idle). Also over IPC:
  `birdland-bullpen ipc call bullpen toggleIdleInhibitor`.

#### Changed

- announcer: do not disturb is kept in `$XDG_RUNTIME_DIR`, so it survives
  Announcer restarting and Bullpen can show and change it.

### 2026-11-09

#### Added

- lineup: `programs.birdland.lineup.iconSize` (`LINEUP_ICON_SIZE`) sets the
  dock's icon size; slots and the divider scale with it.

#### Fixed

- bullpen: the feeds indicator notices a pressbox token created after the bar
  started, instead of staying hidden until a restart.

### 2026-11-08

#### Added

- bullpen: a separate `date` module (`date.format`, default `dd MMM, yyyy`).
  `clock` now shows only the time (`clock.format`, default `hh:mm`). Both share
  an island by default, so the bar looks the same.

#### Changed

- bullpen: modules float in pill-shaped islands just off the screen edge, and
  the bar loses its background and border. Layout entries joined with `+` (or a
  nested list in Nix) share a pill; an island with nothing to show hides.
- The Birdland logo is licensed under CC-BY-SA-4.0.

### 2026-11-07

#### Added

- bullpen: a `feeds` module showing the unread count from a
  [pressbox](https://github.com/red-oxide/pressbox) server. Click opens
  pressbox, right click refreshes every feed, and new items send a notification.
  Options: `programs.birdland.bullpen.feeds.{command,interval,notifications}`.
- bullpen: a network indicator for systemd-networkd hosts, reading `networkctl`
  and `/proc/net/wireless` when NetworkManager isn't present.
- Birdland logo in the README.

#### Changed

- **Breaking:** the notification app is renamed from Pressbox to Announcer:
  `apps/announcer`, `birdland-announcer`, the `announcer` IPC target and user
  service, `ANNOUNCER_*` variables and `programs.birdland.announcer`. The
  `programs.birdland.pressbox.*` and `programs.birdland.scoreboard.*` aliases
  (from a short-lived Scoreboard name) have been removed.
- bullpen: systemd-networkd polling is shared by all bars, and the CPU
  temperature sensor is read only when a bar shows it.
- dugout: faster search.
- README split into pages under `docs/`.

#### Fixed

- The `Edges` singleton is renamed `ScreenEdges`, since Quickshell's own `Edges`
  type shadowed it. bullpen had been filling the whole screen; lineup and
  jumbotron hit the same lookup.
- bullpen: the workspaces pill is sized from the bar's thickness, so it fits
  side bars.
- `just fmt-check` works with treefmt 2.

### 2026-11-01

#### Added

- pressbox (now [announcer](./docs/announcer.md)): a notification server with
  popups on the focused monitor, action buttons, hover-to-pause, persistent
  critical notifications, and do-not-disturb over IPC.
- [jumbotron](./docs/jumbotron.md): a pop-up on the focused monitor when the
  volume, microphone mute or backlight changes.
- bullpen: `tray` (StatusNotifierItem) and `media` (MPRIS) modules.
- bullpen: `clock.format` and `clock.verticalFormat`, in Qt's date format.
- tarp: `screenOffAfter` (default 15 minutes) turns the monitors off through
  swayidle, plus a `screenOff` IPC call.
- bullpen and lineup run on every monitor; dugout opens on the focused one.
- CI builds every app and caches the Nix store.
- gate docs: setting up greetd with cage and Niri by hand.

#### Changed

- dugout and lineup launch apps through Niri, so each app gets its own systemd
  scope and environment; restarting either service no longer closes the apps
  started from it.
- Weather is fetched once for all bars, and a failed request retries after a
  minute.
- The focused window's title shows only on the bar of the monitor holding it,
  and the title module hides while empty.
- Services wait 3 s between restarts and are skipped outside a Wayland session.
- Shared helpers in `modules/util` (`Env`, `JsonSettings`, `Screens`, `Apps`)
  and shared Nix options for the Home Manager and NixOS modules.
- Nerd Font symbols are installed whenever Birdland is enabled.
- Fewer flake lock nodes: `base24-themes` and `qml-niri` follow devfmt's inputs.

#### Fixed

- lineup: windows are matched to entries the same way running apps are, so apps
  found by heuristic lookup show as running and appear once.
- lineup: opening or closing a window no longer recreates every icon.
- Home Manager: systemd `Environment=` values with spaces, quotes or `%` reach
  the apps intact.

### 2026-10-27 to 2026-10-28

#### Added

- [tarp](./docs/tarp.md) lock screen and [gate](./docs/gate.md) greeter.
- [outfield](./docs/outfield.md) wallpaper app.
- bullpen: configurable left, center and right sections.
- bullpen: status indicators for system, network, audio, battery and weather,
  and Intel GPU usage.

### 2026-10-26

#### Added

- Run apps from the checkout in the dev shell.
- `nix flake check` workflow in CI.

#### Fixed

- Support for the restructured base24-themes library.
- Nix: keep the caller's `QML2_IMPORT_PATH` and narrow app sources.
- bullpen: show rounded corners, elide long titles, tidy layout.

### 2026-10-25

#### Added

- lineup: a dock of favorite apps, also showing running apps that aren't
  favorites.
- bullpen: configurable bar position.
- README.

#### Fixed

- dugout: icons are sized up front.

### 2026-10-24

#### Added

- dugout: a Quickshell application launcher.

### 2026-10-19

- Initial commit.
