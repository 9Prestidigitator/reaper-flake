{
  lib,
  pkgs,
}: let
  reaperLib = import ./lib {inherit lib;};

  evaluated = lib.evalModules {
    specialArgs = reaperLib // {inherit pkgs reaperLib;};
    modules = [
      ./ini.nix
      ./line-files.nix
      ./resources.nix
      ./actions.nix
      ./extensions/reapack-schema.nix
      ./layout
      ./windows.nix

      ./preferences/general
      ./preferences/project
      ./preferences/appearance
      ./preferences/editing-behavior
      ./preferences/media
      ./preferences/plugins
      ./preferences/control-osc-web.nix

      {
        options.assertions = lib.mkOption {
          type = lib.types.listOf lib.types.unspecified;
          default = [];
        };
        options.warnings = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
        options.programs.reaper.configPath = lib.mkOption {
          type = lib.types.str;
          default = "/tmp/reaper-flake-schema";
          internal = true;
        };
      }
    ];
  };
  failedAssertions = builtins.filter (assertion: !assertion.assertion) evaluated.config.assertions;
in
  assert lib.assertMsg (failedAssertions == [])
  (builtins.concatStringsSep "\n" (map (assertion: assertion.message) failedAssertions));
    evaluated.config.programs.reaper.ini.generatedSchemaFile
