{
  lib,
  stdenvNoCC,
  imagemagick,
  fontconfig,
  nerd-fonts,
  accent ? "#b3c5ff",
  base ? "#121318",
  surface ? "#292a2f",
  text ? "#e3e2e9",
}:

stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-yuki";
  version = "0.1.0";
  src = ../extras/plymouth;

  nativeBuildInputs = [
    imagemagick
    fontconfig
  ];

  installPhase = ''
    runHook preInstall

    dir=$out/share/plymouth/themes/yuki
    mkdir -p $dir
    font=$(find ${nerd-fonts.jetbrains-mono}/share/fonts -name 'JetBrainsMonoNerdFont-Regular.ttf' | head -n1)
    bash ./generate.sh $dir "${accent}" "${base}" "${surface}" "${text}" "$font"
    cp yuki/yuki.script $dir/
    substitute yuki/yuki.plymouth $dir/yuki.plymouth --replace-fail "@THEMEDIR@" "$dir"

    # The script's background color is the theme base.
    sed -i 's|^Window.SetBackgroundTopColor.*|Window.SetBackgroundTopColor(${lib.concatMapStringsSep ", " (x: x) (
      map (i: toString ((lib.fromHexString (builtins.substring i 2 base)) / 255.0)) [ 1 3 5 ]
    )});|' $dir/yuki.script

    runHook postInstall
  '';

  meta = {
    license = lib.licenses.asl20;
    description = "Plymouth boot splash matching yuki";
    platforms = lib.platforms.linux;
  };
}
