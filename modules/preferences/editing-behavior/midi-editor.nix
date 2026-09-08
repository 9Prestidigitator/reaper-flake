{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption types;
  inherit (reaperLib) reaperBitfield reaperPreference reaperTypes reaperEditingBehavior;

  cfg = config.programs.reaper.preferences.editingBehavior.midiEditor;
in {
  options.programs.reaper.preferences.editingBehavior.midiEditor = {
    flashMidiEditorKeysOnTrackInput = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show a brief color flash on the MIDI editor keyboard when the track receives MIDI note-on input.";
    };
    horizontalGridLinesInCcLanes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show horizontal grid lines in CC lanes in MIDI editor, height permitting.";
    };
    eventsPerQuarterNoteWhenDrawingCcLanes = {
      value = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 32;
        description = "Set the midi event density when drawing in CC lanes with the mouse.";
      };
      zoomDependent = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "CC event drawing density will be greater when the view is zoomed in, and lower when zoomed out.";
      };
    };
    defaultShapeForCcSegment = {
      shape = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames reaperEditingBehavior.segmentShape));
        default = null;
        example = literalExpression "reaperEditingBehavior.segmentShape.square";
        description = "When adding a new segment to a CC lane, use this segment shape.";
      };
      reduceCcEventsWhenDrawing = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Automatically reduce events when drawing, if the segment shape is square or linear.";
      };
    };

    displayEmptySpaceAtTopBottomOfCcLanes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Add some empty space at the top and bottom of CC lanes, to make it easier to edit values close to the minimum/maximum value.";
    };
    preventMouseEditsOfSingleCcEventsFromMovingPastOtherEvents = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When editing a single CC event with the mouse, the edit can be constrained to the space between adjacent CC events.";
    };

    oneMidiEditorPer = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames reaperEditingBehavior.midiEditorPer));
      default = null;
      example = literalExpression "reaperEditingBehavior.midiEditorPer.track";
      description = ''
        By default, double-clicking a MIDI media item in the arrange view will open the MIDI editor, or change the active MIDI item in the editor.
        If you prefer to use a separate MIDI editor for each MIDI media item, or for each track, change the settings on this page.
        Once the MIDI editor is open, you can use the MIDI editor track list (MIDI editor Contents menu/Track list) to choose which tracks or items to display or edit.
        Within a single MIDI editor, only one media item can be active, meaning that it can receive drawn or copy/pasted notes and CC data.
        MIDI from other media items may be faintly visible, and optionally editable.  Use the MIDI editor track list or media item lane to control which items are visible and editable.
        You can switch the active MIDI media item by double-clicking within the bounds of a secondary media item, or by using the MIDI editor contents menu, the MIDI editor track list, or the MIDI editor media item lane.
      '';
    };
    behaviorForOpenItemsInBuiltInMidiEditor = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames reaperEditingBehavior.openItemsInBuiltInMidiEditor));
      default = null;
      example = literalExpression "reaperEditingBehavior.openItemsInBuiltInMidiEditor.openAllMidiOnTheSameTrack";
      description = "Set the default behavior when double-clicking a MIDI media item.";
    };

    whenUsingOneMidiEditorPerProject = {
      activeMidiItemFollowsSelectionChangesInArrangeView = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "The active MIDI item in the MIDI editor can follow the media item or track selection in the arrange view, or neither.";
        };
        type = mkOption {
          type = types.nullOr (types.enum (builtins.attrNames reaperEditingBehavior.arrangeSelection));
          default = null;
          example = literalExpression "reaperEditingBehavior.arrangeSelection.track";
          description = "The active MIDI item in the MIDI editor can follow the media item or track selection in the arrange view, or neither.";
        };
      };
      selectionIsLinkedToVisibility = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Media item selection in the arrange view can determine whether a MIDI item is visible in the MIDI editor.";
      };
      selectionIsLinkedToEditability = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Media item selection in the arrange view can determine whether a MIDI item is editable in the MIDI editor.";
      };
      closeEditorWhenTheActiveItemIsDeletedInTheArrangeView = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "When displaying multiple MIDI media items in a single editor, the editor can be set to remain open if the active media item is deleted.";
      };
    };

    makeAllMidiItemsEditableByDefaultIfTheyAreVisibleInTheEditor = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
    };
    avoid = {
      settingItemsOnOtherTracksEditable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "By default all displaying MIDI items can be editable, or only those on the same track.";
      };
      settingItemsOnNonPlayingLanesVisible = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "By default MIDI items on non-playing track fixed lanes can be visible, or only those on lanes that are playing back.";
      };
    };
    doubleClickOutsideTheBoundsOfAnyMediaItemToExtendTheNearestMedia = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When displaying multiple media items at once, choose how to switch the active media item with the MIDI editor.";
    };

    opacityOfInactiveSecondaryItem = mkOption {
      type = types.nullOr types.number;
      default = null;
      example = 0.25;
      description = "MIDI notes/CC in inactive media items can be drawn more or less faintly (0-1, default is 0.25).";
    };
    editableSecondaryItems = mkOption {
      type = types.nullOr types.number;
      default = null;
      example = 0.75;
      description = "MIDI notes/CC in secondary editable media items can be drawm more or less faintly (0-1, default is 0.75).";
    };

    defaultNoteColorMap = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/user/Documents/colormap";
      description = "Colormap image to use for drawing notes in the MIDI editor. If no colormap is specified here, the colormap in the current color theme will be used.";
    };
  };
}
