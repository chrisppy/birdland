# SPDX-License-Identifier: GPL-3.0-only
{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    let
      qsPkg = inputs.quickshell.packages.${system}.default;
      niriPlugin = inputs.qml-niri.packages.${system}.default;
      base24 = inputs.base24-themes.lib.base24;

      # Overridable so the Home Manager module can rebuild an app with the
      # user's theme and font: `bullpen.override { theme = ...; }`.
      mkApp = lib.makeOverridable (
        {
          name,
          appDir ? name,
          binName ? "birdland-${name}",
          # A Base24 theme attrset, e.g. one of base24.themes.
          theme ? base24.themes.birdland,
          fontFamily ? "Sans-Serif",
        }:
        pkgs.stdenv.mkDerivation {
          pname = "birdland-${name}";
          version = "0.1.0";
          src = ../.;

          buildInputs = [
            qsPkg
            niriPlugin
            pkgs.bash
          ];

          installPhase = ''
            mkdir -p $out/share/birdland

            # Copy the entire project structure or required directories to preserve relative paths
            cp -r $src/modules $out/share/birdland/
            if [ -d "$src/apps/${appDir}" ]; then
              cp -r $src/apps/${appDir} $out/share/birdland/${name}
            elif [ -d "$src/${appDir}" ]; then
              cp -r $src/${appDir} $out/share/birdland/${name}
            else
              echo "Error: Could not find source directory for ${appDir}" >&2
              exit 1
            fi

            chmod -R +w $out/share/birdland

            # Inject the generated Base24 theme and the font into modules/theme
            cp ${pkgs.writeText "Base24Colors.qml" (base24.toQml theme)} \
              $out/share/birdland/modules/theme/Base24Colors.qml
            substituteInPlace $out/share/birdland/modules/theme/Fonts.qml \
              --replace-fail '"Sans-Serif"' ${lib.escapeShellArg (builtins.toJSON fontFamily)}

            mkdir -p $out/bin
            cat <<EOF > $out/bin/${binName}
            #!/usr/bin/env bash
            export QML2_IMPORT_PATH="${niriPlugin}/lib/qt-6/qml:$out/share/birdland''${QML2_IMPORT_PATH:+:\$QML2_IMPORT_PATH}"
            exec ${lib.getExe qsPkg} -p "$out/share/birdland/${name}" "\$@"
            EOF
            chmod +x $out/bin/${binName}
          '';
        }
      );
    in
    {
      packages = rec {
        bullpen = mkApp {
          name = "bullpen";
        };
        dugout = mkApp {
          name = "dugout";
        };
        lineup = mkApp {
          name = "lineup";
        };

        birdland = pkgs.symlinkJoin {
          name = "birdland-suite";
          paths = [
            bullpen
            dugout
            lineup
          ];
        };

        default = birdland;
      };
    };
}
