{
  config,
  lib,
  pkgs,
  reaperLib,
  reaperPlugins,
  ...
}:
let
  inherit (lib)
    mkOption
    optionals
    types
    unique
    ;
  inherit (reaperLib) reaperPreference;

  cfg = config.programs.reaper.preferences.plugIns;
  clapPathKey = "clap_path_linux-${pkgs.stdenv.hostPlatform.qemuArch}";

  nixClapPaths = optionals cfg.clap.enableNixPaths (
    reaperPlugins.profilePaths config.home.username [ "clap" ]
  );

  nixLv2Paths = optionals cfg.lv2.enableNixPaths (
    reaperPlugins.profilePaths config.home.username [ "lv2" ]
  );

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
    "%LV2_PATH%"
  ];

  clapSearchPaths = unique (cfg.clap.searchPaths ++ nixClapPaths ++ userClapPaths);
  lv2SearchPaths = unique (cfg.lv2.searchPaths ++ nixLv2Paths ++ userLv2Paths);
in
{
  options.programs.reaper.preferences.plugIns = {
    lv2 = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "~/.lv2" ];
        description = ''
          Additional LV2 search paths written to `[reaper].lv2path_linux`.
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
        description = "Whether to append the conventional LV2 paths.";
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
        default = [ ];
        example = [ "~/.clap" ];
        description = ''
          Additional CLAP search paths written to REAPER's Linux CLAP path.
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
        description = "Whether to append the conventional CLAP paths.";
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
      key = "lv2path_linux";
      codec = "list";
    }
  ];
}
