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
    defaultSession = "niri";         # preselected; the first session otherwise
    wallpaper = ./login.jpg;         # copied into the store; optional
  };
}
```

At boot, greetd starts cage as the `greeter` user, and cage shows Gate. When you
log in, Gate hands greetd the session's command (`niri-session` for Niri, from
its `.desktop` file) and exits. cage exits with it, and greetd starts Niri as
you.

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

### Setting up greetd yourself

The module above is the easy route. To wire greetd, cage and Gate together
yourself, give Gate a JSON settings file through `GATE_CONFIG` and have greetd
run it inside cage. On NixOS, without the module:

```nix
{ config, inputs, lib, pkgs, ... }:
let
  gate = inputs.birdland.packages.${pkgs.stdenv.hostPlatform.system}.gate;
  gateConfig = pkgs.writeText "gate.json" (builtins.toJSON {
    users = [ { name = "chris"; realName = "Chris Palmer"; } ];
    # Every installed Wayland session, Niri's included
    sessionsDir = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
    defaultSession = "niri";
    statePath = "/var/lib/birdland-gate/state.json";
  });
in
{
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    # cage: -s allows switching virtual terminals, -m last uses one monitor
    settings.default_session.command =
      "${pkgs.coreutils}/bin/env GATE_CONFIG=${gateConfig} XDG_CACHE_HOME=/var/cache/birdland-gate ${lib.getExe pkgs.cage} -s -m last -- ${lib.getExe gate}";
  };

  fonts.packages = [ pkgs.nerd-fonts.symbols-only ];  # Gate's icons
  # Gate remembers the last user and session here; Qt keeps its cache here
  systemd.tmpfiles.rules = [
    "d /var/lib/birdland-gate 0750 greeter greeter - -"
    "d /var/cache/birdland-gate 0750 greeter greeter - -"
  ];
}
```

On other distributions, the same in `/etc/greetd/config.toml`, with Gate
installed somewhere the `greeter` user can run it:

```toml
[terminal]
vt = 1

[default_session]
command = "env GATE_CONFIG=/etc/greetd/gate.json XDG_CACHE_HOME=/var/cache/birdland-gate cage -s -m last -- /usr/local/bin/birdland-gate"
user = "greeter"
```

and `/etc/greetd/gate.json`, readable by `greeter`. Create
`/var/lib/birdland-gate` and `/var/cache/birdland-gate`, owned by `greeter`:

```json
{
  "users": [{ "name": "chris", "realName": "Chris Palmer" }],
  "sessionsDir": "/usr/share/wayland-sessions",
  "defaultSession": "niri",
  "statePath": "/var/lib/birdland-gate/state.json"
}
```

Gate's settings: `users` (each `name`, optional `realName`), `sessionsDir` (a
folder of Wayland session `.desktop` files), `defaultSession` (one of those
files' names without `.desktop`), `statePath` (where the last user and session
are remembered), `power` (`false` hides restart and shut down), and `wallpaper`
and `fill`.
