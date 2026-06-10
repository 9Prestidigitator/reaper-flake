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
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      perSystem = {system, ...}: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        packages = rec {
          default = reaper;
          reaper = pkgs.callPackage ./packages/reaper.nix {inherit swell-wayland;};
          reapack = pkgs.callPackage ./packages/reapack {};
          sws = pkgs.callPackage ./packages/sws {};
          swell-wayland = pkgs.callPackage ./packages/swell-wayland.nix {};
        };

        devShells.default = pkgs.mkShell {
          name = "reaper-flake dev shell";
          packages = with pkgs; [
            nixd
            alejandra

            (python3.withPackages
              (ps:
                with ps; [
                  numpy
                  pandas
                  matplotlib
                  scikit-learn
                  # tools
                  black
                  debugpy
                ]))
            basedpyright
            ruff

            bash-language-server
            prettierd
          ];
        };
      };

      flake.homeModules.reaper = ./modules;
    };
}
