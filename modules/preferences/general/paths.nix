{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
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

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.defaultProjectSavePath != null) {defsavepath = cfg.defaultProjectSavePath;}
    // optionalAttrs (cfg.defaultRenderPath != null) {defrenderpath = cfg.defaultRenderPath;}
    // optionalAttrs (cfg.defaultRecordingPath != null) {defrecpath = cfg.defaultRecordingPath;}
    // optionalAttrs (cfg.peakCache.alternatePath != null) {altpeakspath = cfg.peakCache.alternatePath;}
    // optionalAttrs (cfg.peakCache.useAlternatePathForPaths != null) {altpeaksopathlist = cfg.peakCache.useAlternatePathForPaths;}
    // optionalAttrs (cfg.doNotCopyOrMoveMediaFromTheFollowingPaths != null) {nocopyfrompaths = cfg.doNotCopyOrMoveMediaFromTheFollowingPaths;};

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    altpeaks = [
      {
        optionPath = "preferences.general.paths.peakCache.storeAllInAlternatePath";
        gui = "Store all peak caches (.reapeaks) in alternate path";
        option = cfg.peakCache.storeAllInAlternatePath;
        bit = 1;
      }
    ];
  };
}
