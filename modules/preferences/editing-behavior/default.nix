{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption types;
  inherit (reaperLib) reaperBitfield reaperEditingBehavior reaperPreference reaperTypes;

  cfg = config.programs.reaper.preferences.editingBehavior;
in {
  imports = [
    ./mouse-modifiers.nix
    ./midi-editor.nix
  ];

  options.programs.reaper.preferences.editingBehavior = {
    moveEditCursorOn = {
      timeSelectionChange = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "The edit cursor (where playback will begin) moves to the start of the time selection when you change the time selection.";
      };
      razorEditChange = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "The edit cursor (where playback will begin) moves to the start of the razor edit when you create the razor editor move it without contents.";
      };
      pastingInsertingMedia = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "The edit cursor (where playback will begin) moves to the mouse when pasting or inserting media items.";
      };
      clickingFixedLaneCompArea = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "The edit cursor (where playback will begin) moves to start of the fixed lane comp area when you click the area.";
      };
    };

    moveEditCursorToEndOfRecordedItemsOnRecordStop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "The edit cursor (where playback will begin) moves to the end of newly recorded items when recording stops.";
    };
    linkLoopPointsToTimeSelection = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Time selection and loop points can be linked, or unlinked so that they can be set or cleared independently.";
    };
    clearLoopPointsOnClickInRuler = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Loop points are cleared using the escape key, or optionally by single-clicking in the ruler/timeline area.";
    };
    clearTimeSelectionWhenEditCursorMovesOnClickInArrangeView = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "The time selection is cleared using the escape key, or optionally whenever a mouse click in the arrange view moves the edit cursor.";
    };

    minimumTimeSelectionLoopRazorEditLength = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 15;
      description = "Contrain the mouse-edited time selection, loop, and razor edit length to a minimum pixel size.";
    };

    transientDetection = {
      settings = {
        sensitivity = mkOption {
          type = types.nullOr reaperTypes.percentage.sensitivity;
          default = null;
          example = 0.5;
          description = "Sensitivity used by tab-to-transient and dynamic split, from 0 to 1.";
        };
        threshold = mkOption {
          type = types.nullOr reaperTypes.number;
          default = null;
          example = -24.0;
          description = "Threshold used by tab-to-transient and dynamic split, in dB.";
        };
        useZeroCrossing = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Move detected transients to the nearest zero crossing.";
        };
        displayThresholdInMediaItemsWhileThisWindowIsOpen = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Display the transient-detection threshold in media items while the transient settings window is open.";
        };
        mediaItemSelectionFollowsTabToTransition = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Make media item selection follow tab-to-transient navigation.";
        };
        moveByAtLeast1PixelWhenNavigatingByTransient = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Move by at least one pixel when navigating between transients.";
        };
      };
      tabThroughMidiNotes = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Tab-to-transient can ignore MIDI items, or consider MIDI notes as transients.";
      };
      treatMediaItemEdgesAsTransient = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Tab-to-transient can tab past media items edges, or consider media item edges as transients.";
      };
    };

    clearExistingMediaItemEnvelopeSelectionWhenCreatingRazorEditArea = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When creating a razor edit area, existing media item and envelope selection can be cleared, or preserved.";
    };
    allowDualTrimOnlyIfBothItemsAreSelected = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Media item edges between adjacent items can trim both items at once. This behavior can be restricted so both items are edited only if both are selected.";
    };
    crossfadesStayTogetherDuringFadeEditsWhenTrimContentBehindMediaItemsIsEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When auto-crossfades (toolbar button) are disabled, normally editing a crossfade will cause the fade-in and fade-out to separate.";
    };
    automaticallyDeleteEmptyTracksCreatedByDraggingItemsBelowTheLastTrackAndBack = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Tracks that are automatically created when dragging media into empty space below the last track can be automatically deleted if not used.";
    };
    draggingTheSourceStartOffsetOfTheActiveTakeAdjustsTheOffsetForAllTakes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When using mouse modifiers like 'move item contents', the edit can be applied to only the take being edited, or to all takes in the same media item.";
    };
    ifNoItemsAreSelectedSomeSplitTrimDeleteActionsAffectAllItemsAtTheEditCursor = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Actions to split, trim, or delete media items can affect all media items that intersect the edit cursor, if no media items are selected.";
    };
    stretchingRazorEditAreaAddsStretchMarkersToAudioItems = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When stretching a razor edit area edge that falls within an audio media item, either stretch markers can be added, or the item can be split.";
    };
    normalizeActionsAffectAllTakesWithinAMediaItem = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Actions to normalize media items affect only the active take by default, but can affect all takes within the media item.";
    };
    automaticallyZoomToTimeSelectionWhenRunningSampleEditActions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Actions like 'Sample edits: Set sample values to zero' can automatically zoom in, to enable sample editing with the mouse if needed.";
    };
    automaticallySelectRegionsMarkersWhenNavigatingViaActionOrJumpToTimeDialog = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Actions like 'go to next marker' or jumping via Jump To Time dialog can automatically select the region/markers that is navigated to.";
    };

    takeMarkerRankingLevels = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames reaperEditingBehavior.takeMarkerRankingLevels));
      default = null;
      example = literalExpression "reaperEditingBehavior.takeMarkerRankingLevels.threeUpOneDown";
      description = "Take markers can be up-ranked or down-ranked. The maximum number of ranking levels is set here.";
    };
    upDownCycleActionsSkipNoRanking = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Actions to up-rank, down-rank, or cycle through rankings can either include or skip setting the take to have no ranking.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.editingBehavior.linkLoopPointsToTimeSelection";
        gui = "Link loop points to time selection";
        value = cfg.linkLoopPointsToTimeSelection;
        section = "reaper";
        key = "locklooptotime";
        codec = "bool";
      }
      {
        path = "preferences.editingBehavior.minimumTimeSelectionLoopRazorEditLength";
        gui = "Minimum time selection/loop/razor edit length";
        value = cfg.minimumTimeSelectionLoopRazorEditLength;
        section = "reaper";
        key = "minlooppx";
        codec = "integer";
      }
      {
        path = "preferences.editingBehavior.transientDetection.settings.sensitivity";
        gui = "Transient detection sensitivity";
        value = cfg.transientDetection.settings.sensitivity;
        section = "reaper";
        key = "transientsensitivity";
        codec = "float";
      }
      {
        path = "preferences.editingBehavior.transientDetection.settings.threshold";
        gui = "Transient detection threshold";
        value = cfg.transientDetection.settings.threshold;
        section = "reaper";
        key = "transientthreshold";
        codec = "float";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      itemclickmovecurs = [
        {
          optionPath = "preferences.editingBehavior.moveEditCursorOn.timeSelectionChange";
          gui = "Move edit cursor on time selection change";
          option = cfg.moveEditCursorOn.timeSelectionChange;
          bit = 1;
        }
        {
          optionPath = "preferences.editingBehavior.moveEditCursorOn.razorEditChange";
          gui = "Move edit cursor on razor edit change";
          option = cfg.moveEditCursorOn.razorEditChange;
          bit = 512;
        }
        {
          optionPath = "preferences.editingBehavior.moveEditCursorOn.pastingInsertingMedia";
          gui = "Move edit cursor when pasting/inserting media";
          option = cfg.moveEditCursorOn.pastingInsertingMedia;
          bit = 8;
          inverted = true;
        }
        {
          optionPath = "preferences.editingBehavior.moveEditCursorOn.clickingFixedLaneCompArea";
          gui = "Move edit cursor when clicking fixed lane comp area";
          option = cfg.moveEditCursorOn.clickingFixedLaneCompArea;
          bit = 1024;
        }
        {
          optionPath = "preferences.editingBehavior.moveEditCursorToEndOfRecordedItemsOnRecordStop";
          gui = "Move edit cursor to end of recorded items on record stop";
          option = cfg.moveEditCursorToEndOfRecordedItemsOnRecordStop;
          bit = 16;
        }
        {
          optionPath = "preferences.editingBehavior.clearLoopPointsOnClickInRuler";
          gui = "Clear loop points on click in ruler";
          option = cfg.clearLoopPointsOnClickInRuler;
          bit = 32;
        }
        {
          optionPath = "preferences.editingBehavior.clearTimeSelectionWhenEditCursorMovesOnClickInArrangeView";
          gui = "Clear time selection when edit cursor moves on click in arrange view";
          option = cfg.clearTimeSelectionWhenEditCursorMovesOnClickInArrangeView;
          bit = 64;
        }
        {
          optionPath = "preferences.editingBehavior.automaticallyDeleteEmptyTracksCreatedByDraggingItemsBelowTheLastTrackAndBack";
          gui = "Automatically delete empty tracks created by dragging items below the last track and back";
          option = cfg.automaticallyDeleteEmptyTracksCreatedByDraggingItemsBelowTheLastTrackAndBack;
          bit = 128;
        }
      ];
      tabtotransflag = [
        {
          optionPath = "preferences.editingBehavior.transientDetection.tabThroughMidiNotes";
          gui = "Tab through MIDI notes";
          option = cfg.transientDetection.tabThroughMidiNotes;
          bit = 1;
        }
        {
          optionPath = "preferences.editingBehavior.transientDetection.settings.useZeroCrossing";
          gui = "Use zero crossings";
          option = cfg.transientDetection.settings.useZeroCrossing;
          bit = 2;
        }
        {
          optionPath = "preferences.editingBehavior.transientDetection.settings.displayThresholdInMediaItemsWhileThisWindowIsOpen";
          gui = "Display threshold in media items while this window is open";
          option = cfg.transientDetection.settings.displayThresholdInMediaItemsWhileThisWindowIsOpen;
          bit = 4;
        }
        {
          optionPath = "preferences.editingBehavior.transientDetection.settings.mediaItemSelectionFollowsTabToTransition";
          gui = "Media item selection follows tab-to-transient";
          option = cfg.transientDetection.settings.mediaItemSelectionFollowsTabToTransition;
          bit = 8;
        }
        {
          optionPath = "preferences.editingBehavior.transientDetection.treatMediaItemEdgesAsTransient";
          gui = "Treat media item edges as transients";
          option = cfg.transientDetection.treatMediaItemEdgesAsTransient;
          bit = 16;
        }
        {
          optionPath = "preferences.editingBehavior.transientDetection.settings.moveByAtLeast1PixelWhenNavigatingByTransient";
          gui = "Move by at least 1 pixel when navigating by transients";
          option = cfg.transientDetection.settings.moveByAtLeast1PixelWhenNavigatingByTransient;
          bit = 32;
        }
      ];
      areasel = [
        {
          optionPath = "preferences.editingBehavior.clearExistingMediaItemEnvelopeSelectionWhenCreatingRazorEditArea";
          gui = "Clear existing media item/envelope selection when creating razor edit area";
          option = cfg.clearExistingMediaItemEnvelopeSelectionWhenCreatingRazorEditArea;
          bit = 4;
        }
        {
          optionPath = "preferences.editingBehavior.stretchingRazorEditAreaAddsStretchMarkersToAudioItems";
          gui = "Stretching razor edit area adds stretch markers to audio items";
          option = cfg.stretchingRazorEditAreaAddsStretchMarkersToAudioItems;
          bit = 1;
        }
      ];
      relativeedges = [
        {
          optionPath = "preferences.editingBehavior.allowDualTrimOnlyIfBothItemsAreSelected";
          gui = "Allow dual trim only if both items are selected";
          option = cfg.allowDualTrimOnlyIfBothItemsAreSelected;
          bit = 32;
        }
        {
          optionPath = "preferences.editingBehavior.draggingTheSourceStartOffsetOfTheActiveTakeAdjustsTheOffsetForAllTakes";
          gui = "Dragging the source start offset of the active take adjusts the offset for all takes";
          option = cfg.draggingTheSourceStartOffsetOfTheActiveTakeAdjustsTheOffsetForAllTakes;
          bit = 128;
        }
        {
          optionPath = "preferences.editingBehavior.ifNoItemsAreSelectedSomeSplitTrimDeleteActionsAffectAllItemsAtTheEditCursor";
          gui = "If no items are selected, some split/trim/delete actions affect all items at the edit cursor";
          option = cfg.ifNoItemsAreSelectedSomeSplitTrimDeleteActionsAffectAllItemsAtTheEditCursor;
          bit = 256;
        }
        {
          optionPath = "preferences.editingBehavior.normalizeActionsAffectAllTakesWithinAMediaItem";
          gui = "Normalize actions affect all takes within a media item";
          option = cfg.normalizeActionsAffectAllTakesWithinAMediaItem;
          bit = 16384;
        }
        {
          optionPath = "preferences.editingBehavior.automaticallyZoomToTimeSelectionWhenRunningSampleEditActions";
          gui = "Automatically zoom to time selection when running sample edit actions";
          option = cfg.automaticallyZoomToTimeSelectionWhenRunningSampleEditActions;
          bit = 262144;
        }
      ];
      splitautoxfade = [
        {
          optionPath = "preferences.editingBehavior.crossfadesStayTogetherDuringFadeEditsWhenTrimContentBehindMediaItemsIsEnabled";
          gui = "Crossfades stay together during fade edits when trim content behind media items is enabled";
          option = cfg.crossfadesStayTogetherDuringFadeEditsWhenTrimContentBehindMediaItemsIsEnabled;
          bit = 4;
        }
      ];
      rulerlayout = [
        {
          optionPath = "preferences.editingBehavior.automaticallySelectRegionsMarkersWhenNavigatingViaActionOrJumpToTimeDialog";
          gui = "Automatically select regions/markers when navigating via action or Jump To Time dialog";
          option = cfg.automaticallySelectRegionsMarkersWhenNavigatingViaActionOrJumpToTimeDialog;
          bit = 2;
        }
      ];
      itemranks = [
        {
          optionPath = "preferences.editingBehavior.takeMarkerRankingLevels";
          gui = "Take marker ranking levels";
          option = cfg.takeMarkerRankingLevels;
          mask = 31;
          valueFor = value: reaperEditingBehavior.takeMarkerRankingLevels.${value};
          importValues = reaperEditingBehavior.takeMarkerRankingLevels;
        }
        {
          optionPath = "preferences.editingBehavior.upDownCycleActionsSkipNoRanking";
          gui = "Up/down/cycle actions skip 'no ranking'";
          option = cfg.upDownCycleActionsSkipNoRanking;
          bit = 256;
          inverted = true;
        }
      ];
    });
}
