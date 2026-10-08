{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  bash,
  coreutils,
  procps,
  cliphist,
  wl-clipboard,
  brightnessctl,
  xdg-utils,
  # Run the QML from this directory instead of the store copy, e.g. a git
  # checkout, to keep hot reload. Settings are shared either way (ShellId).
  configDir ? null,
}:

let
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../shell.qml
      ../bar
      ../components
      ../config
      ../lib
      ../lock
      ../pam
      ../popups
      ../services
      ../settings
      ../wallpaper
    ];
  };
in
stdenvNoCC.mkDerivation {
  pname = "shell";
  version = "0.1.0";
  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/shell $out/bin
    cp -r . $out/share/shell

    # `shell` starts it; `shell ipc call <target> <fn>` talks to it.
    makeWrapper ${lib.getExe' quickshell "qs"} $out/bin/shell \
      --add-flags "-p ${if configDir != null then configDir else "$out/share/shell"}" \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
          procps
          cliphist
          wl-clipboard
          brightnessctl
          xdg-utils
        ]
      }

    runHook postInstall
  '';

  meta = {
    license = lib.licenses.asl20;
    description = "Quickshell desktop shell for niri";
    platforms = lib.platforms.linux;
    mainProgram = "shell";
  };
}
