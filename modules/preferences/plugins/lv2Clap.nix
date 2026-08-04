{
  config,
  lib,
  pkgs,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption optionals types unique;
  inherit (reaperLib) reaperPreference;

  cfg = config.programs.reaper.preferences.plugIns;
  clapPathKey = "clap_path_linux-${pkgs.stdenv.hostPlatform.qemuArch}";

  nixClapPaths = optionals cfg.clap.enableNixPaths [
    "/run/current-system/sw/lib/clap"
  ];

  nixLv2Paths = optionals cfg.lv2.enableNixPaths [
    "/run/current-system/sw/lib/lv2"
  ];

  userClapPaths = optionals cfg.clap.enableUserPaths [
    "/usr/local/lib/clap"
    "/usr/lib/clap"
    "~/.clap"
    "%CLAP_PATH%"
  ];

  userLv2Paths = optionals cfg.lv2.enableUserPaths [
    "/usr/lib/lv2"
    "/usr/local/lib/lv2"
    "~/.lv2"
  ];

  clapSearchPaths = unique (cfg.clap.searchPaths ++ nixClapPaths ++ userClapPaths);
  lv2SearchPaths = unique (cfg.lv2.searchPaths ++ nixLv2Paths ++ userLv2Paths);
in {
  options.programs.reaper.preferences.plugIns = {
    lv2 = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.lv2"];
        description = "LV2 search paths written to `[reaper].lv2path_linux` before any enabled Nix and conventional user paths are appended.";
      };

      enableNixPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to append `/run/current-system/sw/lib/lv2`.";
      };

      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to append the conventional LV2 paths.";
      };
    };

    clap = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.clap"];
        description = "CLAP search paths written to REAPER's Linux CLAP path before any enabled Nix and conventional user paths are appended.";
      };

      enableNixPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to append `/run/current-system/sw/lib/clap`.";
      };

      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to append the conventional CLAP paths.";
      };
    };
  };

  config.programs.reaper.ini.contributions = reaperPreference.contributions [
    {
      path = "preferences.plugIns.clap.searchPaths";
      value = clapSearchPaths;
      configured = clapSearchPaths != [] || !cfg.clap.enableNixPaths || !cfg.clap.enableUserPaths;
      section = "reaper";
      key = clapPathKey;
      codec = "list";
    }
    {
      path = "preferences.plugIns.lv2.searchPaths";
      value = lv2SearchPaths;
      configured = lv2SearchPaths != [] || !cfg.lv2.enableNixPaths || !cfg.lv2.enableUserPaths;
      section = "reaper";
      key = "lv2path_linux";
      codec = "list";
    }
  ];
}
