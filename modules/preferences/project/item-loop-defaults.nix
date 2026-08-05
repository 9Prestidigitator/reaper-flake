{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield;

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
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When auto-punch recording into a time selection, loop the time selection's content when extending the edges of the resulting item.";
    };
  };

  config.programs.reaper.ini.contributions =
    map (entry: entry // {section = "reaper";})
    (reaperBitfield.contributions {
      loopnewitems = [
        {
          optionPath = "preferences.project.itemLoopDefaults.loopSourceFor.midiItems";
          gui = "Loop source for MIDI items";
          option = cfg.loopSourceFor.midiItems;
          bit = 2;
        }
        {
          optionPath = "preferences.project.itemLoopDefaults.loopSourceFor.importedItems";
          gui = "Loop source for imported items";
          option = cfg.loopSourceFor.importedItems;
          bit = 4;
          inverted = true;
        }
        {
          optionPath = "preferences.project.itemLoopDefaults.loopSourceFor.recordedItems";
          gui = "Loop source for recorded items";
          option = cfg.loopSourceFor.recordedItems;
          bit = 8;
        }
        {
          optionPath = "preferences.project.itemLoopDefaults.loopSourceFor.gluedItems";
          gui = "Loop source for glued items";
          option = cfg.loopSourceFor.gluedItems;
          bit = 32;
          inverted = true;
        }
        {
          optionPath = "preferences.project.itemLoopDefaults.timeSelectionAutoPunchAudioRecordingCreatesLoopableSelection";
          gui = "Time selection auto-punch audio recording creates loopable selection";
          option = cfg.timeSelectionAutoPunchAudioRecordingCreatesLoopableSelection;
          bit = 16;
        }
      ];
    });
}
