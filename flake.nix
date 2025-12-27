{
  description = "Luca's custom shell pwd for use with starship.rs";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    inputs@{ nixpkgs, crane, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      imports = with inputs; [
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];

      perSystem =
        {
          config,
          self',
          pkgs,
          ...
        }:
        let
          craneLib = crane.mkLib pkgs;
          commonArgs = {
            src = craneLib.cleanCargoSource ./.;
            strictDeps = true;
          };
          crate = craneLib.buildPackage (
            commonArgs
            // {
              cargoArtifacts = craneLib.buildDepsOnly commonArgs;
            }
          );
        in
        {
          checks = { inherit crate; };
          packages = {
            default = crate;
            lcs-pwd = crate;
          };

          devShells.default = craneLib.devShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
            checks = self'.checks;
            packages =
              with pkgs;
              [
                rust-analyzer
                just
              ];
          };

          pre-commit.settings.hooks.treefmt.enable = true;

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              rustfmt.enable = true;
              nixfmt.enable = true;
              taplo.enable = true;
              just.enable = true;
            };
          };
        };
    };
}
