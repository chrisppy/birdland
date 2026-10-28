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
        theme =
          if builtins.isString cfg.theme.scheme then base24.themes.${cfg.theme.scheme} else cfg.theme.scheme;

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
        ];

        apps = {
          bullpen = {
            description = "Bullpen Status Bar for Niri";
            extraOptions = {
              position = lib.mkOption {
                type = lib.types.enum [
                  "top"
                  "bottom"
                  "left"
                  "right"
                ];
                default = "top";
                description = "Screen edge the Bullpen bar is attached to.";
              };
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
                    "cpu"
                    "memory"
                    "gpu"
                    "temperature"
                    "weather"
                    "network"
                    "volume"
                    "microphone"
                    "battery"
                    "clock"
                  ];
                  description = ''
                    Modules in the right part of the bar (the bottom on side bars), in
                    order. Modules with nothing to show (no battery, no GPU sensor, no
                    weather location) hide themselves.
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
            };
            # Icon glyphs for the status indicators.
            packages = [ pkgs.nerd-fonts.symbols-only ];
            sessionVariables = {
              BULLPEN_POSITION = cfg.bullpen.position;
              BULLPEN_LEFT = lib.concatStringsSep "," cfg.bullpen.layout.left;
              BULLPEN_CENTER = lib.concatStringsSep "," cfg.bullpen.layout.center;
              BULLPEN_RIGHT = lib.concatStringsSep "," cfg.bullpen.layout.right;
              BULLPEN_UNITS = cfg.bullpen.units;
            }
            // lib.optionalAttrs (cfg.bullpen.weather.latitude != null && cfg.bullpen.weather.longitude != null) {
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
              position = lib.mkOption {
                type = lib.types.enum [
                  "top"
                  "bottom"
                  "left"
                  "right"
                ];
                default = "bottom";
                description = "Screen edge the Lineup dock is attached to.";
              };
            };
            sessionVariables = {
              LINEUP_POSITION = cfg.lineup.position;
              LINEUP_FAVORITES = lib.concatStringsSep "," cfg.lineup.favorites;
            };
          };
        };

        enabledApps = lib.filterAttrs (name: _: cfg.${name}.enable) apps;
      in
      {
        options.programs.birdland = {
          enable = lib.mkEnableOption "Birdland Quickshell Suite";
          systemd.enable = lib.mkEnableOption "systemd user services for Birdland apps";

          theme = {
            scheme = lib.mkOption {
              type = lib.types.either (lib.types.enum (builtins.attrNames base24.themes)) (
                lib.types.attrsOf lib.types.str
              );
              default = "birdland";
              description = ''
                Name of a theme bundled with base24-themes, or a custom Base16/Base24
                theme: an attrset of base00–base17 as six hex digits without "#".
              '';
            };
          };

          font = {
            family = lib.mkOption {
              type = lib.types.str;
              default = "Inter";
              description = "Default font family for Birdland apps.";
            };
            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = pkgs.inter;
              description = "Nix package for the font.";
            };
          };
        }
        // lib.mapAttrs (
          _: app:
          {
            enable = lib.mkEnableOption app.description;
          }
          // app.extraOptions
        ) apps;

        config = lib.mkIf cfg.enable {
          home = {
            packages =
              (map appPackage (lib.attrNames enabledApps))
              ++ lib.concatMap (app: app.packages or [ ]) (lib.attrValues enabledApps)
              ++ (lib.optional (cfg.font.package != null) cfg.font.package);

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
                };
                Service = {
                  ExecStart = lib.getExe (appPackage name);
                  Environment = lib.mapAttrsToList (var: value: "${var}=${value}") app.sessionVariables;
                  Restart = "always";
                };
                Install.WantedBy = [ "graphical-session.target" ];
              }
            ) enabledApps
          );
        };
      };
  };
}
