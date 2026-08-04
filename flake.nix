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
        reapackPackage = pkgs.callPackage ./packages/reapack {};
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
        reaperSchema = import ./modules/schema.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        reaper2nix = pkgs.writeShellApplication {
          name = "reaper2nix";
          runtimeInputs = [pkgs.python3];
          text = ''
            export REAPER_FLAKE_SCHEMA=${pkgs.lib.escapeShellArg reaperSchema}
            exec python3 ${./scripts/reaper2nix.py} "$@"
          '';
        };
      in {
        apps.generate-preferences-docs = {
          type = "app";
          program = pkgs.lib.getExe generatePreferencesDocs;
          meta.description = "Generate Markdown documentation for REAPER preference options";
        };

        apps.reaper2nix = {
          type = "app";
          program = pkgs.lib.getExe reaper2nix;
          meta.description = "Convert supported REAPER INI values to reaper-flake declarations";
        };

        checks = {
          reapack = reapackPackage;

          actions-shortcuts = pkgs.callPackage ./tests/actions-shortcuts.nix {};

          plugin-paths = pkgs.callPackage ./tests/plugin-paths.nix {};

          preference-schema = pkgs.callPackage ./tests/preference-schema.nix {};

          sws-colors = pkgs.callPackage ./tests/sws-colors.nix {};

          activation-guard =
            pkgs.runCommand "reaper-activation-guard-tests" {
              nativeBuildInputs = [pkgs.python3 pkgs.procps];
              PGREP_FOR_TESTS = pkgs.lib.getExe' pkgs.procps "pgrep";
              REAPER_RUNNING_SCRIPT = ./scripts/reaper-is-running.sh;
              SHELL_FOR_TESTS = pkgs.runtimeShell;
            } ''
              python3 ${./tests/test_activation_guard.py} -v
              touch "$out"
            '';

          reaper2nix =
            pkgs.runCommand "reaper2nix-tests" {
              nativeBuildInputs = [pkgs.python3];
              REAPER2NIX_SCRIPT = ./scripts/reaper2nix.py;
            } ''
              python3 ${./tests/test_reaper2nix.py} -v
              touch "$out"
            '';

          schema =
            pkgs.runCommand "reaper-schema-tests" {
              nativeBuildInputs = [pkgs.python3];
              REAPER_SCHEMA_PATH = reaperSchema;
            } ''
              python3 ${./tests/test_schema.py} -v
              touch "$out"
            '';

          reapack-startup =
            pkgs.runCommand "reapack-startup-tests" {
              nativeBuildInputs = [pkgs.lua];
              LUA = pkgs.lib.getExe pkgs.lua;
              REAPACK_MODULE = ./modules/extensions/reapack.nix;
            } ''
              ${pkgs.python3.interpreter} ${./tests/test_reapack_startup.py} -v
              touch "$out"
            '';

          write-config =
            pkgs.runCommand "reaper-write-config-tests" {
              nativeBuildInputs = [pkgs.python3];
              WRITE_CONFIG_SCRIPT = ./scripts/write_config.py;
            } ''
              python3 ${./tests/test_write_config.py} -v
              touch "$out"
            '';
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
            reapack = reapackPackage;
            reaper-schema = reaperSchema;
            sws = pkgs.callPackage ./packages/sws {};
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            swell-wayland = swellWayland;
          };
      };

      flake.homeModules.reaper = ./modules;
    };
}
