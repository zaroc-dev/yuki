let
  # A nix-wrapper-modules module (github:nix-community/nix-wrapper-modules),
  # built on its quickshell module. It receives `wlib` from there, so this
  # flake doesn't need it as an input:
  #
  #   inputs.wrappers.lib.wrapPackage [
  #     inputs.yuki.wrapperModules.yuki
  #     { inherit pkgs; }
  #   ]
  module =
    {
      config,
      lib,
      wlib,
      pkgs,
      ...
    }:
    let
      yuki = pkgs.callPackage ../package.nix { };
    in
    {
      imports = [ wlib.wrapperModules.quickshell ];

      options.checkout = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/me/source/yuki";
        description = ''
          Absolute path of a yuki checkout to run instead of the packaged QML,
          for Quickshell's hot reload. Unlike the package's `configDir` there
          is no fallback: the directory must exist. Settings are shared either
          way (`//@ pragma ShellId yuki`).
        '';
      };

      config = {
        # `yuki ipc call …` (keybinds, scripts) talks to the running shell.
        binName = lib.mkDefault "yuki";
        configDir = lib.mkDefault (
          if config.checkout == null then yuki.qml else wlib.mkOutOfStoreSymlink pkgs config.checkout
        );
        runtimePkgs = yuki.runtimeInputs;
        # Inter + JetBrainsMono Nerd Font without installing them system-wide.
        envDefault.FONTCONFIG_FILE = "${yuki.fontsConf}";
        meta.platforms = lib.platforms.linux;
      };
    };
in
{
  flake.wrapperModules = {
    yuki = module;
    default = module;
  };
}
