{
  config,
  lib,
  reaperLib,
  reaperAppearance,
  ...
}: let
  inherit (lib) mkOption types literalExpression;
  inherit (reaperLib) reaperBitfield reaperTypes reaperPreference;
  inherit (reaperAppearance) arrangeSnap;

  cfg = config.programs.reaper.preferences.appearance;
in {
  imports = [
    ./ruler-grid.nix
    ./track-control-panels.nix
    ./zoom-scroll-offset.nix
  ];
  options.programs.reaper.preferences.appearance = {
    tooltips = {
      uiElements = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable tooltips on the UI elements.";
      };
      itemsEnvelopes = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable tooltips when editing items or envelopes.";
      };
      envsOnHover = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "If tooltips are enabled for envelopes, show the tooltip when hovering the mouse over an envelope.";
      };
      peakAndLoudnessValueWhenMouseIsOverMediaItems = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Enable peak value and loudness (if peaks settings are configured to calculate loudness) tooltip when hovering the mouse over a media item.";
      };
      delay = mkOption {
        type = types.nullOr reaperTypes.number;
        default = null;
        example = true;
        description = "The length of the mouse hover delay before tooltips appear.";
      };
    };

    fasterTextRendering = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Cache rendered font glyphs, which can improve drawing performance significantly vs FreeType.";
    };
    drawVerticalTextBottomUp = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When drawing vertical text in the theme (for example, track names or meter scale numbers), draw from bottom to top rather than top to bottom.";
    };
    framelessFloatingToolbarWindows = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Floating toolbars, and the Toolbar Docker, can be displayed without a window frame, for a smaller appearance.";
    };

    dontScaleToolbarButtonsBelow1to1 = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When changing the size of the toolbar or floating toolbar, don't allow buttons to be drawn smaller than the size of their underlying theme images.";
    };
    dontScaleToolbarButtonsAbove1to1 = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When changing the size of the toolbar or floating toolbar, don't allow buttons to be drawn larger than the size of their underlying theme images.";
    };
    dontAnimateArmedActionToolbarButtons = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Disable animations for armed toolbar buttons. Animations can be configured per-button in the toolbar context menu, under 'Customize toolbar'.";
    };
    dontAnimateAnyToolbarButtons = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Disable all toolbar animations. Animations can be configured per-button in the toolbar context menu, under 'Customize toolbar'.";
    };

    verticalSpaceAtBottomOfTrackNumber = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = true;
      description = "Vertical pixel spacing below media items, above the following track.";
    };
    visualTrackSpacerSize = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = true;
      description = "Pixel size of track spacer, applied to track control panels, mixer, and arrange view.";
    };
    limitTcpSpacerHeightToLaneSize = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Spacers in the TCP will shrink so that they are not larger thant he following panel's lane size.";
    };

    antialiasedFadesAndEnvelopes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Draw smooth item fadein/fadeout curves and automation envelopes. No meaningful performance penalty.";
    };
    horizontalGridLinesInAutomationLanes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show horizontal grid lines in envelope lanes, height permitting.";
    };
    filledAutomationEnvelopes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Fill automation envelopes with color, for easier reading but a slight performance penalty. (Media item fade area curve fills use a theme setting.)";
    };
    filledEnvelopesWhenDrawnOverMedia = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Fill automation envelopes with color when drawing envelopes over media, for easier reading but a slight performance penalty.";
    };

    envelopePointSizeScaling = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 1.5;
      description = "Adjust size of all envelope points - 1.0 is the default, 1.5 might be easier to see.";
    };
    scaleNonSelectedPoint = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 1.5;
      description = "Adjust size of unselected envelope points (relative to selected points)";
    };

    hightlightEditCursorOverLastSelectedTrack = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "By default, the edit cursor will display a highlight over the last selected track, to indicate where pasted content will go.";
    };
    showGuideLinesWhenEditing = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "By default, the edit cursor will display a highlight over the last selected track, to indicate where pasted content will go.";
    };
    solidEdgeOnTimeSelectionHighlight = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Draw solid lines at the edges of the time selection. In the theme, set the time selection fill mode alpha to zero for a minor performance improvement.";
    };
    solidEdgeOnLoopSelection = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Draw solid lines through the arrange view at the edges of the loop selection, for a slight performance penalty.";
    };

    displayVerticalLineAtMousePosition = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Draw a vertical line to indicate the mouse position in the arrange view.";
      };
      snap = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames arrangeSnap));
        default = null;
        example = literalExpression "reaperGeneral.modalWindowPositioning.centerOnCurrentScreen";
        description = "Draw a vertical line to indicate the mouse position in the arrange view.";
      };
    };
    playCursorWidth = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 2;
      description = "Width of play cursor in pixels.";
    };
    hideDockerTabsWhenSingleWindowAndSmallerThanPixels = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 300;
      description = "Set the minimum size in pixels where a single tab will be displayed in a docker. Below this size, a minimal handle will be displayed.";
    };
  };
  config = {
    programs.reaper.ini.contributions =
      reaperPreference.contributions [
      ];
  };
}
