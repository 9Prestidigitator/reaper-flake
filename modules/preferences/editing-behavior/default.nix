{
  config,
  lib,
  reaperEditingBehavior,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;

  cfg = config.programs.reaper.preferences.editingBehavior;
in {
  imports = [
    ./mouse-modifiers.nix
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
  };
}
