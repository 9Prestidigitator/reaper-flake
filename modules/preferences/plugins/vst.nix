{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption optionals types unique;
  inherit (reaperLib) reaperPreference;

  cfg = config.programs.reaper.preferences.plugIns;

  nixPaths = optionals cfg.vst.enableNixPaths [
    "/run/current-system/sw/lib/vst"
    "/run/current-system/sw/lib/vst3"
  ];

  userPaths = optionals cfg.vst.enableUserPaths [
    "~/.vst"
    "~/.vst3"
  ];

  searchPaths = unique (cfg.vst.searchPaths ++ nixPaths ++ userPaths);
in {
  options.programs.reaper.preferences.plugIns.vst = {
    searchPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/Documents/vsts" "~/Downloads/vst3"];
      description = "VST(3) search paths written to `[reaper].vstpath` before any enabled Nix and conventional user paths are appended.";
    };

    enableNixPaths = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to append VST and VST3 directories from `/run/current-system/sw/lib`.";
    };

    enableUserPaths = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to append the default `~/.vst` and `~/.vst3` paths.";
    };
  };

  config.programs.reaper.ini.contributions = reaperPreference.contribution {
    path = "preferences.plugIns.vst.searchPaths";
    value = searchPaths;
    configured = searchPaths != [] || !cfg.vst.enableNixPaths || !cfg.vst.enableUserPaths;
    section = "reaper";
    key = "vstpath";
    codec = "list";
  };
}
