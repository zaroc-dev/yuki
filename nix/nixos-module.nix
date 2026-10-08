self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.yuki;
  pkgs' = self.packages.${pkgs.stdenv.hostPlatform.system};
  palette = lib.types.submodule {
    options = lib.genAttrs [ "accent" "onAccent" "base" "crust" "surface" "text" "subtext" "muted" "error" ] (
      _: lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      }
    );
  };
in
{
  options.programs.yuki = {
    sddm = {
      enable = lib.mkEnableOption "the SDDM login theme matching yuki";
      background = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Wallpaper shown (blurred) behind the login form.";
      };
    };

    plymouth.enable = lib.mkEnableOption "the Plymouth boot splash matching yuki";

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
}
