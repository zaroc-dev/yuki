{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.quickshell
          pkgs.kdePackages.qtdeclarative # qmlls, qmlformat
          pkgs.nixfmt
        ];
      };

      formatter = pkgs.nixfmt-tree;
    };
}
