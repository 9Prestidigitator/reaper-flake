{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption types;
  inherit (reaperLib) reaperBitfield reaperPreference reaperTypes reaperEditingBehavior;

  cfg = config.programs.reaper.preferences.editingBehavior.midiEditor;
  ccDensity = cfg.eventsPerQuarterNoteWhenDrawingCcLanes;
  ccDensityValue =
    if ccDensity.value != null
    then ccDensity.value
    else 32;
  ccDensityConfigured = ccDensity.value != null || ccDensity.zoomDependent != null;

  wrapNibble = value:
    if value < 0
    then value + 16
    else value;
  opacityStep = value: builtins.floor (value * 16.0 + 0.5);
  opacityAssignments = optionPath: offset: unit:
    builtins.listToAttrs (map (encoded: let
        unwrapped = encoded + offset;
        step =
          if unwrapped > 16
          then unwrapped - 16
          else unwrapped;
      in {
        name = toString (encoded * unit);
        value = {${optionPath} = step / 16.0;};
      })
      (lib.range 0 15));
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
        type = types.nullOr types.ints.positive;
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
        type = types.nullOr (reaperTypes.namedEnum reaperEditingBehavior.segmentShape);
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
      type = types.nullOr (reaperTypes.namedEnum reaperEditingBehavior.midiEditorPer);
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
      type = types.nullOr (reaperTypes.namedEnum reaperEditingBehavior.openItemsInBuiltInMidiEditor);
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
          type = types.nullOr (reaperTypes.namedEnum reaperEditingBehavior.arrangeSelection);
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
      type = types.nullOr (reaperTypes.boundedNumber "MIDI item opacity between 0.0625 and 1" 0.0625 1);
      default = null;
      example = 0.25;
      description = "MIDI notes/CC in inactive media items can be drawn more or less faintly (0.0625-1, default is 0.25).";
    };
    editableSecondaryItems = mkOption {
      type = types.nullOr (reaperTypes.boundedNumber "MIDI item opacity between 0.0625 and 1" 0.0625 1);
      default = null;
      example = 0.75;
      description = "MIDI notes/CC in secondary editable media items can be drawn more or less faintly (0.0625-1, default is 0.75).";
    };

    defaultNoteColorMap = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/user/Documents/colormap";
      description = "Colormap image to use for drawing notes in the MIDI editor. If no colormap is specified here, the colormap in the current color theme will be used.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.editingBehavior.midiEditor.eventsPerQuarterNoteWhenDrawingCcLanes.value";
        value = ccDensityValue;
        configured = ccDensityConfigured;
        section = "reaper";
        key = "midiccdensity";
        codec = {
          type = "signed-integer";
          negative = ccDensity.zoomDependent == true;
          decode = "absolute";
        };
      }
      {
        path = "preferences.editingBehavior.midiEditor.eventsPerQuarterNoteWhenDrawingCcLanes.zoomDependent";
        value = ccDensityValue;
        configured = ccDensityConfigured;
        section = "reaper";
        key = "midiccdensity";
        codec = {
          type = "signed-integer";
          negative = ccDensity.zoomDependent == true;
          decode = "negative";
        };
      }
      {
        path = "preferences.editingBehavior.midiEditor.defaultNoteColorMap";
        value = cfg.defaultNoteColorMap;
        section = "reaper";
        key = "mididefcolormap";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      midivu = [
        {
          optionPath = "preferences.editingBehavior.midiEditor.flashMidiEditorKeysOnTrackInput";
          gui = "Flash MIDI editor keys on track input";
          option = cfg.flashMidiEditorKeysOnTrackInput;
          bit = 4;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.horizontalGridLinesInCcLanes";
          gui = "Horizontal grid lines in CC lanes";
          option = cfg.horizontalGridLinesInCcLanes;
          bit = 8;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.displayEmptySpaceAtTopBottomOfCcLanes";
          gui = "Display empty space at top/bottom of CC lanes";
          option = cfg.displayEmptySpaceAtTopBottomOfCcLanes;
          bit = 128;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.doubleClickOutsideTheBoundsOfAnyMediaItemToExtendTheNearestMedia";
          gui = "Double-click outside the bounds of any media item to extend the nearest media item";
          option = cfg.doubleClickOutsideTheBoundsOfAnyMediaItemToExtendTheNearestMedia;
          bit = 256;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.opacityOfInactiveSecondaryItem";
          gui = "Opacity of inactive secondary items";
          option = cfg.opacityOfInactiveSecondaryItem;
          mask = 251658240;
          valueFor = value: 16777216 * wrapNibble (opacityStep value - 4);
          importAssignments = opacityAssignments "preferences.editingBehavior.midiEditor.opacityOfInactiveSecondaryItem" 4 16777216;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.editableSecondaryItems";
          gui = "Editable secondary items opacity";
          option = cfg.editableSecondaryItems;
          mask = 15728640;
          valueFor = value: 1048576 * wrapNibble (opacityStep value - 12);
          importAssignments = opacityAssignments "preferences.editingBehavior.midiEditor.editableSecondaryItems" 12 1048576;
        }
      ];
      midiccenv = [
        {
          optionPath = "preferences.editingBehavior.midiEditor.defaultShapeForCcSegment.shape";
          gui = "Default shape for CC segments";
          option = cfg.defaultShapeForCcSegment.shape;
          mask = 7;
          valueFor = value: reaperEditingBehavior.segmentShape.${value};
          importValues = reaperEditingBehavior.segmentShape;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.defaultShapeForCcSegment.reduceCcEventsWhenDrawing";
          gui = "Reduce CC events when drawing";
          option = cfg.defaultShapeForCcSegment.reduceCcEventsWhenDrawing;
          bit = 16;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.preventMouseEditsOfSingleCcEventsFromMovingPastOtherEvents";
          gui = "Prevent mouse edits of single CC events from moving past other events";
          option = cfg.preventMouseEditsOfSingleCcEventsFromMovingPastOtherEvents;
          bit = 32;
        }
      ];
      midieditor = [
        {
          optionPath = "preferences.editingBehavior.midiEditor.oneMidiEditorPer";
          gui = "One MIDI editor per";
          option = cfg.oneMidiEditorPer;
          mask = 3;
          valueFor = value: reaperEditingBehavior.midiEditorPer.${value};
          importValues = reaperEditingBehavior.midiEditorPer;
          ignoredValues = [3];
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.behaviorForOpenItemsInBuiltInMidiEditor";
          gui = "Behavior for open items in built-in MIDI editor";
          option = cfg.behaviorForOpenItemsInBuiltInMidiEditor;
          mask = 20;
          valueFor = value: reaperEditingBehavior.openItemsInBuiltInMidiEditor.${value};
          importValues = reaperEditingBehavior.openItemsInBuiltInMidiEditor;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.whenUsingOneMidiEditorPerProject.activeMidiItemFollowsSelectionChangesInArrangeView.enable";
          gui = "Active MIDI item follows selection changes in arrange view";
          option = cfg.whenUsingOneMidiEditorPerProject.activeMidiItemFollowsSelectionChangesInArrangeView.enable;
          bit = 128;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.whenUsingOneMidiEditorPerProject.activeMidiItemFollowsSelectionChangesInArrangeView.type";
          gui = "Active MIDI item follows media item or track selection";
          option = cfg.whenUsingOneMidiEditorPerProject.activeMidiItemFollowsSelectionChangesInArrangeView.type;
          mask = 8192;
          valueFor = value: reaperEditingBehavior.arrangeSelection.${value} * 8192;
          importValues = builtins.mapAttrs (_: value: value * 8192) reaperEditingBehavior.arrangeSelection;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.whenUsingOneMidiEditorPerProject.selectionIsLinkedToVisibility";
          gui = "Selection is linked to visibility";
          option = cfg.whenUsingOneMidiEditorPerProject.selectionIsLinkedToVisibility;
          bit = 1024;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.whenUsingOneMidiEditorPerProject.selectionIsLinkedToEditability";
          gui = "Selection is linked to editability";
          option = cfg.whenUsingOneMidiEditorPerProject.selectionIsLinkedToEditability;
          bit = 512;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.whenUsingOneMidiEditorPerProject.closeEditorWhenTheActiveItemIsDeletedInTheArrangeView";
          gui = "Close editor when the active item is deleted in the arrange view";
          option = cfg.whenUsingOneMidiEditorPerProject.closeEditorWhenTheActiveItemIsDeletedInTheArrangeView;
          bit = 32;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.makeAllMidiItemsEditableByDefaultIfTheyAreVisibleInTheEditor";
          gui = "Make all MIDI items editable by default if they are visible in the editor";
          option = cfg.makeAllMidiItemsEditableByDefaultIfTheyAreVisibleInTheEditor;
          bit = 4096;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.avoid.settingItemsOnOtherTracksEditable";
          gui = "Avoid setting items on other tracks editable";
          option = cfg.avoid.settingItemsOnOtherTracksEditable;
          bit = 256;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.midiEditor.avoid.settingItemsOnNonPlayingLanesVisible";
          gui = "Avoid setting items on non-playing lanes visible";
          option = cfg.avoid.settingItemsOnNonPlayingLanesVisible;
          bit = 16384;
        }
      ];
    });
}
