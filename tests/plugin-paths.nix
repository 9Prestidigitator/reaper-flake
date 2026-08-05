{
  lib,
  pkgs,
  runCommand,
}: let
  reaperLib = import ../modules/lib {inherit lib;};

  evaluate = extraModule:
    lib.evalModules {
      specialArgs = reaperLib // {inherit pkgs reaperLib;};
      modules = [
        ../modules/ini.nix
        ../modules/preferences/plugins
        {
          options.assertions = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [];
          };
          options.warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          options.home.username = lib.mkOption {
            type = lib.types.str;
            default = "test-user";
          };
          options.programs.reaper.configPath = lib.mkOption {
            type = lib.types.str;
            default = "/tmp/reaper-plugin-path-tests";
          };
        }
        extraModule
      ];
    };

  defaults = (evaluate {}).config.programs.reaper.ini.sections.reaper;

  explicit =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        vst.searchPaths = ["/exact/vst" "/exact/vst3" "/exact/vst"];
        lv2.searchPaths = ["/exact/lv2"];
        clap.searchPaths = ["/exact/clap"];
      };
    }).config.programs.reaper.ini.sections.reaper;

  onlyCustom =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        vst = {
          searchPaths = ["/exact/vst" "/exact/vst3"];
          enableNixPaths = false;
          enableUserPaths = false;
        };
        lv2 = {
          searchPaths = ["/exact/lv2"];
          enableNixPaths = false;
          enableUserPaths = false;
        };
        clap = {
          searchPaths = ["/exact/clap"];
          enableNixPaths = false;
          enableUserPaths = false;
        };
      };
    }).config.programs.reaper.ini.sections.reaper;

  empty =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        vst = {
          enableNixPaths = false;
          enableUserPaths = false;
        };
        lv2 = {
          enableNixPaths = false;
          enableUserPaths = false;
        };
        clap = {
          enableNixPaths = false;
          enableUserPaths = false;
        };
      };
    }).config.programs.reaper.ini.sections.reaper;

  clapKey = "clap_path_linux-${pkgs.stdenv.hostPlatform.qemuArch}";
in
  assert defaults.vstpath
  == [
    "/etc/profiles/per-user/test-user/lib/vst"
    "/etc/profiles/per-user/test-user/lib/vst3"
    "~/.nix-profile/lib/vst"
    "~/.nix-profile/lib/vst3"
    "/run/current-system/sw/lib/vst"
    "/run/current-system/sw/lib/vst3"
    "~/.vst"
    "~/.vst3"
  ];
  assert defaults.lv2path_linux
  == [
    "/etc/profiles/per-user/test-user/lib/lv2"
    "~/.nix-profile/lib/lv2"
    "/run/current-system/sw/lib/lv2"
    "/usr/lib/lv2"
    "/usr/local/lib/lv2"
    "~/.lv2"
  ];
  assert defaults.${clapKey}
  == [
    "/etc/profiles/per-user/test-user/lib/clap"
    "~/.nix-profile/lib/clap"
    "/run/current-system/sw/lib/clap"
    "/usr/local/lib/clap"
    "/usr/lib/clap"
    "~/.clap"
    "%CLAP_PATH%"
  ];
  assert explicit.vstpath
  == [
    "/exact/vst"
    "/exact/vst3"
    "/etc/profiles/per-user/test-user/lib/vst"
    "/etc/profiles/per-user/test-user/lib/vst3"
    "~/.nix-profile/lib/vst"
    "~/.nix-profile/lib/vst3"
    "/run/current-system/sw/lib/vst"
    "/run/current-system/sw/lib/vst3"
    "~/.vst"
    "~/.vst3"
  ];
  assert explicit.lv2path_linux
  == [
    "/exact/lv2"
    "/etc/profiles/per-user/test-user/lib/lv2"
    "~/.nix-profile/lib/lv2"
    "/run/current-system/sw/lib/lv2"
    "/usr/lib/lv2"
    "/usr/local/lib/lv2"
    "~/.lv2"
  ];
  assert explicit.${clapKey}
  == [
    "/exact/clap"
    "/etc/profiles/per-user/test-user/lib/clap"
    "~/.nix-profile/lib/clap"
    "/run/current-system/sw/lib/clap"
    "/usr/local/lib/clap"
    "/usr/lib/clap"
    "~/.clap"
    "%CLAP_PATH%"
  ];
  assert onlyCustom.vstpath == ["/exact/vst" "/exact/vst3"];
  assert onlyCustom.lv2path_linux == ["/exact/lv2"];
  assert onlyCustom.${clapKey} == ["/exact/clap"];
  assert empty.vstpath == [];
  assert empty.lv2path_linux == [];
  assert empty.${clapKey} == [];
    runCommand "reaper-plugin-path-tests" {} ''
      touch "$out"
    ''
