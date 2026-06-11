{
  description = "REAPER flake";

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
        swellWayland = pkgs.callPackage ./packages/swell-wayland.nix {};
      in {
        packages =
          rec {
            default = reaper;
            reaper = pkgs.callPackage ./packages/reaper.nix {
              swell-wayland =
                if pkgs.stdenv.hostPlatform.isLinux
                then swellWayland
                else null;
            };
            reapertips-theme = pkgs.callPackage ./packages/reapertips-theme.nix {};
            reapack = pkgs.callPackage ./packages/reapack {};
            sws = pkgs.callPackage ./packages/sws {};
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            swell-wayland = swellWayland;
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
