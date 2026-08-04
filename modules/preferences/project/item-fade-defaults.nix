{
  config,
  lib,
  reaperLib,
  reaperProject,
  ...
}: let
  inherit (lib) mkOption types mkEnableOption;
  inherit (reaperLib) reaperBitfield reaperTypes reaperPreference reaperCodecs;
  inherit (reaperProject);

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
      type = types.nullOr;
      default = null;
      description = "";
    };
    defaultCrossfadeShape = mkOption {
      type = types.nullOr;
      default = null;
      description = "";
    };
    importedMediaItems = mkOption {
      type = types.nullOr;
      default = null;
      description = "";
    };
    recordedMediaItems = mkOption {
      type = types.nullOr;
      default = null;
      description = "";
    };
    splitMediaItems = mkOption {
      type = types.nullOr;
      default = null;
      description = "";
    };
    fixedLaneCompAreas = mkOption {
      type = types.nullOr;
      default = null;
      description = "";
    };
    trimContentBehindMediaEditsEnabled = mkOption {
      type = types.nullOr;
      default = null;
      description = "Overlap and crossfade when editing with 'trim content behind media items' enabled";
    };
    trimContentBehindRazorEditsEnabled = mkOption {
      type = types.nullOr;
      default = null;
      description = "Overlap and crossfade when editing with 'trim content behind razor edits' enabled";
    };
    limitSplitCreatedFadeCrossfadeTo = {
      enable = mkEnableOption "When splits create fades/crossfades, limit the fade length in pixels. Otherwise, the fade length is limited to a percentage of the visible arrange view area.";
      pixels = mkOption {
        type = types.nullOr;
        default = null;
        description = "Integer representing pixels.";
      };
    };
    rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade = mkOption {
      type = types.nullOr;
      default = null;
      description = "Right-click a fade or crossfade to change the fade shape. For a crossfade, right-click can change the shape of both sides, or one side only.";
    };
    applyFadeInFadeOutCrossfadePreferencesToMidiItems = mkOption {
      type = types.nullOr;
      default = null;
      description = "Apply the above fade/crossfade settings, and the project auto-crossfade setting, to MIDI items. Fades on MIDI items affect note velocities, not MIDI volume.";
    };
    defaultStretchMarkerFadeSizeForNewItem = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Default stretch marker crossfade size for new items (in milliseconds).  Change existing items via media item properties.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
    ];
}
