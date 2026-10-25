# SPDX-License-Identifier: GPL-3.0-only
{ inputs, ... }: {
  perSystem =
    { pkgs, system, ... }:
    let
      qsPkg = inputs.quickshell.packages.${system}.default;
      niriPlugin = inputs.qml-niri.packages.${system}.default;
      base24Lib = inputs.base24-themes.lib.base24;
      defaultQmlTheme = base24Lib.toQml inputs.base24-themes.themes.camden;

      mkApp =
        {
          name,
          appDir ? name,
          binName ? "birdland-${name}",
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

            # Inject the generated Base24 theme into modules/theme
            mkdir -p $out/share/birdland/modules/theme
            cat << 'EOF' > $out/share/birdland/modules/theme/Base24Colors.qml
            ${defaultQmlTheme}
            EOF

            mkdir -p $out/bin
            cat <<EOF > $out/bin/${binName}
            #!/usr/bin/env bash
            export QML2_IMPORT_PATH="${niriPlugin}/lib/qt-6/qml:$out/share/birdland''${QML2_IMPORT_PATH:+:\$QML2_IMPORT_PATH}"
            exec ${qsPkg}/bin/quickshell -p "$out/share/birdland/${name}" "\$@"
            EOF
            chmod +x $out/bin/${binName}
          '';
        };
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
