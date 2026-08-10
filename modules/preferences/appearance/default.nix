{
  config,
  lib,
  pkgs,
  reaperLib,
  reaperAppearance,
  ...
}: let
  inherit (lib) mkOption types;
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
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 200;
        description = "The mouse hover delay before tooltips appear, in milliseconds.";
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
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 4;
      description = "Vertical pixel spacing below media items, above the following track.";
    };
    visualTrackSpacerSize = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 16;
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
        example = "respectToolbarSnapButton";
        description = "Draw a vertical line to indicate the mouse position in the arrange view.";
      };
    };
    playCursorWidth = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 2;
      description = "Width of play cursor in pixels.";
    };
    hideDockerTabsWhenSingleWindowAndSmallerThanPixels = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 300;
      description = "Set the minimum size in pixels where a single tab will be displayed in a docker. Below this size, a minimal handle will be displayed.";
    };
  };
  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.appearance.tooltips.delay";
        value = cfg.tooltips.delay;
        section = "reaper";
        key = "tooltipdelay";
        codec = "integer";
      }
      {
        path = "preferences.appearance.verticalSpaceAtBottomOfTrackNumber";
        value = cfg.verticalSpaceAtBottomOfTrackNumber;
        section = "reaper";
        key = "trackitemgap";
        codec = "integer";
      }
      {
        path = "preferences.appearance.visualTrackSpacerSize";
        value = cfg.visualTrackSpacerSize;
        section = "reaper";
        key = "trackgapmax";
        codec = "integer";
      }
      {
        path = "preferences.appearance.envelopePointSizeScaling";
        value = cfg.envelopePointSizeScaling;
        section = "reaper";
        key = "env_pt_scale";
        codec = "float";
      }
      {
        path = "preferences.appearance.scaleNonSelectedPoint";
        value = cfg.scaleNonSelectedPoint;
        section = "reaper";
        key = "env_pt_scale2";
        codec = "float";
      }
      {
        path = "preferences.appearance.playCursorWidth";
        value = cfg.playCursorWidth;
        section = "reaper";
        key = "playcursormode";
        codec = "integer";
      }
      {
        path = "preferences.appearance.hideDockerTabsWhenSingleWindowAndSmallerThanPixels";
        value = cfg.hideDockerTabsWhenSingleWindowAndSmallerThanPixels;
        section = "reaper";
        key = "dock_mini_tab_size";
        codec = "integer";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      tooltips = [
        {
          optionPath = "preferences.appearance.tooltips.uiElements";
          gui = "Tooltips: UI elements";
          option = cfg.tooltips.uiElements;
          bit = 1;
        }
        {
          optionPath = "preferences.appearance.tooltips.itemsEnvelopes";
          gui = "Tooltips: Items/envelopes";
          option = cfg.tooltips.itemsEnvelopes;
          bit = 2;
        }
        {
          optionPath = "preferences.appearance.tooltips.envsOnHover";
          gui = "Tooltips: Envs on hover";
          option = cfg.tooltips.envsOnHover;
          bit = 4;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.tooltips.peakAndLoudnessValueWhenMouseIsOverMediaItems";
          gui = "Peak and loudness value when mouse is over media item";
          option = cfg.tooltips.peakAndLoudnessValueWhenMouseIsOverMediaItems;
          bit = 8;
        }
      ];

      textflags = [
        {
          optionPath = "preferences.appearance.drawVerticalTextBottomUp";
          gui = "Draw vertical text bottom-up";
          option = cfg.drawVerticalTextBottomUp;
          bit = 1;
        }
      ];

      nativedrawtext_linux = [
        {
          optionPath = "preferences.appearance.fasterTextRendering";
          gui = "Faster text rendering";
          option = cfg.fasterTextRendering;
          configured = pkgs.stdenv.hostPlatform.isLinux && cfg.fasterTextRendering != null;
          bit = 1;
          inverted = true;
        }
      ];

      custommenu = [
        {
          optionPath = "preferences.appearance.framelessFloatingToolbarWindows";
          gui = "Frameless floating toolbar windows";
          option = cfg.framelessFloatingToolbarWindows;
          bit = 256;
        }
        {
          optionPath = "preferences.appearance.dontScaleToolbarButtonsBelow1to1";
          gui = "Don't scale toolbar buttons below 1:1";
          option = cfg.dontScaleToolbarButtonsBelow1to1;
          bit = 4;
        }
        {
          optionPath = "preferences.appearance.dontScaleToolbarButtonsAbove1to1";
          gui = "Don't scale toolbar buttons above 1:1";
          option = cfg.dontScaleToolbarButtonsAbove1to1;
          bit = 16;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.dontAnimateArmedActionToolbarButtons";
          gui = "Don't animate armed-action toolbar buttons";
          option = cfg.dontAnimateArmedActionToolbarButtons;
          bit = 512;
        }
        {
          optionPath = "preferences.appearance.dontAnimateAnyToolbarButtons";
          gui = "Don't animate any toolbar buttons";
          option = cfg.dontAnimateAnyToolbarButtons;
          bit = 1024;
        }
      ];

      tcpalign = [
        {
          optionPath = "preferences.appearance.limitTcpSpacerHeightToLaneSize";
          gui = "Limit TCP spacer height to lane size";
          option = cfg.limitTcpSpacerHeightToLaneSize;
          bit = 8192;
          inverted = true;
        }
      ];

      envlanes = [
        {
          optionPath = "preferences.appearance.antialiasedFadesAndEnvelopes";
          gui = "Antialiased fades and envelopes";
          option = cfg.antialiasedFadesAndEnvelopes;
          bit = 8;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.horizontalGridLinesInAutomationLanes";
          gui = "Horizontal grid lines in automation lanes";
          option = cfg.horizontalGridLinesInAutomationLanes;
          bit = 64;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.filledAutomationEnvelopes";
          gui = "Filled automation envelopes";
          option = cfg.filledAutomationEnvelopes;
          bit = 16;
        }
        {
          optionPath = "preferences.appearance.filledEnvelopesWhenDrawnOverMedia";
          gui = "Filled envelopes when drawn over media";
          option = cfg.filledEnvelopesWhenDrawnOverMedia;
          bit = 32;
        }
      ];

      guidelines2 = [
        {
          optionPath = "preferences.appearance.hightlightEditCursorOverLastSelectedTrack";
          gui = "Highlight edit cursor over last selected track";
          option = cfg.hightlightEditCursorOverLastSelectedTrack;
          bit = 8;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.showGuideLinesWhenEditing";
          gui = "Show guide lines when editing";
          option = cfg.showGuideLinesWhenEditing;
          bit = 4;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.displayVerticalLineAtMousePosition.enable";
          gui = "Display vertical line at mouse position";
          option = cfg.displayVerticalLineAtMousePosition.enable;
          bit = 16;
        }
        {
          optionPath = "preferences.appearance.displayVerticalLineAtMousePosition.snap";
          gui = "Display vertical line at mouse position snap mode";
          option = cfg.displayVerticalLineAtMousePosition.snap;
          mask = 224;
          valueFor = mode: arrangeSnap.${mode};
          importValues = arrangeSnap;
        }
      ];

      timeseledge = [
        {
          optionPath = "preferences.appearance.solidEdgeOnTimeSelectionHighlight";
          gui = "Solid edge on time selection highlight";
          option = cfg.solidEdgeOnTimeSelectionHighlight;
          bit = 1;
        }
        {
          optionPath = "preferences.appearance.solidEdgeOnLoopSelection";
          gui = "Solid edge on loop selection";
          option = cfg.solidEdgeOnLoopSelection;
          bit = 2;
        }
      ];
    });
}
