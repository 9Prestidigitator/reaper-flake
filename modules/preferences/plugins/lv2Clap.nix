{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption optionalAttrs optionals types unique;

  cfg = config.programs.reaper.preferences.plugIns;
  clapPathKey = "clap_path_linux-${pkgs.stdenv.hostPlatform.qemuArch}";

  nixSystemClapPaths = optionals cfg.nixSystemPaths.enable [
    "${cfg.nixSystemPaths.root}/lib/clap"
  ];

  nixSystemLv2Paths = optionals cfg.nixSystemPaths.enable [
    "${cfg.nixSystemPaths.root}/lib/lv2"
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

  clapSearchPaths = unique (nixSystemClapPaths ++ userClapPaths ++ cfg.clap.searchPaths);
  lv2SearchPaths = unique (nixSystemLv2Paths ++ userLv2Paths ++ cfg.lv2.searchPaths);
in {
  options.programs.reaper.preferences.plugIns = {
    lv2 = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.lv2"];
        description = "Additional LV2 search paths appended to `[reaper].lv2path_linux`.";
      };

      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to include default ~/.lv2 paths in searchPaths.";
      };
    };

    clap = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.clap"];
        description = "Additional CLAP search paths appended to REAPER's Linux CLAP path.";
      };

      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to include default ~/.clap paths in searchPaths.";
      };
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (clapSearchPaths != []) {
      ${clapPathKey} = clapSearchPaths;
    }
    // optionalAttrs (lv2SearchPaths != []) {
      lv2path_linux = lv2SearchPaths;
    };
}
