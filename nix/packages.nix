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
          # A Base24 theme attrset, e.g. one of base24.themes.
          theme ? base24.themes.birdland,
          fontFamily ? "Sans-Serif",
          # Extra makeWrapper arguments for the app's launcher.
          wrapperArgs ? [ ],
        }:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "birdland-${name}";
          version = "0.1.0";

          # Only this app and the shared modules, so unrelated edits (other
          # apps, README, Nix) don't rebuild it.
          src = lib.fileset.toSource {
            root = ../.;
            fileset = lib.fileset.unions [
              ../modules
              (../apps + "/${name}")
            ];
          };
          dontUnpack = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/share/birdland
            cp -r $src/modules $out/share/birdland/
            cp -r $src/apps/${name} $out/share/birdland/${name}
            chmod -R +w $out/share/birdland

            # Inject the generated Base24 theme and the font into modules/theme
            cp ${pkgs.writeText "Base24Colors.qml" (base24.toQml theme)} \
              $out/share/birdland/modules/theme/Base24Colors.qml
            substituteInPlace $out/share/birdland/modules/theme/Fonts.qml \
              --replace-fail '"Sans-Serif"' ${lib.escapeShellArg (builtins.toJSON fontFamily)}

            makeWrapper ${lib.getExe qsPkg} $out/bin/birdland-${name} \
              --prefix QML2_IMPORT_PATH : ${niriPlugin}/lib/qt-6/qml:$out/share/birdland \
              --add-flags "-p $out/share/birdland/${name}" \
              ${lib.escapeShellArgs wrapperArgs}
          '';

          meta.mainProgram = "birdland-${name}";
        }
      );

      # Qt only reads JPEG, PNG, BMP and GIF by itself; this adds WebP and TIFF
      # for the apps that show wallpapers.
      imageFormats = [
        "--prefix"
        "QT_PLUGIN_PATH"
        ":"
        "${pkgs.qt6.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}"
      ];
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
        outfield = mkApp {
          name = "outfield";
          wrapperArgs = imageFormats;
        };
        # The lock screen; it runs in the background and locks over IPC.
        tarp = mkApp {
          name = "tarp";
          wrapperArgs = imageFormats;
        };
        # The greeter; run by greetd through the NixOS module, not by users.
        gate = mkApp {
          name = "gate";
          wrapperArgs = imageFormats;
        };

        birdland = pkgs.symlinkJoin {
          name = "birdland-suite";
          paths = [
            bullpen
            dugout
            lineup
            outfield
            tarp
          ];
        };

        default = birdland;
      };
    };
}
