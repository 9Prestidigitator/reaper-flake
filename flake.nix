{
  description = "REAPER flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-26.05";
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
        generatePreferencesDocs = pkgs.writeShellApplication {
          name = "generate-preferences-docs";
          runtimeInputs = [pkgs.git pkgs.nix pkgs.prettier];
          text = ''
            repo=$(git rev-parse --show-toplevel)
            cd "$repo"

            options_doc=$(nix build --impure --no-link --print-out-paths --expr '
              let
                flake = builtins.getFlake (toString ./.);
                pkgs = import flake.inputs.nixpkgs {
                  system = builtins.currentSystem;
                  config.allowUnfree = true;
                };
              in (import ./docs/preferences-options.nix {
                inherit pkgs;
                lib = pkgs.lib;
              }).optionsCommonMark
            ')

            cp "$options_doc" "$repo/docs/preferences.md"
            prettier --write "$repo/docs/preferences.md"
          '';
        };
      in {
        apps.generate-preferences-docs = {
          type = "app";
          program = pkgs.lib.getExe generatePreferencesDocs;
          meta.description = "Generate Markdown documentation for REAPER preference options";
        };

        devShells.default = pkgs.callPackage ./devshell.nix {};
        packages =
          rec {
            default = reaper;
            reaper = pkgs.callPackage ./packages/reaper.nix {
              swell-wayland =
                if pkgs.stdenv.hostPlatform.isLinux
                then swellWayland
                else null;
            };
            reapertips-theme = pkgs.callPackage ./packages/themes/reapertips.nix {};
            smooth6-theme = pkgs.callPackage ./packages/themes/smooth6.nix {};
            reapack = pkgs.callPackage ./packages/reapack {};
            sws = pkgs.callPackage ./packages/sws {};
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            swell-wayland = swellWayland;
          };
      };

      flake.homeModules.reaper = ./modules;
    };
}
