{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperPreference;
  cfg = config.programs.reaper.preferences.general.paths;
in {
  options.programs.reaper.preferences.general.paths = {
    defaultProjectSavePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/user/Projects/REAPER";
      description = "Default path for saving new projects.";
    };

    defaultRenderPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Renders";
      description = "Default render path. A relative path is resolved relative to the current project.";
    };

    defaultRecordingPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/user/Music/Recordings";
      description = "Default recording path when the project is unsaved and no recording path is configured.";
    };

    peakCache = {
      storeAllInAlternatePath = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether all `.reapeaks` peak-cache files are stored in the alternate path.";
      };

      alternatePath = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/home/user/.cache/reaper-peaks";
        description = "Alternate path in which REAPER stores peak-cache files.";
      };

      useAlternatePathForPaths = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/mnt/samples";
        description = "Paths for which REAPER uses the alternate peak-cache path, in REAPER's native list format.";
      };
    };

    doNotCopyOrMoveMediaFromTheFollowingPaths = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      example = [
        "/home/user/Downloads/samplepack"
        "/mnt/samples"
      ];
      description = "List of paths that will not have media copied or moved from (on import if configured, or save-as with copy). Useful for sample libraries, etc.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.general.paths.defaultProjectSavePath";
        value = cfg.defaultProjectSavePath;
        section = "reaper";
        key = "defsavepath";
      }
      {
        path = "preferences.general.paths.defaultRenderPath";
        value = cfg.defaultRenderPath;
        section = "reaper";
        key = "defrenderpath";
      }
      {
        path = "preferences.general.paths.defaultRecordingPath";
        value = cfg.defaultRecordingPath;
        section = "reaper";
        key = "defrecpath";
      }
      {
        path = "preferences.general.paths.peakCache.alternatePath";
        value = cfg.peakCache.alternatePath;
        section = "reaper";
        key = "altpeakspath";
      }
      {
        path = "preferences.general.paths.peakCache.useAlternatePathForPaths";
        value = cfg.peakCache.useAlternatePathForPaths;
        section = "reaper";
        key = "altpeaksopathlist";
      }
      {
        path = "preferences.general.paths.doNotCopyOrMoveMediaFromTheFollowingPaths";
        value = cfg.doNotCopyOrMoveMediaFromTheFollowingPaths;
        section = "reaper";
        key = "nocopyfrompaths";
        codec = "list";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      altpeaks = [
        {
          optionPath = "preferences.general.paths.peakCache.storeAllInAlternatePath";
          gui = "Store all peak caches (.reapeaks) in alternate path";
          option = cfg.peakCache.storeAllInAlternatePath;
          bit = 1;
        }
      ];
    });
}
