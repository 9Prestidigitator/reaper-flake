{
  config,
  lib,
  reaperLib,
  reaperPlugins,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperPreference;
  cfg = config.programs.reaper.preferences.plugIns;
in {
  imports = [
    ./Compatibility.nix
    ./vst.nix
    ./lv2Clap.nix
    ./ara.nix
    ./ReaScript.nix
  ];

  options.programs.reaper.preferences.plugIns = {
    automaticallyResizeFxWindow.up = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Automatically resize FX window up.";
    };
    automaticallyResizeFxWindow.down = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Automatically resize FX window down.";
    };
    autoFloatUiForFxCreatedViaFxBrowser = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Auto-float UI for FX created via FX browser.";
    };
    autoFloatUiForFxCreatedViaRightClickMenu = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Auto-float UI for FX created via right-click menu.";
    };
    autoOpenUiAfterDragDropEntireFxChain = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Auto-open UI after drag/drop entire FX chain.";
    };
    autoOpenFxBrowserWhenOpeningEmptyFxChain = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Auto-open FX browser when opening empty FX chain.";
      };
      hideChainUntilAdded = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Hide chain until added.";
      };
    };

    fxChainPositioning = mkOption {
      type = types.nullOr (types.enum ["cascade" "automatic" "modalDefault"]);
      default = null;
      example = "cascade";
      description = "Positioning mode for FX chain windows.";
    };
    floatingFxPositioning = mkOption {
      type = types.nullOr (types.enum ["cascade" "automatic" "modalDefault"]);
      default = null;
      example = "cascade";
      description = "Positioning mode for floating FX windows.";
    };

    autoDockNewFxChainWindows = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Auto-dock new FX chain windows.";
    };

    onlyAllowOneFxChainWindowAtATime = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Only allow one FX chain window at a time.";
      };
      openTrackFxWindowOnTrackSelectionChange = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Open track FX window on track selection change.";
      };
      onlyIfAnyFxWindowIsOpen = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Only if any FX window is open.";
      };
    };

    onlyAllowOneFxFloatingAtATime = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Only allow one FX floating at a time.";
      };
      excludeMonitoringFx = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Exclude monitoring FX.";
      };
      excludeMasterTrackFx = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Exclude master track FX.";
      };
      onePerTrack = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "One per track.";
      };
    };

    automaticallyForegroundFloatingWindowIfOpenWhenSelectingFx = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Automatically foreground floating window, if open, when selecting FX in the FX chain.";
    };
    showFxListOnRightSideOfFxChainWindow = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show FX list on right side of FX chain window.";
    };
    showFxChainButtonsAboveFxList = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show FX chain buttons above FX list.";
    };
    showCommentFieldAboveFxUi = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show comment field above FX UI.";
    };
    showFxStateAsAccessibleTextInName = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show FX state as accessible text in name.";
    };

    showCurrentTrackFxInFxButtonRightClickMenu = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Show current track FX in FX button right-click menu.";
    };
    doNotCreateUndoPointsWhenClosingFxWindows = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Do not create undo points when closing FX windows.";
    };
    promptToCreateRoutingWhenInsertingNewMultichannelInstruments = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Prompt to create routing when inserting new multichannel instruments.";
    };
    preservePinMappingsWhenLoadingPresets = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Preserve pin mappings when loading presets.";
    };

    onlyShowFxMatchingFilterString = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "NOT VST2";
      description = "Filter expression limiting the FX shown in the browser. An empty string clears the filter.";
    };
    recentlyUsedListMax = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 30;
      description = "Maximum number of FX in the recently used list.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.plugIns.onlyShowFxMatchingFilterString";
        gui = "Only show FX matching filter string";
        value = cfg.onlyShowFxMatchingFilterString;
        section = "reaper";
        key = "def_fx_filtgen";
        codec = "identity";
      }
      {
        path = "preferences.plugIns.recentlyUsedListMax";
        gui = "Recently Used list max";
        value = cfg.recentlyUsedListMax;
        section = "reaper";
        key = "maxrecentfx";
        codec = "integer";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      fxresize = [
        {
          optionPath = "preferences.plugIns.automaticallyResizeFxWindow.up";
          gui = "Automatically resize FX window up";
          option = cfg.automaticallyResizeFxWindow.up;
          bit = 1;
        }
        {
          optionPath = "preferences.plugIns.automaticallyResizeFxWindow.down";
          gui = "Automatically resize FX window down";
          option = cfg.automaticallyResizeFxWindow.down;
          bit = 2;
        }
      ];
      fxfloat_focus = [
        {
          optionPath = "preferences.plugIns.autoFloatUiForFxCreatedViaFxBrowser";
          gui = "Auto-float UI for FX created via FX browser";
          option = cfg.autoFloatUiForFxCreatedViaFxBrowser;
          bit = 4;
        }
        {
          optionPath = "preferences.plugIns.autoFloatUiForFxCreatedViaRightClickMenu";
          gui = "Auto-float UI for FX created via right-click menu";
          option = cfg.autoFloatUiForFxCreatedViaRightClickMenu;
          bit = 128;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.autoOpenUiAfterDragDropEntireFxChain";
          gui = "Auto-open UI after drag/drop entire FX chain";
          option = cfg.autoOpenUiAfterDragDropEntireFxChain;
          bit = 8388608;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.autoOpenFxBrowserWhenOpeningEmptyFxChain.enable";
          gui = "Auto-open FX browser when opening empty FX chain";
          option = cfg.autoOpenFxBrowserWhenOpeningEmptyFxChain.enable;
          bit = 8;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.autoOpenFxBrowserWhenOpeningEmptyFxChain.hideChainUntilAdded";
          gui = "Hide chain until added";
          option = cfg.autoOpenFxBrowserWhenOpeningEmptyFxChain.hideChainUntilAdded;
          bit = 524288;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.autoDockNewFxChainWindows";
          gui = "Auto-dock new FX chain windows";
          option = cfg.autoDockNewFxChainWindows;
          bit = 16;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxChainWindowAtATime.enable";
          gui = "Only allow one FX chain window at a time";
          option = cfg.onlyAllowOneFxChainWindowAtATime.enable;
          bit = 2;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxChainWindowAtATime.openTrackFxWindowOnTrackSelectionChange";
          gui = "Open track FX window on track selection change";
          option = cfg.onlyAllowOneFxChainWindowAtATime.openTrackFxWindowOnTrackSelectionChange;
          bit = 32;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxChainWindowAtATime.onlyIfAnyFxWindowIsOpen";
          gui = "Only if any FX window is open";
          option = cfg.onlyAllowOneFxChainWindowAtATime.onlyIfAnyFxWindowIsOpen;
          bit = 64;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxFloatingAtATime.enable";
          gui = "Only allow one FX floating at a time";
          option = cfg.onlyAllowOneFxFloatingAtATime.enable;
          bit = 16777216;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxFloatingAtATime.excludeMonitoringFx";
          gui = "Exclude monitoring FX";
          option = cfg.onlyAllowOneFxFloatingAtATime.excludeMonitoringFx;
          bit = 33554432;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxFloatingAtATime.excludeMasterTrackFx";
          gui = "Exclude master track FX";
          option = cfg.onlyAllowOneFxFloatingAtATime.excludeMasterTrackFx;
          bit = 67108864;
        }
        {
          optionPath = "preferences.plugIns.onlyAllowOneFxFloatingAtATime.onePerTrack";
          gui = "One per track";
          option = cfg.onlyAllowOneFxFloatingAtATime.onePerTrack;
          bit = 134217728;
        }
        {
          optionPath = "preferences.plugIns.automaticallyForegroundFloatingWindowIfOpenWhenSelectingFx";
          gui = "Automatically foreground floating window, if open, when selecting FX in the FX chain";
          option = cfg.automaticallyForegroundFloatingWindowIfOpenWhenSelectingFx;
          bit = 1;
        }
        {
          optionPath = "preferences.plugIns.showFxListOnRightSideOfFxChainWindow";
          gui = "Show FX list on right side of FX chain window";
          option = cfg.showFxListOnRightSideOfFxChainWindow;
          bit = 8192;
        }
        {
          optionPath = "preferences.plugIns.showFxChainButtonsAboveFxList";
          gui = "Show FX chain buttons above FX list";
          option = cfg.showFxChainButtonsAboveFxList;
          bit = 16384;
        }
        {
          optionPath = "preferences.plugIns.showCommentFieldAboveFxUi";
          gui = "Show comment field above FX UI";
          option = cfg.showCommentFieldAboveFxUi;
          bit = 32768;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.showFxStateAsAccessibleTextInName";
          gui = "Show FX state as accessible text in name";
          option = cfg.showFxStateAsAccessibleTextInName;
          bit = 1048576;
        }
        {
          optionPath = "preferences.plugIns.showCurrentTrackFxInFxButtonRightClickMenu";
          gui = "Show current track FX in FX button right-click menu";
          option = cfg.showCurrentTrackFxInFxButtonRightClickMenu;
          bit = 256;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.doNotCreateUndoPointsWhenClosingFxWindows";
          gui = "Do not create undo points when closing FX windows";
          option = cfg.doNotCreateUndoPointsWhenClosingFxWindows;
          bit = 65536;
        }
        {
          optionPath = "preferences.plugIns.promptToCreateRoutingWhenInsertingNewMultichannelInstruments";
          gui = "Prompt to create routing when inserting new multichannel instruments";
          option = cfg.promptToCreateRoutingWhenInsertingNewMultichannelInstruments;
          bit = 4194304;
          inverted = true;
        }
        {
          optionPath = "preferences.plugIns.fxChainPositioning";
          option = cfg.fxChainPositioning;
          mask = 132096;
          valueFor = value: reaperPlugins.chainPositioning.${value};
          importValues = reaperPlugins.chainPositioning;
        }
        {
          optionPath = "preferences.plugIns.floatingFxPositioning";
          option = cfg.floatingFxPositioning;
          mask = 264192;
          valueFor = value: reaperPlugins.floatingPositioning.${value};
          importValues = reaperPlugins.floatingPositioning;
        }
      ];
      vstfullstate = [
        {
          optionPath = "preferences.plugIns.preservePinMappingsWhenLoadingPresets";
          gui = "Preserve pin mappings when loading presets";
          option = cfg.preservePinMappingsWhenLoadingPresets;
          bit = 8388608;
        }
      ];
    });
}
