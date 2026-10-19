# SPDX-License-Identifier: GPL-3.0-only
{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:

    let
      shellPackage = import ./_mk-shell.nix {
        inherit pkgs;

        quickshell = inputs.qml-niri.packages.${system}.quickshell;
        base24Themes = inputs.base24-themes;
      };
    in
    {
      packages = {
        shell = shellPackage;
        default = shellPackage;
      };
    };
}
