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

        base24Lib = inputs.base24-themes.lib.${system} or inputs.base24-themes.lib;
        resolvedScheme =
          if builtins.isString cfg.theme.scheme then
            inputs.base24-themes.themes.${cfg.theme.scheme}
          else
            cfg.theme.scheme;

        qmlThemeText = base24Lib.toQml resolvedScheme;

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
              type = lib.types.either lib.types.str lib.types.attrs;
              default = "birdland";
              description = "Base24 color scheme name or custom attribute set.";
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
              (map (name: birdlandPkgs.${name}) (lib.attrNames enabledApps))
              ++ (lib.optional (cfg.font.package != null) cfg.font.package);

            sessionVariables = lib.foldl' (acc: app: acc // app.sessionVariables) { } (
              lib.attrValues enabledApps
            );
          };

          fonts.fontconfig.enable = true;

          xdg.configFile."birdland/modules/theme/Base24Colors.qml".text = qmlThemeText;

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
                  ExecStart = lib.getExe' birdlandPkgs.${name} "birdland-${name}";
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
