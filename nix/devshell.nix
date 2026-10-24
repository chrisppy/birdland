# SPDX-License-Identifier: GPL-3.0-only
{ inputs, ... }: {
  perSystem = { pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        inputs.quickshell.packages.${system}.default
        inputs.qml-niri.packages.${system}.default
        qt6.qtdeclarative
        qt6.qtbase
        niri
      ];
      shellHook = ''
        echo "⚾ Birdland Development Environment Loaded!"
      '';
    };
  };
}
