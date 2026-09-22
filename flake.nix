{
  description = "What a code comment says, and the checker that holds comments to it";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # The pinned toolbox for check.sh, locally and in CI. A check whose tools come from
      # the registry changes behaviour with zero change in the repository
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            actionlint
            git
            # check-sh.sh reads a script as a tree, out of `shfmt --to-json`, and jq
            # flattens that tree into rows
            jq
            # check-comments.sh prints its frontend for a linter that cannot see Python
            # inside a heredoc
            ruff
            shellcheck
            shfmt
            # The comment reader. The language pack carries a Nix grammar, which Vale and
            # the tree-sitter CLI's default configuration both lack
            (python3.withPackages (ps: [ ps.tree-sitter-language-pack ]))
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
