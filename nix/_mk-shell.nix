# SPDX-License-Identifier: GPL-3.0-only
{
  pkgs,
  quickshell,
  base24Themes,
  theme ? "camden",
  fonts ? {
    ui = "Barlow Medium";
    monospace = "FiraCode Nerd Font";
    size = 12;
    smallSize = 10;
    largeSize = 14;
  },
}:

let
  inherit (pkgs) lib;

  selectedTheme = base24Themes.themes.${theme};

  themeQml = pkgs.writeText "Theme.qml" (base24Themes.lib.base24.toQml selectedTheme);

  fontsQml = pkgs.writeText "Fonts.qml" ''
    pragma Singleton

    import QtQuick

    QtObject {
      readonly property string family: ${builtins.toJSON fonts.ui}
      readonly property string monospace: ${builtins.toJSON fonts.monospace}

      readonly property int size: ${toString fonts.size}
      readonly property int smallSize: ${toString fonts.smallSize}
      readonly property int largeSize: ${toString fonts.largeSize}
    }
  '';

  qmlFiles = pkgs.runCommand "shell-qml" { } ''
    mkdir -p "$out"
    cp -r ${../qml}/. "$out/"
    cp ${themeQml} "$out/Theme.qml"
    cp ${fontsQml} "$out/Fonts.qml"
  '';

  desktopEntry = pkgs.writeText "org.quickshell.desktop" ''
    [Desktop Entry]
    Version=1.5
    Type=Application
    Name=Quickshell
    NoDisplay=true
    Exec=${placeholder "out"}/bin/shell
    Icon=org.quickshell
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "shell";
  version = "0.1.0";

  dontUnpack = true;

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  installPhase = ''
      runHook preInstall

      install -d "$out/bin"
      install -d "$out/share/quickshell/shell"
      install -d "$out/share/applications"
      install -d "$out/share/icons/hicolor/scalable/apps"

      cp -r ${qmlFiles}/. "$out/share/quickshell/shell/"

        install -Dm644 ${desktopEntry} \
    "$out/share/applications/org.quickshell.desktop"

      install -Dm644 \
        ${quickshell}/share/icons/hicolor/scalable/apps/org.quickshell.svg \
        "$out/share/icons/hicolor/scalable/apps/org.quickshell.svg"

      makeWrapper ${lib.getExe quickshell} "$out/bin/shell" \
        --add-flags "--path" \
        --add-flags "$out/share/quickshell/shell/shell.qml"

      runHook postInstall
  '';

  meta = {
    description = "Personal Quickshell desktop shell for Niri";
    platforms = lib.platforms.linux;
    mainProgram = "shell";
  };
}
