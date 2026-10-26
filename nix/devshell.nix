# SPDX-License-Identifier: GPL-3.0-only
{ inputs, ... }: {
  perSystem =
    { pkgs, system, ... }:
    let
      base24 = inputs.base24-themes.lib.base24;
      niriPlugin = inputs.qml-niri.packages.${system}.default;
      themeQml = pkgs.writeText "Base24Colors.qml" (base24.toQml base24.themes.birdland);
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          inputs.quickshell.packages.${system}.default
          niriPlugin
          qt6.qtdeclarative
          qt6.qtbase
          niri
        ];

        # Make the apps runnable straight from the checkout, e.g.
        # `qs -p apps/bullpen`: generate the theme file the packages normally
        # provide (it is gitignored) and put the repo root on the import path
        # so `import modules.theme` resolves.
        shellHook = ''
          root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
          install -m644 ${themeQml} "$root/modules/theme/Base24Colors.qml"
          export QML2_IMPORT_PATH="${niriPlugin}/lib/qt-6/qml:$root''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
          echo "⚾ Birdland Development Environment Loaded! Run an app with: qs -p apps/<name>"
        '';
      };
    };
}
