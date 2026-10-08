self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.shell;
in
{
  options.programs.shell = {
    enable = lib.mkEnableOption "the Quickshell desktop shell";

    configDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = lib.literalExpression ''"''${config.home.homeDirectory}/source/shell"'';
      description = ''
        Run the QML straight from this directory (e.g. a git checkout) instead
        of the store copy, which keeps Quickshell's hot reload. Settings live in
        ~/.local/state/quickshell/by-shell/shell either way.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.shell.override {
        inherit (cfg) configDir;
      };
      defaultText = lib.literalExpression "shell.packages.\${system}.shell";
      description = "The wrapped shell (`shell`, `shell ipc call …`).";
    };

    systemd.enable = lib.mkEnableOption ''
      a systemd user service bound to graphical-session.target (instead of
      spawn-at-startup in niri)
    '';

    gtk.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Point GTK 3/4 gtk.css at the shell's generated colors.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.inter
      pkgs.nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig.enable = lib.mkDefault true;

    xdg.configFile = lib.mkIf cfg.gtk.enable {
      "gtk-3.0/gtk.css".text = ''@import url("file://${config.xdg.stateHome}/shell/theme/gtk3.css");'';
      "gtk-4.0/gtk.css".text = ''@import url("file://${config.xdg.stateHome}/shell/theme/gtk4.css");'';
    };

    systemd.user.services.shell = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Quickshell desktop shell";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
