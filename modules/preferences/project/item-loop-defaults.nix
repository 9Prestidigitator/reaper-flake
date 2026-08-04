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

  cfg = config.programs.reaper.preferences.project.itemLoopDefaults;
in {
  options.programs.reaper.preferences.project.itemLoopDefaults = {
    loopSourceFor = {
      importedItems = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable the 'loop source' attribute for imported media items. Dragging the right edge of the item will automatically loop the media.";
      };
      midiItems = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable the 'loop source' attribute for new MIDI items. Dragging the right edge of the item will automatically loop the media.";
      };
      recordedItems = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable the 'loop source' attribute for recorded audio items. Dragging the right edge of the item will automatically loop the media.";
      };
      gluedItems = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable the 'loop source' attribute for glued items. Dragging the right edge of the item will automatically loop the media.";
      };
    };
    timeSelectionAutoPunchAudioRecordingCreatesLoopableSelection = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "When auto-punch recording into a time selection, loop the time selection's content when extending the edges of the resulting item.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
    ];
}
