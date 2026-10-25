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
        qmlThemeText = base24Lib.toQml cfg.theme.scheme;
      in
      {
        options.programs.birdland = {
          enable = lib.mkEnableOption "Birdland Quickshell Suite";

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

          bullpen = {
            enable = lib.mkEnableOption "Bullpen status bar";
            systemd.enable = lib.mkEnableOption "systemd user service for Bullpen";
            position = lib.mkOption {
              type = lib.types.enum [ "top" "bottom" "left" "right" ];
              default = "top";
              description = "Screen edge the Bullpen bar is attached to.";
            };
          };

          dugout = {
            enable = lib.mkEnableOption "Dugout app launcher";
            systemd.enable = lib.mkEnableOption "systemd user service for Dugout";
          };

          lineup = {
            enable = lib.mkEnableOption "Lineup favorite apps dock";
            systemd.enable = lib.mkEnableOption "systemd user service for Lineup";
            favorites = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "firefox" "foot" ];
              description = "Desktop entry IDs (file name without .desktop) of the apps to show, in order.";
            };
            position = lib.mkOption {
              type = lib.types.enum [ "top" "bottom" "left" "right" ];
              default = "bottom";
              description = "Screen edge the Lineup dock is attached to.";
            };
          };
        };

        config = lib.mkIf cfg.enable {
          home.packages =
            (lib.optional cfg.bullpen.enable birdlandPkgs.bullpen)
            ++ (lib.optional cfg.dugout.enable birdlandPkgs.dugout)
            ++ (lib.optional cfg.lineup.enable birdlandPkgs.lineup)
            ++ (lib.optional (cfg.font.package != null) cfg.font.package);

          fonts.fontconfig.enable = true;

          # Apps read their settings from these variables (see apps/*/).
          home.sessionVariables =
            (lib.optionalAttrs cfg.bullpen.enable {
              BULLPEN_POSITION = cfg.bullpen.position;
            })
            // (lib.optionalAttrs cfg.lineup.enable {
              LINEUP_POSITION = cfg.lineup.position;
              LINEUP_FAVORITES = lib.concatStringsSep "," cfg.lineup.favorites;
            });

          xdg.configFile."birdland/modules/theme/Base24Colors.qml".text = qmlThemeText;

          systemd.user.services.bullpen = lib.mkIf (cfg.bullpen.enable && cfg.bullpen.systemd.enable) {
            Unit = {
              Description = "Bullpen Status Bar for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${birdlandPkgs.bullpen}/bin/birdland-bullpen";
              Environment = [ "BULLPEN_POSITION=${cfg.bullpen.position}" ];
              Restart = "always";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };

          systemd.user.services.dugout = lib.mkIf (cfg.dugout.enable && cfg.dugout.systemd.enable) {
            Unit = {
              Description = "Dugout App Launcher for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${birdlandPkgs.dugout}/bin/birdland-dugout";
              Restart = "always";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };

          systemd.user.services.lineup = lib.mkIf (cfg.lineup.enable && cfg.lineup.systemd.enable) {
            Unit = {
              Description = "Lineup Favorite Apps Dock for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${birdlandPkgs.lineup}/bin/birdland-lineup";
              Environment = [
                "LINEUP_POSITION=${cfg.lineup.position}"
                "LINEUP_FAVORITES=${lib.concatStringsSep "," cfg.lineup.favorites}"
              ];
              Restart = "always";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };
      };
  };
}
