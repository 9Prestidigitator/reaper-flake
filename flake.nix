{
  description = "Reaper flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      perSystem = {system, ...}: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        packages = rec {
          default = reaper;
          reaper = pkgs.callPackage ./packages/reaper.nix {};
          reapack = pkgs.callPackage ./packages/reapack {};
          sws = pkgs.callPackage ./packages/sws {};
        };

        devShells.default = pkgs.mkShell {
          name = "reaper-flake dev shell";
          packages = with pkgs; [
            nixd
            alejandra
            bash-language-server
            prettierd
          ];
        };
      };
    };
}
