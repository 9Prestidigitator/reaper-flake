{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption optionalAttrs optionals types unique;

  cfg = config.programs.reaper.preferences.plugIns;

  nixSystemPaths = optionals cfg.nixSystemPaths.enable [
    "${cfg.nixSystemPaths.root}/lib/vst"
    "${cfg.nixSystemPaths.root}/lib/vst3"
  ];

  userPaths = optionals cfg.vst.enableUserPaths [
    "~/.vst"
    "~/.vst3"
  ];

  searchPaths = unique (nixSystemPaths ++ userPaths ++ cfg.vst.searchPaths);
in {
  options.programs.reaper.preferences.plugIns.vst = {
    searchPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/Documents/vsts" "~/Downloads/vst3"];
      description = "Additional VST(3) search paths appended to `[reaper].vstpath`.";
    };

    enableUserPaths = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to include default ~/.vst(3) paths in searchPaths.";
    };
  };

  config.programs.reaper.ini.sections.reaper = optionalAttrs (searchPaths != []) {
    vstpath = searchPaths;
  };
}
