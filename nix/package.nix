{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  bash,
  coreutils,
  dbus,
  procps,
  cliphist,
  wl-clipboard,
  brightnessctl,
  xdg-utils,
  python3,
  openconnect,
  networkmanager,
  systemd,
  writeText,
  inter,
  nerd-fonts,
  # Run the QML from this directory instead of the store copy, e.g. a git
  # checkout, to keep hot reload. Settings are shared either way (ShellId).
  configDir ? null,
  # Wallpaper shown until one is picked in the shell (YUKI_WALLPAPER).
  wallpaper ? null,
}:

let
  # Tools the QML runs (Process, execDetached).
  runtimeInputs = [
    bash
    coreutils
    dbus
    procps
    cliphist
    wl-clipboard
    brightnessctl
    xdg-utils
    python3
    openconnect
    networkmanager
    systemd
  ];
  runtimePath = lib.makeBinPath runtimeInputs;

  # The fonts the QML names (Theme.font, Icon), so the shell renders without
  # anything installed system-wide. Includes the system config first, so user
  # and system fonts (emoji, CJK in notifications) keep working. Apps the
  # shell launches inherit it; they only gain these two families.
  fonts = [
    inter
    nerd-fonts.jetbrains-mono
  ];
  fontsConf = writeText "yuki-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
    ${
      lib.concatMapStrings (f: "  <dir>${f}/share/fonts</dir>\n") fonts
    }  <cachedir prefix="xdg">fontconfig</cachedir>
    </fontconfig>
  '';
  # --set-default: a FONTCONFIG_FILE / YUKI_WALLPAPER the user already set wins.
  wrapperFlags =
    "--prefix PATH : ${runtimePath} --set-default FONTCONFIG_FILE ${fontsConf}"
    + lib.optionalString (
      wallpaper != null
    ) " --set-default YUKI_WALLPAPER ${lib.escapeShellArg "${wallpaper}"}";

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
  pname = "yuki";
  version = "0.1.0";
  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/yuki $out/bin
    cp -r . $out/share/yuki

    ${
      if configDir == null then
        ''
          # `yuki` starts it; `yuki ipc call <target> <fn>` talks to it.
          makeWrapper ${lib.getExe' quickshell "qs"} $out/bin/yuki \
            --add-flags "-p $out/share/yuki" \
            ${wrapperFlags}
        ''
      else
        ''
          # Prefer the checkout (hot reload), but don't break machines that
          # don't have it: fall back to the packaged copy.
          mkdir -p $out/libexec
          cat > $out/libexec/yuki <<'EOF'
          #!${lib.getExe bash}
          dir=${lib.escapeShellArg configDir}
          # A system-wide package can't know the home directory; expand ~ here.
          case $dir in "~" | "~/"*) dir=$HOME''${dir#\~} ;; esac
          if [ ! -f "$dir/shell.qml" ]; then
            echo "yuki: no shell.qml in $dir, using the packaged copy" >&2
            dir=@out@/share/yuki
          fi
          exec ${lib.getExe' quickshell "qs"} -p "$dir" "$@"
          EOF
          substituteInPlace $out/libexec/yuki --replace-fail @out@ $out
          chmod +x $out/libexec/yuki
          makeWrapper $out/libexec/yuki $out/bin/yuki ${wrapperFlags}
        ''
    }

    runHook postInstall
  '';

  # For wrappers that run quickshell themselves (wrapperModules.yuki):
  # the QML directory, the tools it expects on PATH and its fontconfig file.
  passthru = {
    qml = src;
    inherit runtimeInputs fonts fontsConf;
  };

  meta = {
    license = lib.licenses.asl20;
    description = "yuki: Quickshell desktop shell for niri";
    platforms = lib.platforms.linux;
    mainProgram = "yuki";
  };
}
