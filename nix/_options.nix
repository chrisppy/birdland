# SPDX-License-Identifier: GPL-3.0-only
# Options and helpers shared by the Home Manager and NixOS modules. The leading
# underscore keeps import-tree from loading this file as a flake module.
{ lib, base24 }:
let
  inherit (lib) mkOption types;
in
{
  # Base24 theme: a bundled theme's name, or an attrset of colors.
  theme.scheme = mkOption {
    type = types.either (types.enum (builtins.attrNames base24.themes)) (types.attrsOf types.str);
    default = "birdland";
    description = ''
      Name of a theme bundled with base24-themes, or a custom Base16/Base24
      theme: an attrset of base00–base17 as six hex digits without "#".
    '';
  };

  font = pkgs: {
    family = mkOption {
      type = types.str;
      default = "Inter";
      description = "Font family.";
    };
    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.inter;
      defaultText = lib.literalExpression "pkgs.inter";
      description = "Package providing the font.";
    };
  };

  # The theme attrset for a theme.scheme value.
  resolveTheme = scheme: if builtins.isString scheme then base24.themes.${scheme} else scheme;

  # A screen edge, for bars and docks.
  edge =
    default: description:
    mkOption {
      type = types.enum [
        "top"
        "bottom"
        "left"
        "right"
      ];
      inherit default description;
    };

  # How a wallpaper fits the screen.
  fill =
    args:
    mkOption (
      {
        type = types.enum [
          "fill"
          "fit"
          "stretch"
          "center"
          "tile"
        ];
        default = "fill";
        description = "How the wallpaper fits the screen: fill crops to cover it, fit shows all of the image.";
      }
      // args
    );
}
