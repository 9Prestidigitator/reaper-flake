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
          When empty and both `enableNixPaths` and `enableUserPaths` are
          enabled (the default), REAPER uses its own built-in defaults and
          the `LV2_PATH` environment variable, leaving the INI key unmanaged
          and fully mutable at runtime.
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
    };

    clap = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "~/.clap" ];
        description = ''
          Additional CLAP search paths written to REAPER's Linux CLAP path.
          When empty and both `enableNixPaths` and `enableUserPaths` are
          enabled (the default), REAPER uses its own built-in defaults and
          the `CLAP_PATH` environment variable, leaving the INI key unmanaged
          and fully mutable at runtime.
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
    };
  };

  config.programs.reaper.ini.contributions = reaperPreference.contributions [
    {
      path = "preferences.plugIns.clap.searchPaths";
      value = clapSearchPaths;
      configured = cfg.clap.searchPaths != [ ] || !cfg.clap.enableNixPaths || !cfg.clap.enableUserPaths;
      section = "reaper";
      key = clapPathKey;
      codec = "list";
    }
    {
      path = "preferences.plugIns.lv2.searchPaths";
      value = lv2SearchPaths;
      configured = cfg.lv2.searchPaths != [ ] || !cfg.lv2.enableNixPaths || !cfg.lv2.enableUserPaths;
      section = "reaper";
      key = "lv2path_linux";
      codec = "list";
    }
  ];
}
