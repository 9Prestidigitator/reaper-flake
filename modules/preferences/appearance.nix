{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib {inherit lib;};
  cfg = config.programs.reaper.preferences.appearance;
  number = types.either types.int types.float;
  boundedNumber = description: min: max:
    (types.addCheck number (value: value >= min && value <= max))
    // {
      inherit description;
    };
  maxVerticalZoom = boundedNumber "zoom percentage between 0.125 and 8" 0.125 8;
  envelopeVerticalZoom = boundedNumber "zoom percentage between 0 and 1000" 0 1000;
  scrollStep = boundedNumber "scroll step percentage between 0.01 and 1" 0.01 1;
  overlapOffset = types.ints.between 0 255;
  optionalBitfield = enabled: attrs:
    optionalAttrs enabled attrs;
  scroll = cfg.zoomScrollOffset;
  verticalScrollStep = scroll.verticalScrollStep;

  # vscrollflag is shared by Zoom/Scroll/Offset controls.
  # Mask 1 selects "% of arrange view height" for the vertical scroll step.
  # Mask 2 enables "limit horizontal zoom/scroll to project start".
  # Mask 4 disables mousewheel vertical zoom for pinned arrange-view tracks.

  vscrollflagMask =
    (if verticalScrollStep.unit != null then 1 else 0)
    + (if scroll.limitHorizontalZoomScrollToProjectStart != null then 2 else 0)
    + (if scroll.disableMousewheelVerticalZoomForTracksThatArePinnedInArrangeView != null then 4 else 0);
  vscrollflagValue =
    (if verticalScrollStep.unit == reaperLib.reaperAppearance.zoomScrollOffset.verticalScrollStep.units.arrangeViewHeight then 1 else 0)
    + (if scroll.limitHorizontalZoomScrollToProjectStart == true then 2 else 0)
    + (if scroll.disableMousewheelVerticalZoomForTracksThatArePinnedInArrangeView == true then 4 else 0);
  overlap = scroll.overlappingMediaItems;
  overlapMask =
    (if overlap.offset != null then 255 else 0)
    + (if overlap.drawAsOpaque != null then 256 else 0)
    + (if overlap.arrangeInCreationOrder != null then 512 else 0);
  overlapValue =
    (if overlap.offset != null then overlap.offset else 0)
    + (if overlap.drawAsOpaque == true then 256 else 0)
    + (if overlap.arrangeInCreationOrder == true then 512 else 0);
in {
  options.programs.reaper.preferences.appearance = {
    zoomScrollOffset = {
      verticalZoomCenter = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.zoomScrollOffset.zoomCenter.vertical));
        default = null;
        example = literalExpression "reaperAppearance.zoomScrollOffset.zoomCenter.vertical.lastSelectedTrack";
        description = ''
          Vertical zoom center in Zoom/Scroll/Offset menu in Appearance preferences menu. Null default is `Track at view center`.
        '';
      };
      maximumVerticalZoom = mkOption {
        type = types.nullOr maxVerticalZoom;
        default = null;
        example = 1.25;
        description = ''
          Maximum vertical zoom in Zoom/Scroll/Offset menu in Appearance preferences menu.
          Use a normalized percentage where `1.0` is `100%`. Null default is `100%`.
        '';
      };
      envelopeLaneVerticalZoom = mkOption {
        type = types.nullOr envelopeVerticalZoom;
        default = null;
        example = 0.32;
        description = ''
          Envelope lane vertical zoom in Zoom/Scroll/Offset menu in Appearance preferences menu.
          Use a normalized percentage where `0.5` is `50%`. Null default is `50%`.
        '';
      };
      horizontalZoomCenter = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.zoomScrollOffset.zoomCenter.horizontal));
        default = null;
        example = literalExpression "reaperAppearance.zoomScrollOffset.zoomCenter.horizontal.editCursor";
        description = ''
          Horizontal zoom center in Zoom/Scroll/Offset menu in Appearance preferences menu. Null default is `Edit cursor or play cursor (default)`.
        '';
      };
      limitHorizontalZoomScrollToProjectStart = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          Whether horizontal zoom and scroll are limited to the project start. Null default is checked.
        '';
      };
      disableMousewheelVerticalZoomForTracksThatArePinnedInArrangeView = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = ''
          Whether mousewheel vertical zoom is disabled for tracks pinned in arrange view.
        '';
      };
      verticalScrollStep = {
        unit = mkOption {
          type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.zoomScrollOffset.verticalScrollStep.units));
          default = null;
          example = literalExpression "reaperAppearance.zoomScrollOffset.verticalScrollStep.units.trackHeight";
          description = ''
            Unit used for vertical scroll step. Null default is `% of track height`.
          '';
        };
        trackHeight = mkOption {
          type = types.nullOr scrollStep;
          default = null;
          example = 0.5;
          description = ''
            Vertical scroll step as a percentage of track height, where `0.5` is `50%`.
          '';
        };
        arrangeViewHeight = mkOption {
          type = types.nullOr scrollStep;
          default = null;
          example = 0.1;
          description = ''
            Vertical scroll step as a percentage of arrange view height, where `0.1` is `10%`.
          '';
        };
      };
      overlappingMediaItems = {
        offset = mkOption {
          type = types.nullOr overlapOffset;
          default = null;
          example = 100;
          description = ''
            Vertical offset for overlapping media items, as a percent of item height.
          '';
        };
        drawAsOpaque = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether vertically offset overlapping media items are drawn as opaque.";
        };
        arrangeInCreationOrder = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = ''
            Whether overlapping media items are arranged in the order they were created.
          '';
        };
      };
    };
  };
  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.zoomScrollOffset.verticalZoomCenter != null) {vzoommode = cfg.zoomScrollOffset.verticalZoomCenter;}
    // optionalAttrs (cfg.zoomScrollOffset.maximumVerticalZoom != null) {maxvzoom = cfg.zoomScrollOffset.maximumVerticalZoom;}
    // optionalAttrs (cfg.zoomScrollOffset.envelopeLaneVerticalZoom != null) {envvzoomscale = cfg.zoomScrollOffset.envelopeLaneVerticalZoom;}
    // optionalAttrs (cfg.zoomScrollOffset.horizontalZoomCenter != null) {zoommode = cfg.zoomScrollOffset.horizontalZoomCenter;}
    // optionalAttrs (cfg.zoomScrollOffset.verticalScrollStep.trackHeight != null) {vscrollstep = cfg.zoomScrollOffset.verticalScrollStep.trackHeight;}
    // optionalAttrs (cfg.zoomScrollOffset.verticalScrollStep.arrangeViewHeight != null) {vscrollstep2 = cfg.zoomScrollOffset.verticalScrollStep.arrangeViewHeight;};

  config.programs.reaper.ini.bitfields.reaper =
    optionalBitfield (vscrollflagMask != 0) {
      vscrollflag = {
        mask = vscrollflagMask;
        value = vscrollflagValue;
      };
    }
    // optionalAttrs (overlapMask != 0) {
      itemoverlap_offspct = {
        mask = overlapMask;
        value = overlapValue;
      };
    };
}
