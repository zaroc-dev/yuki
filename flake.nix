{
  description = "yuki: a Quickshell desktop shell for niri (bar, launcher, lock screen, Material You theming)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        yuki = pkgs.callPackage ./nix/package.nix { };
        sddm-theme = pkgs.callPackage ./nix/sddm-theme.nix { };
        plymouth-theme = pkgs.callPackage ./nix/plymouth-theme.nix { };
        default = yuki;
      });

      homeManagerModules.default = import ./nix/home-module.nix self;
      nixosModules.default = import ./nix/nixos-module.nix self;

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.quickshell
            pkgs.kdePackages.qtdeclarative # qmlls, qmlformat
            pkgs.nixfmt
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
