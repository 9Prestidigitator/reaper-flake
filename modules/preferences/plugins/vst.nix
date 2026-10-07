{
  config,
  lib,
  pkgs,
  reaperLib,
  reaperPlugins,
  ...
}: let
  inherit (lib) mkOption optionals types unique;
  inherit (reaperLib) reaperPreference;

  cfg = config.programs.reaper.preferences.plugIns;

  vstPathKey =
    if pkgs.stdenv.hostPlatform.isDarwin
    then
      (
        if pkgs.stdenv.hostPlatform.isAarch64
        then "vstpath_arm64"
        else "vstpath64"
      )
    else "vstpath";

  nixPaths = optionals cfg.vst.enableNixPaths (reaperPlugins.profilePaths config.home.username ["vst" "vst3"]);

  userPaths = optionals cfg.vst.enableUserPaths (
    if pkgs.stdenv.hostPlatform.isDarwin
    then [
      "/Library/Audio/Plug-Ins/VST"
      "/Library/Audio/Plug-Ins/VST3"
      "~/Library/Audio/Plug-Ins/VST"
      "~/Library/Audio/Plug-Ins/VST3"
    ]
    else [
      "~/.vst"
      "~/.vst3"
    ]
  );

  searchPaths = unique (cfg.vst.searchPaths ++ nixPaths ++ userPaths);
in {
  options.programs.reaper.preferences.plugIns.vst = {
    searchPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/Documents/vsts" "~/Downloads/vst3"];
      description = ''
        Additional VST(3) search paths written to `[reaper].vstpath` on Linux,
        `vstpath_arm64` on Apple Silicon, or `vstpath64` on Intel macOS.
        This key is always managed, but by default `mutable` is true,
        meaning paths added via REAPER's UI are preserved across
        activations by merging them with the computed list.
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
        Whether to append `~/.vst` and `~/.vst3` on Linux, or the VST and VST3
        directories under `/Library/Audio/Plug-Ins` and `~/Library/Audio/Plug-Ins`
        on macOS.
      '';
    };

    mutable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to merge the computed search paths with the existing on-disk
        value instead of replacing it. When true, paths added via REAPER's UI
        are preserved across activations. When false, the INI key is
        overwritten on every activation. Only supported for list-valued
        preferences.
      '';
    };
  };

  config.programs.reaper.ini.contributions = reaperPreference.contribution {
    path = "preferences.plugIns.vst.searchPaths";
    value = searchPaths;
    configured = true;
    mutable = cfg.vst.mutable;
    section = "reaper";
    key = vstPathKey;
    codec = "list";
  };
}
