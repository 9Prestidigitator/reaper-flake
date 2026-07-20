{
  config,
  lib,
  reaperLib,
  ...
}: let
  cfg = config.programs.reaper.preferences.general.undo;

  inherit (lib) mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
in {
  options.programs.reaper.preferences.general.undo = {
    maximumUndoMemory = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 256;
      description = "Maxmimum undo memory (default: 256 MB). Enter 0 to disable the Undo function as well as the prompt to save modified projects on close.";
    };

    includeSelection = {
      item = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether item selections create undo points.";
      };
      track = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether track selections create undo points.";
      };
      envelopePoint = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether envelope-point selections create undo points.";
      };
      time = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether time-selection changes create undo points.";
      };
      cursorPosition = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether cursor-position changes create undo points.";
      };
      midiEvents = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether midi event changes create undo points.";
      };
    };

    keepNewestStateWhenApproachingMemoryLimit = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER keeps the newest undo state when the undo memory limit is approached.";
    };

    storeMultipleRedoPathsWhenPossible = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = false;
      description = "Whether REAPER stores multiple redo paths when possible.";
    };

    saveHistoryWithProjectFiles = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER saves undo history with project files in `.rpp-undo` files.";
    };

    allowLoadingHistory = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER is allowed to load saved undo history.";
    };

    showLastUndoPointInMenuBar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show the last user action in REAPER's menu bar.";
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.maximumUndoMemory != null) {
      undomaxmem = cfg.maximumUndoMemory;
    }
    // optionalAttrs (cfg.showLastUndoPointInMenuBar != null) {
      showlastundo = cfg.showLastUndoPointInMenuBar;
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    undomask = [
      {
        optionPath = "preferences.general.undo.includeSelection.item";
        gui = "Include selection: item";
        option = cfg.includeSelection.item;
        bit = 1;
      }
      {
        optionPath = "preferences.general.undo.includeSelection.time";
        gui = "Include selection: time selection";
        option = cfg.includeSelection.time;
        bit = 2;
      }
      {
        optionPath = "preferences.general.undo.keepNewestStateWhenApproachingMemoryLimit";
        gui = "When approaching full undo memory, keep newest state";
        option = cfg.keepNewestStateWhenApproachingMemoryLimit;
        bit = 4;
      }
      {
        optionPath = "preferences.general.undo.includeSelection.cursorPosition";
        gui = "Include selection: cursor position";
        option = cfg.includeSelection.cursorPosition;
        bit = 8;
      }
      {
        optionPath = "preferences.general.undo.includeSelection.track";
        gui = "Include selection: track";
        option = cfg.includeSelection.track;
        bit = 16;
      }
      {
        optionPath = "preferences.general.undo.includeSelection.envelopePoint";
        gui = "Include selection: envelope points";
        option = cfg.includeSelection.envelopePoint;
        bit = 32;
      }
      {
        optionPath = "preferences.general.undo.includeSelection.midiEvents";
        gui = "Include selection: MIDI events";
        option = cfg.includeSelection.midiEvents;
        bit = 128;
      }
    ];

    saveundostatesproj = [
      {
        optionPath = "preferences.general.undo.saveHistoryWithProjectFiles";
        gui = "Save undo history with project files";
        option = cfg.saveHistoryWithProjectFiles;
        bit = 1;
      }
      {
        optionPath = "preferences.general.undo.allowLoadingHistory";
        gui = "Allow load of undo history";
        option = cfg.allowLoadingHistory;
        bit = 4;
        inverted = true;
      }
      {
        optionPath = "preferences.general.undo.storeMultipleRedoPathsWhenPossible";
        gui = "Store multiple redo paths when possible";
        option = cfg.storeMultipleRedoPathsWhenPossible;
        bit = 256;
      }
    ];
  };
}
