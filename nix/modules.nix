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

        apps = {
          bullpen = {
            enabled = cfg.bullpen.enable;
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
            };
            environment = [ "BULLPEN_POSITION=${cfg.bullpen.position}" ];
            sessionVariables = {
              BULLPEN_POSITION = cfg.bullpen.position;
            };
          };
          dugout = {
            enabled = cfg.dugout.enable;
            description = "Dugout App Launcher for Niri";
            extraOptions = { };
            environment = [ ];
            sessionVariables = { };
          };
          lineup = {
            enabled = cfg.lineup.enable;
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
            environment = [
              "LINEUP_POSITION=${cfg.lineup.position}"
              "LINEUP_FAVORITES=${lib.concatStringsSep "," cfg.lineup.favorites}"
            ];
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
                  Environment = app.environment;
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
