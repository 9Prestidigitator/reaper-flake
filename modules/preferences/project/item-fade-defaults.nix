{
  config,
  lib,
  reaperLib,
  reaperProject,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperCodecs reaperPreference reaperTypes;
  inherit (reaperProject) crossfadePositions crossfadeShapes fadeInOutShapes itemOverlapModes;

  cfg = config.programs.reaper.preferences.project.itemFadeDefaults;
  recordedItemOverlapValues = {
    noCrossfade = 0;
    overlapAndCrossfade = 1024;
    respectToolbarAutoCrossfadeButton = 2048;
  };
  splitItemOverlapValues = {
    noCrossfade = 0;
    overlapAndCrossfade = 1;
    respectToolbarAutoCrossfadeButton = 512;
  };
  splitCrossfadePositionValues = {
    left = 131072;
    center = 262144;
    right = 0;
  };
  trimContentBehindMediaEditsValues = {
    noCrossfade = 8192;
    overlapAndCrossfade = 4096;
    respectToolbarAutoCrossfadeButton = 0;
  };
  trimContentBehindRazorEditsValues = {
    noCrossfade = 0;
    overlapAndCrossfade = 64;
    respectToolbarAutoCrossfadeButton = 32768;
  };
in {
  options.programs.reaper.preferences.project.itemFadeDefaults = {
    defaultFadeInFadeOutLength = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 0.050;
      description = "The default fade-in/fade-out length, in seconds.";
    };
    defaultCrossfadeLength = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 0.080;
      description = "The default crossfade length, in seconds.";
    };
    defaultFadeInFadeOutShape = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames fadeInOutShapes));
      default = null;
      example = "exponential";
      description = "The default fade-in/fade-out shape.";
    };
    defaultCrossfadeShape = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames crossfadeShapes));
      default = null;
      example = "centerDip";
      description = "The default crossfade shape.";
    };

    importedMediaItems = {
      fadeInFadeOut = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Automatically fade-in/fade-out imported media items.";
      };
    };
    recordedMediaItems = {
      fadeInFadeOut = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Automatically fade-in/fade-out newly recorded media items.";
      };
      overlap = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames itemOverlapModes));
        default = null;
        description = "Overlap and crossfade when a new recording overlaps existing media items.";
      };
    };
    splitMediaItems = {
      fadeInFadeOut = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Automatically fade-in/fade-out media items created by splitting.";
      };
      overlap = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames itemOverlapModes));
        default = null;
        description = "Overlap and crossfade when splitting media items.";
      };
      overlapCrossfadePosition = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames crossfadePositions));
        default = null;
        example = "left";
        description = "Crossfade to the left, right, or center when splitting media items.";
      };
    };

    fixedLaneCompAreas = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Automatically fade-in/fade-out and crossfade fixed-lane comp areas.";
    };
    trimContentBehindMediaEditsEnabled = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames itemOverlapModes));
      default = null;
      description = "Overlap and crossfade when editing with 'trim content behind media items' enabled.";
    };
    trimContentBehindRazorEditsEnabled = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames itemOverlapModes));
      default = null;
      description = "Overlap and crossfade when editing with 'trim content behind razor edits' enabled.";
    };

    limitSplitCreatedFadeCrossfadeTo = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether splits limit created fade/crossfade lengths to a fixed number of pixels instead of a percentage of the visible arrange view.";
      };
      pixels = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Maximum fade/crossfade length created by splits, in pixels.";
      };
    };
    rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Right-click a fade or crossfade to change the fade shape. For a crossfade, right-click can change the shape of both sides, or one side only.";
    };
    applyFadeInFadeOutCrossfadePreferencesToMidiItems = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Apply the above fade/crossfade settings, and the project auto-crossfade setting, to MIDI items. Fades on MIDI items affect note velocities, not MIDI volume.";
    };
    defaultStretchMarkerFadeSizeForNewItem = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      description = "Default stretch marker crossfade size for new items, in milliseconds. Change existing items through media item properties.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.project.itemFadeDefaults.defaultFadeInFadeOutLength";
        value = cfg.defaultFadeInFadeOutLength;
        section = "reaper";
        key = "deffadelen";
        codec = "float";
      }
      {
        path = "preferences.project.itemFadeDefaults.defaultCrossfadeLength";
        value = cfg.defaultCrossfadeLength;
        section = "reaper";
        key = "defsplitxfadelen";
        codec = "float";
      }
      {
        path = "preferences.project.itemFadeDefaults.defaultFadeInFadeOutShape";
        value = cfg.defaultFadeInFadeOutShape;
        section = "reaper";
        key = "deffadeshape";
        codec = reaperCodecs.enum fadeInOutShapes;
      }
      {
        path = "preferences.project.itemFadeDefaults.defaultCrossfadeShape";
        value = cfg.defaultCrossfadeShape;
        section = "reaper";
        key = "defxfadeshape";
        codec = reaperCodecs.enum crossfadeShapes;
      }
      {
        path = "preferences.project.itemFadeDefaults.limitSplitCreatedFadeCrossfadeTo.pixels";
        value = cfg.limitSplitCreatedFadeCrossfadeTo.pixels;
        section = "reaper";
        key = "splitmaxpix";
        codec = "integer";
      }
      {
        path = "preferences.project.itemFadeDefaults.defaultStretchMarkerFadeSizeForNewItem";
        value = cfg.defaultStretchMarkerFadeSizeForNewItem;
        section = "reaper";
        key = "stretchmarkerfade";
        codec = "float";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      splitautoxfade = [
        {
          optionPath = "preferences.project.itemFadeDefaults.importedMediaItems.fadeInFadeOut";
          gui = "Automatically fade-in/fade-out imported media items";
          option = cfg.importedMediaItems.fadeInFadeOut;
          mask = 65568;
          falseValue = 32;
          trueValue = 65536;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.recordedMediaItems.fadeInFadeOut";
          gui = "Automatically fade-in/fade-out newly recorded media items";
          option = cfg.recordedMediaItems.fadeInFadeOut;
          bit = 16384;
          inverted = true;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.splitMediaItems.fadeInFadeOut";
          gui = "Automatically fade-in/fade-out media items created by splitting";
          option = cfg.splitMediaItems.fadeInFadeOut;
          bit = 8;
          inverted = true;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.recordedMediaItems.overlap";
          gui = "When recording and new recording overlaps existing media items";
          option = cfg.recordedMediaItems.overlap;
          mask = 3072;
          valueFor = mode: recordedItemOverlapValues.${mode};
          importValues = recordedItemOverlapValues;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.splitMediaItems.overlap";
          gui = "When splitting media items";
          option = cfg.splitMediaItems.overlap;
          mask = 513;
          valueFor = mode: splitItemOverlapValues.${mode};
          importValues = splitItemOverlapValues;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.splitMediaItems.overlapCrossfadePosition";
          gui = "Crossfade position when splitting media items";
          option = cfg.splitMediaItems.overlapCrossfadePosition;
          mask = 393216;
          valueFor = position: splitCrossfadePositionValues.${position};
          importValues = splitCrossfadePositionValues;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.fixedLaneCompAreas";
          gui = "Fade-in/fade-out/crossfade fixed lane comp areas";
          option = cfg.fixedLaneCompAreas;
          bit = 128;
          inverted = true;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.trimContentBehindMediaEditsEnabled";
          gui = "When 'trim content behind media edits' is enabled";
          option = cfg.trimContentBehindMediaEditsEnabled;
          mask = 12288;
          valueFor = mode: trimContentBehindMediaEditsValues.${mode};
          importValues = trimContentBehindMediaEditsValues;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.trimContentBehindRazorEditsEnabled";
          gui = "When 'trim content behind razor edits' is enabled";
          option = cfg.trimContentBehindRazorEditsEnabled;
          mask = 32832;
          valueFor = mode: trimContentBehindRazorEditsValues.${mode};
          importValues = trimContentBehindRazorEditsValues;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.limitSplitCreatedFadeCrossfadeTo.enable";
          gui = "Limit split-created fade/crossfade length to a fixed number of pixels";
          option = cfg.limitSplitCreatedFadeCrossfadeTo.enable;
          bit = 256;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade";
          gui = "Right-click on crossfade sets fade shape for only one side of the crossfade";
          option = cfg.rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade;
          bit = 16;
        }
        {
          optionPath = "preferences.project.itemFadeDefaults.applyFadeInFadeOutCrossfadePreferencesToMidiItems";
          gui = "Apply fade-in/fade-out/crossfade preferences to MIDI items";
          option = cfg.applyFadeInFadeOutCrossfadePreferencesToMidiItems;
          bit = 2;
        }
      ];
    });
}
