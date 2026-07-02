{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield reaperTypes;
  cfg = config.programs.reaper.preferences.appearance;

  inherit (reaperTypes.percentage) envelopeVerticalZoom maxVerticalZoom scrollStep;
  overlapOffset = types.ints.between 0 255;

  scroll = cfg.zoomScrollOffset;
  verticalScrollStep = scroll.verticalScrollStep;
  overlap = scroll.overlappingMediaItems;

  reaperBitfields = reaperBitfield.entries {
    vscrollflag = [
      {
        optionPath = "preferences.appearance.zoomScrollOffset.verticalScrollStep.unit";
        gui = "Vertical scroll step unit";
        option = verticalScrollStep.unit;
        mask = 1;
        value =
          if verticalScrollStep.unit == reaperLib.reaperAppearance.zoomScrollOffset.verticalScrollStep.units.arrangeViewHeight
          then 1
          else 0;
      }
      {
        optionPath = "preferences.appearance.zoomScrollOffset.limitHorizontalZoomScrollToProjectStart";
        gui = "Limit horizontal zoom/scroll to project start";
        option = scroll.limitHorizontalZoomScrollToProjectStart;
        bit = 2;
      }
      {
        optionPath = "preferences.appearance.zoomScrollOffset.disableMousewheelVerticalZoomForTracksThatArePinnedInArrangeView";
        gui = "Disable mousewheel vertical zoom for pinned arrange-view tracks";
        option = scroll.disableMousewheelVerticalZoomForTracksThatArePinnedInArrangeView;
        bit = 4;
      }
    ];

    itemoverlap_offspct = [
      {
        optionPath = "preferences.appearance.zoomScrollOffset.overlappingMediaItems.offset";
        gui = "Overlapping media item display offset";
        option = overlap.offset;
        mask = 255;
      }
      {
        optionPath = "preferences.appearance.zoomScrollOffset.overlappingMediaItems.drawAsOpaque";
        gui = "Draw overlapping media items as opaque";
        option = overlap.drawAsOpaque;
        bit = 256;
      }
      {
        optionPath = "preferences.appearance.zoomScrollOffset.overlappingMediaItems.arrangeInCreationOrder";
        gui = "Arrange overlapping media items in creation order";
        option = overlap.arrangeInCreationOrder;
        bit = 512;
      }
    ];
  };
in {
  options.programs.reaper.preferences.appearance.zoomScrollOffset = {
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

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.zoomScrollOffset.verticalZoomCenter != null) {vzoommode = cfg.zoomScrollOffset.verticalZoomCenter;}
    // optionalAttrs (cfg.zoomScrollOffset.maximumVerticalZoom != null) {maxvzoom = cfg.zoomScrollOffset.maximumVerticalZoom;}
    // optionalAttrs (cfg.zoomScrollOffset.envelopeLaneVerticalZoom != null) {envvzoomscale = cfg.zoomScrollOffset.envelopeLaneVerticalZoom;}
    // optionalAttrs (cfg.zoomScrollOffset.horizontalZoomCenter != null) {zoommode = cfg.zoomScrollOffset.horizontalZoomCenter;}
    // optionalAttrs (cfg.zoomScrollOffset.verticalScrollStep.trackHeight != null) {vscrollstep = cfg.zoomScrollOffset.verticalScrollStep.trackHeight;}
    // optionalAttrs (cfg.zoomScrollOffset.verticalScrollStep.arrangeViewHeight != null) {vscrollstep2 = cfg.zoomScrollOffset.verticalScrollStep.arrangeViewHeight;};

  config.programs.reaper.ini.bitfields.reaper = reaperBitfields;
}
