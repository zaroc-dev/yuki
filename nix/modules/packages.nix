{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        yuki = pkgs.callPackage ../package.nix { };
        sddm-theme = pkgs.callPackage ../sddm-theme.nix { };
        plymouth-theme = pkgs.callPackage ../plymouth-theme.nix { };
        default = yuki;
      };
    };

  flake.overlays.default = final: _: {
    yuki = final.callPackage ../package.nix { };
    yuki-sddm-theme = final.callPackage ../sddm-theme.nix { };
    yuki-plymouth-theme = final.callPackage ../plymouth-theme.nix { };
  };
}
