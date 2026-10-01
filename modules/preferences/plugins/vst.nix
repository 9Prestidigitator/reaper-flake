{
  config,
  lib,
  reaperLib,
  reaperPlugins,
  ...
}: let
  inherit (lib) mkOption optionals types unique;
  inherit (reaperLib) reaperPreference;

  cfg = config.programs.reaper.preferences.plugIns;

  nixPaths = optionals cfg.vst.enableNixPaths (reaperPlugins.profilePaths config.home.username ["vst" "vst3"]);

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
      description = ''
        Additional VST(3) search paths written to `[reaper].vstpath`.
        When empty and both `enableNixPaths` and `enableUserPaths` are
        enabled (the default), REAPER uses its own built-in defaults,
        leaving the INI key unmanaged and fully mutable at runtime.
      '';
    };

    enableNixPaths = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to append VST and VST3 directories from the per-user, user, and
        system Nix profiles.
      '';
    };

    enableUserPaths = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to append the default `~/.vst` and `~/.vst3` paths.
      '';
    };

    mutable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to merge the computed search paths with the existing on-disk
        value. When true, paths added via REAPER's UI are preserved across
        activations. When false, the INI key is overwritten on every activation.
      '';
    };
  };

  config.programs.reaper.ini.contributions = reaperPreference.contribution {
    path = "preferences.plugIns.vst.searchPaths";
    value = searchPaths;
    configured = true;
    mutable = cfg.vst.mutable;
    section = "reaper";
    key = "vstpath";
    codec = "list";
  };
}
