# SPDX-License-Identifier: GPL-3.0-only
{ inputs, ... }:

let
  themes = inputs.base24-themes.themes;
in
{
  flake.nixosModules.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib) mkEnableOption mkOption types;

      cfg = config.programs.shell;

      shellPackage = import ./_mk-shell.nix {
        inherit pkgs;

        quickshell = inputs.qml-niri.packages.${pkgs.system}.quickshell;

        base24Themes = inputs.base24-themes;

        inherit (cfg) theme;
        inherit (cfg) fonts;
      };
    in
    {
      options.programs.shell = {
        enable = mkEnableOption "the Quickshell desktop shell";
        enableUPower = mkEnableOption "Enable the UPower system service for the shell.";

        theme = mkOption {
          type = types.enum (builtins.attrNames themes);
          default = "camden";
          description = "Base24 theme to use.";
        };

        fonts = {
          ui = mkOption {
            type = types.str;
            default = "Barlow Medium";
            description = "UI font family.";
          };

          monospace = mkOption {
            type = types.str;
            default = "FiraCode Nerd Font";
            description = "Monospace font family.";
          };

          size = mkOption {
            type = types.ints.positive;
            default = 12;
            description = "Default font size.";
          };

          smallSize = mkOption {
            type = types.ints.positive;
            default = 10;
            description = "Small font size.";
          };

          largeSize = mkOption {
            type = types.ints.positive;
            default = 14;
            description = "Large font size.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        services.upower.enable = lib.mkIf cfg.enableUPower true;
        environment.systemPackages = [
          shellPackage
        ];
      };
    };
}
