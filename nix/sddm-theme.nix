{
  lib,
  stdenvNoCC,
  # Image blurred behind the login form.
  background ? null,
  # Overrides for theme.conf keys: accent, onAccent, base, crust, surface,
  # text, subtext, muted, error, font, blur.
  settings ? { },
}:

stdenvNoCC.mkDerivation {
  pname = "sddm-theme-yuki";
  version = "0.1.0";
  src = ../extras/sddm/yuki;

  installPhase = ''
    runHook preInstall

    dir=$out/share/sddm/themes/yuki
    mkdir -p $dir
    cp -r . $dir
    ${lib.optionalString (background != null) ''
      cp ${background} $dir/background
      sed -i "s|^background=.*|background=$dir/background|" $dir/theme.conf
    ''}
    ${lib.concatStrings (
      lib.mapAttrsToList (k: v: ''
        sed -i "s|^${k}=.*|${k}=${toString v}|" $dir/theme.conf
      '') settings
    )}

    runHook postInstall
  '';

  meta = {
    license = lib.licenses.asl20;
    description = "SDDM theme matching yuki's lock screen";
    platforms = lib.platforms.linux;
  };
}
