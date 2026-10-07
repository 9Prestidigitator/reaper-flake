{
  config,
  lib,
  pkgs,
  reaperLib,
  reaperPlugins,
  ...
}: let
  inherit
    (lib)
    mkOption
    optionals
    types
    unique
    ;
  inherit (reaperLib) reaperPreference;

  cfg = config.programs.reaper.preferences.plugIns;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  clapPathKey = "clap_path_${
    if isDarwin
    then "macos"
    else "linux"
  }-${pkgs.stdenv.hostPlatform.qemuArch}";
  lv2PathKey =
    if isDarwin
    then "lv2path_mac"
    else "lv2path_linux";

  nixClapPaths = optionals cfg.clap.enableNixPaths (
    reaperPlugins.profilePaths config.home.username ["clap"]
  );

  nixLv2Paths = optionals cfg.lv2.enableNixPaths (
    reaperPlugins.profilePaths config.home.username ["lv2"]
  );

  userClapPaths = optionals cfg.clap.enableUserPaths ((
      if isDarwin
      then [
        "/Library/Audio/Plug-Ins/CLAP"
        "~/Library/Audio/Plug-Ins/CLAP"
      ]
      else [
        "/usr/local/lib/clap"
        "/usr/lib/clap"
        "~/.clap"
      ]
    )
    ++ ["%CLAP_PATH%"]);

  userLv2Paths = optionals cfg.lv2.enableUserPaths ((
      if isDarwin
      then [
        "/Library/Audio/Plug-Ins/LV2"
        "~/Library/Audio/Plug-Ins/LV2"
      ]
      else [
        "/usr/lib/lv2"
        "/usr/local/lib/lv2"
        "~/.lv2"
      ]
    )
    ++ ["%LV2_PATH%"]);

  clapSearchPaths = unique (cfg.clap.searchPaths ++ nixClapPaths ++ userClapPaths);
  lv2SearchPaths = unique (cfg.lv2.searchPaths ++ nixLv2Paths ++ userLv2Paths);
in {
  options.programs.reaper.preferences.plugIns = {
    lv2 = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.lv2"];
        description = ''
          Additional LV2 search paths written to `[reaper].lv2path_mac` on macOS
          or `[reaper].lv2path_linux` on Linux.
          This key is always managed, but by default `mutable` is true,
          meaning paths added via REAPER's UI are preserved across
          activations by merging them with the computed list.
        '';
      };

      enableNixPaths = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to append LV2 directories from the per-user, user, and system
          Nix profiles.
        '';
      };

      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to append the platform-specific LV2 paths (/Library/Audio/Plug-Ins/LV2 and ~/Library/Audio/Plug-Ins/LV2 on macOS), including %LV2_PATH%.";
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

    clap = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.clap"];
        description = ''
          Additional CLAP search paths written to `[reaper].clap_path_macos-<arch>`
          on macOS or `[reaper].clap_path_linux-<arch>` on Linux.
          This key is always managed, but by default `mutable` is true,
          meaning paths added via REAPER's UI are preserved across
          activations by merging them with the computed list.
        '';
      };

      enableNixPaths = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to append CLAP directories from the per-user, user, and system
          Nix profiles.
        '';
      };

      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to append the platform-specific CLAP paths (/Library/Audio/Plug-Ins/CLAP and ~/Library/Audio/Plug-Ins/CLAP on macOS), including %CLAP_PATH%.";
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
  };

  config.programs.reaper.ini.contributions = reaperPreference.contributions [
    {
      path = "preferences.plugIns.clap.searchPaths";
      value = clapSearchPaths;
      configured = true;
      mutable = cfg.clap.mutable;
      section = "reaper";
      key = clapPathKey;
      codec = "list";
    }
    {
      path = "preferences.plugIns.lv2.searchPaths";
      value = lv2SearchPaths;
      configured = true;
      mutable = cfg.lv2.mutable;
      section = "reaper";
      key = lv2PathKey;
      codec = "list";
    }
  ];
}
