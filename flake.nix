{
  description = "yuki: a Quickshell desktop shell for niri (bar, launcher, lock screen, Material You theming)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
  };

  # Dendritic: every file under nix/modules is a flake-parts module. The
  # callPackage derivations sit one level up so import-tree skips them.
  outputs =
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./nix/modules);
}
