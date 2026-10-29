# SPDX-License-Identifier: GPL-3.0-only
{ self, inputs, ... }:
{
  flake.nixosModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.birdland.gate;
      system = pkgs.stdenv.hostPlatform.system;
      base24 = inputs.base24-themes.lib.base24;

      theme = if builtins.isString cfg.theme.scheme then base24.themes.${cfg.theme.scheme} else cfg.theme.scheme;
      gate = self.packages.${system}.gate.override {
        inherit theme;
        fontFamily = cfg.font.family;
      };

      stateDir = "/var/lib/birdland-gate";
      cacheDir = "/var/cache/birdland-gate";

      normalUsers = lib.filterAttrs (_: user: user.isNormalUser) config.users.users;

      settings = pkgs.writeText "gate.json" (
        builtins.toJSON {
          users = map (name: {
            inherit name;
            realName = config.users.users.${name}.description or "";
          }) cfg.users;
          sessionsDir = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
          inherit (cfg) defaultSession power fill;
          statePath = "${stateDir}/state.json";
          wallpaper = if cfg.wallpaper == null then null else "${cfg.wallpaper}";
        }
      );
    in
    {
      options.programs.birdland.gate = {
        enable = lib.mkEnableOption "the Gate greeter, run by greetd inside cage";

        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = lib.sort lib.lessThan (lib.attrNames normalUsers);
          defaultText = lib.literalExpression "all users with isNormalUser = true";
          description = "Users to choose from, in order. Their description is shown as their name.";
        };

        defaultSession = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = config.services.displayManager.sessionData.autologinSession;
          defaultText = lib.literalExpression "services.displayManager.defaultSession, else the first session";
          example = "niri";
          description = "Session (its .desktop file name) selected until someone picks another.";
        };

        power = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show restart and shut down buttons.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = lib.literalExpression "./wallpapers/login.jpg";
          description = ''
            Image or folder behind the greeter. It is copied into the Nix store,
            since the greeter can't read your home directory.
          '';
        };

        fill = lib.mkOption {
          type = lib.types.enum [
            "fill"
            "fit"
            "stretch"
            "center"
            "tile"
          ];
          default = "fill";
          description = "How the wallpaper fits the screen.";
        };

        theme.scheme = lib.mkOption {
          type = lib.types.either (lib.types.enum (builtins.attrNames base24.themes)) (
            lib.types.attrsOf lib.types.str
          );
          default = "birdland";
          description = "Base24 theme name or attrset, as for the Home Manager module.";
        };

        font = {
          family = lib.mkOption {
            type = lib.types.str;
            default = "Inter";
            description = "Font family for the greeter.";
          };
          package = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = pkgs.inter;
            description = "Package providing the font.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.users != [ ];
            message = "programs.birdland.gate: no users to log in as; add a user with isNormalUser = true or set programs.birdland.gate.users.";
          }
        ];

        services.greetd = {
          enable = true;
          # cage shows one window on the last monitor connected; -s allows
          # switching virtual terminals.
          settings.default_session.command = lib.concatStringsSep " " [
            "${pkgs.coreutils}/bin/env"
            "GATE_CONFIG=${settings}"
            "XDG_CACHE_HOME=${cacheDir}"
            "${lib.getExe pkgs.cage} -s -m last --"
            (lib.getExe gate)
          ];
        };

        fonts.packages = [ pkgs.nerd-fonts.symbols-only ] ++ lib.optional (cfg.font.package != null) cfg.font.package;

        # The greeter remembers the last user and session here.
        systemd.tmpfiles.rules = [
          "d ${stateDir} 0750 greeter greeter - -"
          "d ${cacheDir} 0750 greeter greeter - -"
        ];
      };
    };
}
