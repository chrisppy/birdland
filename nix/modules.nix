# SPDX-License-Identifier: GPL-3.0-only
{ self, inputs, ... }: {
  flake = {
    homeManagerModules.default =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.programs.birdland;
        system = pkgs.stdenv.hostPlatform.system;
        birdlandPkgs = self.packages.${system};

        base24 = inputs.base24-themes.lib.base24;
        shared = import ./_options.nix { inherit lib base24; };
        theme = shared.resolveTheme cfg.theme.scheme;

        # The theme and font are baked into each app at build time.
        appPackage =
          name:
          birdlandPkgs.${name}.override {
            inherit theme;
            fontFamily = cfg.font.family;
          };

        bullpenModule = lib.types.enum [
          "workspaces"
          "title"
          "clock"
          "cpu"
          "memory"
          "gpu"
          "temperature"
          "weather"
          "network"
          "volume"
          "microphone"
          "battery"
          "tray"
          "media"
          "feeds"
        ];

        # A wallpaper image or folder: a Nix path (copied into the store) or a
        # string such as "~/Pictures/Wallpapers" (used where it is).
        wallpaperSource = lib.types.either lib.types.path lib.types.str;
        sourceString = source: if builtins.isPath source then "${source}" else source;

        apps = {
          bullpen = {
            description = "Bullpen Status Bar for Niri";
            extraOptions = {
              position = shared.edge "top" "Screen edge the Bullpen bar is attached to.";
              layout = {
                left = lib.mkOption {
                  type = lib.types.listOf bullpenModule;
                  default = [ "workspaces" ];
                  description = "Modules in the left part of the bar (the top on side bars), in order.";
                };
                center = lib.mkOption {
                  type = lib.types.listOf bullpenModule;
                  default = [ "title" ];
                  description = "Modules in the center of the bar, in order.";
                };
                right = lib.mkOption {
                  type = lib.types.listOf bullpenModule;
                  default = [
                    "tray"
                    "clock"
                  ];
                  description = ''
                    Modules in the right part of the bar (the bottom on side bars), in
                    order. Modules with nothing to show (no battery, no GPU sensor, no
                    weather location, no media player, no tray icons) hide themselves.
                  '';
                };
              };
              clock = {
                format = lib.mkOption {
                  type = lib.types.str;
                  default = "hh:mm dd MMM, yyyy";
                  example = "h:mm AP  ddd MMM d";
                  description = ''
                    Clock on top/bottom bars, in Qt's date format
                    (<https://doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method>):
                    `h:mm AP` is 12-hour time, `ddd MMM d` a US-style date.
                  '';
                };
                verticalFormat = lib.mkOption {
                  type = lib.types.str;
                  default = "hh\nmm\n\ndd\nMMM";
                  example = "h\nmm\nAP\n\nMMM\nd";
                  description = ''
                    Clock on side bars, stacked: each line break (a newline, or `\n`)
                    starts a new line.
                  '';
                };
              };
              units = lib.mkOption {
                type = lib.types.enum [
                  "metric"
                  "imperial"
                ];
                default = "metric";
                description = "Show temperatures in °C (metric) or °F (imperial).";
              };
              weather = {
                latitude = lib.mkOption {
                  type = lib.types.nullOr lib.types.number;
                  default = null;
                  example = 39.28;
                  description = "Latitude for the weather indicator, which is hidden until both coordinates are set.";
                };
                longitude = lib.mkOption {
                  type = lib.types.nullOr lib.types.number;
                  default = null;
                  example = -76.62;
                  description = "Longitude for the weather indicator.";
                };
              };
              feeds = {
                command = lib.mkOption {
                  type = lib.types.str;
                  default = "xdg-terminal-exec pressbox";
                  example = "foot pressbox";
                  description = ''
                    Shell command run by clicking the feeds indicator. The default
                    opens pressbox in your default terminal.
                  '';
                };
                interval = lib.mkOption {
                  type = lib.types.ints.between 30 3600;
                  default = 120;
                  description = "Seconds between unread-count checks.";
                };
                notifications = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Send a notification when new feed items arrive.";
                };
              };
            };
            sessionVariables = {
              BULLPEN_POSITION = cfg.bullpen.position;
              BULLPEN_LEFT = lib.concatStringsSep "," cfg.bullpen.layout.left;
              BULLPEN_CENTER = lib.concatStringsSep "," cfg.bullpen.layout.center;
              BULLPEN_RIGHT = lib.concatStringsSep "," cfg.bullpen.layout.right;
              BULLPEN_UNITS = cfg.bullpen.units;
              BULLPEN_CLOCK_FORMAT = cfg.bullpen.clock.format;
              BULLPEN_FEEDS_COMMAND = cfg.bullpen.feeds.command;
              BULLPEN_FEEDS_INTERVAL = toString cfg.bullpen.feeds.interval;
              BULLPEN_FEEDS_NOTIFICATIONS = lib.boolToString cfg.bullpen.feeds.notifications;
              # Line breaks as "\n", which the bar reads as line breaks.
              BULLPEN_CLOCK_VERTICAL_FORMAT =
                lib.replaceStrings [ "\n" ] [ "\\n" ]
                  cfg.bullpen.clock.verticalFormat;
            }
            //
              lib.optionalAttrs (cfg.bullpen.weather.latitude != null && cfg.bullpen.weather.longitude != null)
                {
                  BULLPEN_WEATHER_LOCATION = "${toString cfg.bullpen.weather.latitude},${toString cfg.bullpen.weather.longitude}";
                };
          };
          dugout = {
            description = "Dugout App Launcher for Niri";
            extraOptions = { };
            sessionVariables = { };
          };
          lineup = {
            description = "Lineup Favorite Apps Dock for Niri";
            extraOptions = {
              favorites = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [
                  "firefox"
                  "foot"
                ];
                description = "Desktop entry IDs of the apps to show, in order.";
              };
              position = shared.edge "bottom" "Screen edge the Lineup dock is attached to.";
            };
            sessionVariables = {
              LINEUP_POSITION = cfg.lineup.position;
              LINEUP_FAVORITES = lib.concatStringsSep "," cfg.lineup.favorites;
            };
          };
          outfield = {
            description = "Outfield Wallpapers for Niri";
            extraOptions = {
              wallpaper = lib.mkOption {
                type = lib.types.nullOr wallpaperSource;
                default = null;
                example = "~/Pictures/Wallpapers";
                description = ''
                  Image, or folder of images, for every monitor. A folder rotates
                  every `interval` minutes. Without one, monitors show the theme's
                  background color.
                '';
              };
              outputs = lib.mkOption {
                type = lib.types.attrsOf wallpaperSource;
                default = { };
                example = {
                  "DP-1" = "~/Pictures/Ultrawide";
                };
                description = "Per-monitor images or folders, by output name (see `niri msg outputs`).";
              };
              interval = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 30;
                description = "Minutes between images from a folder; 0 keeps the first one.";
              };
              shuffle = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Pick images from a folder at random instead of in file-name order.";
              };
              fill = shared.fill { };
            };
            # One JSON file rather than variables: paths and the per-monitor map
            # can hold spaces and quotes, which systemd's Environment= would mangle.
            sessionVariables = {
              OUTFIELD_CONFIG = "${pkgs.writeText "outfield.json" (
                builtins.toJSON {
                  wallpaper = if cfg.outfield.wallpaper == null then null else sourceString cfg.outfield.wallpaper;
                  outputs = lib.mapAttrs (_: sourceString) cfg.outfield.outputs;
                  inherit (cfg.outfield) interval shuffle fill;
                }
              )}";
            };
          };
          scoreboard = {
            description = "Scoreboard Notification Popups for Niri";
            extraOptions = {
              position = lib.mkOption {
                type = lib.types.enum [
                  "top-right"
                  "top-left"
                  "bottom-right"
                  "bottom-left"
                ];
                default = "top-right";
                description = "Corner of the focused monitor the popups show in.";
              };
              timeout = lib.mkOption {
                type = lib.types.ints.positive;
                default = 5;
                description = "Seconds a popup stays, for apps that don't choose; critical ones stay until dismissed.";
              };
            };
            sessionVariables = {
              SCOREBOARD_POSITION = cfg.scoreboard.position;
              SCOREBOARD_TIMEOUT = toString cfg.scoreboard.timeout;
            };
          };
          jumbotron = {
            description = "Jumbotron Volume and Brightness Pop-ups for Niri";
            extraOptions = {
              position = shared.edge "bottom" "Screen edge the pop-up shows near.";
            };
            sessionVariables = {
              JUMBOTRON_POSITION = cfg.jumbotron.position;
            };
          };
          tarp = {
            description = "Tarp Lock Screen for Niri";
            extraOptions = {
              lockAfter = lib.mkOption {
                type = lib.types.nullOr lib.types.ints.positive;
                default = 10;
                description = "Lock after this many minutes without input; null never locks on idle.";
              };
              screenOffAfter = lib.mkOption {
                type = lib.types.nullOr lib.types.ints.positive;
                default = 15;
                description = ''
                  Turn the monitors off after this many minutes without input (any input
                  turns them back on); null leaves them on. Part of the swayidle setup.
                '';
              };
              swayidle = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Configure services.swayidle to lock after `lockAfter` minutes, before
                  sleep and on `loginctl lock-session`. Turn off to set up idle handling
                  yourself; lock with `birdland-tarp ipc call tarp lock`.
                '';
              };
              pamService = lib.mkOption {
                type = lib.types.str;
                default = "login";
                description = ''
                  PAM service (a file in /etc/pam.d) that checks the password. "login"
                  exists on every NixOS system; for a dedicated one, add
                  `security.pam.services.<name> = { };` to your NixOS configuration.
                '';
              };
              wallpaper = lib.mkOption {
                type = lib.types.nullOr wallpaperSource;
                default = null;
                description = "Image or folder behind the lock screen; null uses outfield's wallpaper, if any.";
              };
              fill = shared.fill {
                default = cfg.outfield.fill;
                defaultText = lib.literalExpression "config.programs.birdland.outfield.fill";
              };
            };
            # A lock screen that stays down leaves the session locked with no way
            # in, so keep restarting it; the new one locks again and can unlock.
            unit.StartLimitIntervalSec = 0;
            service.RestartSec = 1;
            sessionVariables = {
              TARP_CONFIG = "${pkgs.writeText "tarp.json" (
                builtins.toJSON {
                  wallpaper =
                    if cfg.tarp.wallpaper != null then
                      sourceString cfg.tarp.wallpaper
                    else if cfg.outfield.enable && cfg.outfield.wallpaper != null then
                      sourceString cfg.outfield.wallpaper
                    else
                      null;
                  inherit (cfg.tarp) pamService fill;
                }
              )}";
            };
          };
        };

        # One Environment= assignment, quoted so spaces (the clock format),
        # quotes, backslashes, "%" and line breaks reach the app unchanged.
        systemdQuote =
          assignment:
          let
            escaped = lib.replaceStrings [ "\\" "\"" "%" "\n" ] [ "\\\\" "\\\"" "%%" "\\n" ] assignment;
          in
          "\"${escaped}\"";
        serviceEnvironment = lib.mapAttrsToList (var: value: systemdQuote "${var}=${value}");

        # Another notification daemon would hold the D-Bus name scoreboard needs.
        otherNotifier = config.services.mako.enable || config.services.dunst.enable;

        enabledApps = lib.filterAttrs (name: _: cfg.${name}.enable) apps;

        # Locks through the running tarp, then waits until the compositor
        # confirms every monitor is covered: swayidle runs this before sleep
        # and holds the suspend until it exits, so the desktop never shows on
        # resume.
        tarpLock = pkgs.writeShellScript "birdland-tarp-lock" ''
          tarp=${lib.getExe (appPackage "tarp")}
          "$tarp" ipc call tarp lock
          for _ in {1..50}; do
            [ "$("$tarp" ipc call tarp isSecure)" = true ] && exit 0
            ${pkgs.coreutils}/bin/sleep 0.1
          done
          echo "birdland-tarp-lock: the lock screen did not confirm the lock" >&2
          exit 1
        '';
      in
      {
        # Scoreboard was called Pressbox until 2026-11-07; the old option names
        # still work, with a warning. Remove these aliases after 2027-02-07.
        imports =
          map
            (
              option:
              lib.mkRenamedOptionModule
                [ "programs" "birdland" "pressbox" option ]
                [ "programs" "birdland" "scoreboard" option ]
            )
            [
              "enable"
              "position"
              "timeout"
            ];

        options.programs.birdland = {
          enable = lib.mkEnableOption "Birdland Quickshell Suite";
          systemd.enable = lib.mkEnableOption "systemd user services for Birdland apps";

          theme = { inherit (shared.theme) scheme; };
          font = shared.font pkgs;
        }
        // lib.mapAttrs (
          _: app:
          {
            enable = lib.mkEnableOption app.description;
          }
          // app.extraOptions
        ) apps;

        config = lib.mkIf cfg.enable {
          warnings =
            lib.optional (cfg.tarp.enable && !cfg.systemd.enable) ''
              programs.birdland.tarp locks the screen only while it is running. Enable
              programs.birdland.systemd.enable, or start birdland-tarp with your session.
            ''
            ++ lib.optional (cfg.scoreboard.enable && otherNotifier) ''
              programs.birdland.scoreboard and services.mako or services.dunst are both
              notification servers, and only one can run; disable one of them.
            '';

          # Lock after inactivity, before sleep and on `loginctl lock-session`.
          services.swayidle = lib.mkIf (cfg.tarp.enable && cfg.tarp.swayidle) {
            enable = true;
            events = {
              before-sleep = lib.mkDefault "${tarpLock}";
              lock = lib.mkDefault "${tarpLock}";
            };
            timeouts =
              lib.optional (cfg.tarp.lockAfter != null) {
                timeout = cfg.tarp.lockAfter * 60;
                command = "${tarpLock}";
              }
              ++ lib.optional (cfg.tarp.screenOffAfter != null) {
                timeout = cfg.tarp.screenOffAfter * 60;
                command = "${lib.getExe (appPackage "tarp")} ipc call tarp screenOff";
              };
          };

          home = {
            packages =
              (map appPackage (lib.attrNames enabledApps))
              # Icon glyphs: bullpen's indicators, and tarp's and the shared
              # controls' buttons.
              ++ [ pkgs.nerd-fonts.symbols-only ]
              ++ (lib.optional (cfg.font.package != null) cfg.font.package)
              # The feeds indicator's default click opens the default terminal.
              ++ (lib.optional (
                cfg.bullpen.enable
                && lib.elem "feeds" (with cfg.bullpen.layout; left ++ center ++ right)
                && lib.hasPrefix "xdg-terminal-exec " cfg.bullpen.feeds.command
              ) pkgs.xdg-terminal-exec);

            sessionVariables = lib.foldl' (acc: app: acc // app.sessionVariables) { } (
              lib.attrValues enabledApps
            );
          };

          fonts.fontconfig.enable = true;

          systemd.user.services = lib.mkIf cfg.systemd.enable (
            lib.mapAttrs' (
              name: app:
              lib.nameValuePair name {
                Unit = {
                  Description = app.description;
                  PartOf = [ "graphical-session.target" ];
                  After = [ "graphical-session.target" ];
                  # Wayland apps; skip them outside a Wayland session.
                  ConditionEnvironment = "WAYLAND_DISPLAY";
                }
                // app.unit or { };
                Service = {
                  ExecStart = lib.getExe (appPackage name);
                  Environment = serviceEnvironment app.sessionVariables;
                  Restart = "always";
                  # systemd gives up after 5 starts in 10 s. Waiting 3 s between
                  # tries stays under that, so an app that starts before the
                  # compositor is ready keeps retrying instead of staying down.
                  RestartSec = 3;
                }
                // app.service or { };
                Install.WantedBy = [ "graphical-session.target" ];
              }
            ) enabledApps
          );
        };
      };
  };
}
