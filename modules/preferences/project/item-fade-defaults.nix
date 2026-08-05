{
  config,
  lib,
  reaperLib,
  reaperProject,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperCodecs reaperPreference reaperTypes;
  inherit (reaperProject) crossfadePositions crossfadeShapes fadeInOutShapes itemOverlapModes;

  cfg = config.programs.reaper.preferences.project.itemFadeDefaults;
in {
  options.programs.reaper.preferences.project.itemFadeDefaults = {
    defaultFadeInFadeOut = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 1.0;
      description = "The default fade-in/fade-out length.";
    };
    defaultCrossfade = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 1.0;
      description = "The default crossfade length.";
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
      type = types.nullOr (types.enum (builtins.attrNames itemOverlapModes));
      default = null;
      description = "Overlap and crossfade when editing fixed-lane comp areas.";
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

  config.programs.reaper.ini.contributions = reaperPreference.contributions [
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
  ];
}
