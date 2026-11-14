let
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.yuki;
      pkgs' = {
        sddm-theme = pkgs.callPackage ../sddm-theme.nix { };
        plymouth-theme = pkgs.callPackage ../plymouth-theme.nix { };
      };
      palette = lib.types.submodule {
        options =
          lib.genAttrs
            [
              "accent"
              "accent2"
              "onAccent"
              "base"
              "crust"
              "surface"
              "text"
              "subtext"
              "muted"
              "error"
            ]
            (
              _:
              lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              }
            );
      };
    in
    {
      options.programs.yuki = {
        enable = lib.mkEnableOption "yuki, the Quickshell desktop shell, for every user";

        configDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "~/source/shell";
          description = ''
            Run the QML from this directory (e.g. a git checkout) instead of the
            store copy, to keep Quickshell's hot reload. A leading `~` expands to
            the user's home when yuki starts, so one system package works for
            every user. Without shell.qml there, the store copy runs.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.callPackage ../package.nix { inherit (cfg) configDir; };
          defaultText = lib.literalExpression "pkgs.callPackage yuki/nix/package.nix { inherit (cfg) configDir; }";
          description = "The wrapped shell (`yuki`, `yuki ipc call …`).";
        };

        systemd.enable = lib.mkEnableOption ''
          a systemd user service bound to graphical-session.target (instead of
          spawn-at-startup in niri)
        '';

        gtk.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Create ~/.config/gtk-{3,4}.0/gtk.css importing the shell's generated
            colors, for users that have no gtk.css yet (systemd-tmpfiles `f`
            never overwrites an existing file).
          '';
        };

        sddm = {
          enable = lib.mkEnableOption "the SDDM login theme matching yuki";
          background = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Wallpaper shown (blurred) behind the login form.";
          };
        };

        plymouth.enable = lib.mkEnableOption "the Plymouth boot splash matching yuki";

        services.enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg.enable;
          defaultText = lib.literalExpression "config.programs.yuki.enable";
          example = true;
          description = ''
            Enable the system services the shell talks to: UPower (battery),
            power-profiles-daemon (profile picker; skipped with TLP or
            auto-cpufreq), PipeWire (volume, OSD), BlueZ and polkit. Each is a
            `mkDefault`, so a host can still turn one off. Works without
            `enable`, e.g. when the shell comes from `wrapperModules.yuki`.
            NetworkManager is left to the host (the network panel needs it).
          '';
        };

        palette = lib.mkOption {
          type = palette;
          default = { };
          description = ''
            Colors for SDDM and Plymouth (hex). Unset keys use the defaults (the
            Material scheme of raiden.shogun.jpg). Copy from
            ~/.local/state/yuki/theme/colors.json to match the shell.
          '';
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          environment.systemPackages = [ cfg.package ];
          fonts.packages = [
            pkgs.inter
            pkgs.nerd-fonts.jetbrains-mono
          ];

          # %h is expanded by systemd-tmpfiles in the path and the content.
          systemd.user.tmpfiles.rules = lib.mkIf cfg.gtk.enable [
            ''f %h/.config/gtk-3.0/gtk.css 0644 - - - @import url("file://%h/.local/state/yuki/theme/gtk3.css");''
            ''f %h/.config/gtk-4.0/gtk.css 0644 - - - @import url("file://%h/.local/state/yuki/theme/gtk4.css");''
          ];

          systemd.user.services.yuki = lib.mkIf cfg.systemd.enable {
            description = "yuki desktop shell";
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = lib.getExe cfg.package;
              Restart = "on-failure";
              RestartSec = 2;
            };
          };
        })

        (lib.mkIf cfg.services.enable {
          services.upower.enable = lib.mkDefault true;
          # Both conflict with power-profiles-daemon (nixpkgs asserts on TLP).
          services.power-profiles-daemon.enable = lib.mkDefault (
            !config.services.tlp.enable && !config.services.auto-cpufreq.enable
          );
          services.pipewire.enable = lib.mkDefault true;
          hardware.bluetooth.enable = lib.mkDefault true;
          security.polkit.enable = lib.mkDefault true;
        })

        (lib.mkIf cfg.sddm.enable {
          services.displayManager.sddm = {
            theme = "yuki";
            extraPackages = [ pkgs.kdePackages.qtdeclarative ];
          };
          environment.systemPackages = [
            (pkgs'.sddm-theme.override {
              inherit (cfg.sddm) background;
              settings = lib.filterAttrs (_: v: v != null) cfg.palette;
            })
          ];
        })

        (lib.mkIf cfg.plymouth.enable {
          boot.plymouth = {
            enable = true;
            theme = "yuki";
            themePackages = [
              (pkgs'.plymouth-theme.override (
                lib.filterAttrs (_: v: v != null) {
                  inherit (cfg.palette)
                    accent
                    base
                    surface
                    text
                    ;
                }
              ))
            ];
            font = "${pkgs.inter}/share/fonts/truetype/InterVariable.ttf";
          };
        })
      ];
    };
in
{
  flake.nixosModules = {
    yuki = module;
    default = module;
  };
}
