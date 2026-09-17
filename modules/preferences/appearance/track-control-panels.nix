{
  config,
  lib,
  reaBool,
  reaEnum,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption types;
  inherit (reaperLib) reaperBitfield reaperPreference reaperTypes;

  inherit (reaperTypes.trackControlPanel) sliderMaximum sliderMinimum sliderShape;

  cfg = config.programs.reaper.preferences.appearance.trackControlPanels;
  mixer = config.programs.reaper.windows.mixer;

  groupSendsWithFxInserts =
    if mixer.groupSendsWithFxInserts != null
    then mixer.groupSendsWithFxInserts
    else cfg.groupSendsWithFxInserts;
  groupFxParametersWithInserts =
    if mixer.groupFxParametersWithInserts != null
    then mixer.groupFxParametersWithInserts
    else cfg.groupFxParametersWithInserts;

  reaperBitfieldContributions = reaperBitfield.contributions {
    tcpalign = [
      {
        optionPath = "preferences.appearance.trackControlPanels.alignTcpControlsWhenTrackIconsOrFixedItemLanesAreUsed";
        gui = "Align TCP controls when track icons or fixed item lanes are used";
        option = cfg.alignTcpControlsWhenTrackIconsOrFixedItemLanesAreUsed;
        bit = 1;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.showFxInserts";
        gui = "Show FX inserts in TCP";
        option = cfg.showFxInserts;
        mask = 14;
        trueValue = 6;
        falseValue = 8;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.showSends";
        gui = "Show sends in TCP";
        option = cfg.showSends;
        bit = 16;
      }
      {
        optionPath = "windows.mixer.groupSendsWithFxInserts";
        gui = "Group sends with FX inserts";
        option = groupSendsWithFxInserts;
        bit = 32;
        importAssignments = {
          "0" = {
            "preferences.appearance.trackControlPanels.groupSendsWithFxInserts" = false;
            "windows.mixer.groupSendsWithFxInserts" = false;
          };
          "32" = {
            "preferences.appearance.trackControlPanels.groupSendsWithFxInserts" = true;
            "windows.mixer.groupSendsWithFxInserts" = true;
          };
        };
      }
      {
        optionPath = "windows.mixer.groupFxParametersWithInserts";
        gui = "Group FX parameters with their inserts";
        option = groupFxParametersWithInserts;
        bit = 64;
        importAssignments = {
          "0" = {
            "preferences.appearance.trackControlPanels.groupFxParametersWithInserts" = false;
            "windows.mixer.groupFxParametersWithInserts" = false;
          };
          "64" = {
            "preferences.appearance.trackControlPanels.groupFxParametersWithInserts" = true;
            "windows.mixer.groupFxParametersWithInserts" = true;
          };
        };
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.allowReorderingEmptySlotsInTcpMcpFxLists";
        gui = "Allow reordering/empty slots in TCP/MCP FX lists";
        option = cfg.allowReorderingEmptySlotsInTcpMcpFxLists;
        bit = 128;
        inverted = true;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights";
        gui = "Folder collapse button cycles track heights";
        option = cfg.folderCollapseButtonCyclesTrackHeights;
        mask = 768;
        importValues = reaperLib.reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay";
        gui = "Fixed lane collapse button changes display";
        option = cfg.fixedLaneCollapseButtonChangesDisplay;
        mask = 1024;
        importValues = reaperLib.reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay;
      }
    ];

    tinttcp = [
      {
        optionPath = "preferences.appearance.trackControlPanels.setTrackLabelBackgroundToCustomTrackColors";
        gui = "Set track label background to custom track colors";
        option = cfg.setTrackLabelBackgroundToCustomTrackColors;
        bit = 1;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.tintTrackPanelBackgrounds";
        gui = "Tint track panel backgrounds";
        option = cfg.tintTrackPanelBackgrounds;
        bit = 2;
      }
    ];
  };
in {
  options.programs.reaper.preferences.appearance.trackControlPanels = {
    allowReorderingEmptySlotsInTcpMcpFxLists = reaBool ''
      Whether reordering and empty slots are allowed in TCP/MCP FX lists.
    '';

    setTrackLabelBackgroundToCustomTrackColors = reaBool ''
      Whether track label backgrounds are set to custom track colors.
    '';

    tintTrackPanelBackgrounds = reaBool {
      example = false;
      description = ''
        Whether track panel backgrounds are tinted.
      '';
    };

    alignTcpControlsWhenTrackIconsOrFixedItemLanesAreUsed = reaBool ''
      Whether TCP controls are aligned when track icons or fixed item lanes are
      used.
    '';

    showFxInserts = reaBool ''
      Whether FX inserts are shown in the track control panel when size permits.
    '';

    showSends = reaBool ''
      Whether sends are shown in the track control panel when size permits.
    '';

    groupSendsWithFxInserts = reaBool {
      example = false;
      description = ''
        Whether sends are grouped with before/after FX inserts.
      '';
    };

    groupFxParametersWithInserts = reaBool ''
      Whether FX parameters are grouped with their inserts.
    '';

    folderCollapseButtonCyclesTrackHeights = reaEnum {
      enum = reaperLib.reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights;
      coerce = "values";
      example = literalExpression "reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights.normalSmallCollapsed";
      description = ''
        Track height cycle used by the folder collapse button.
      '';
    };

    fixedLaneCollapseButtonChangesDisplay = reaEnum {
      enum = reaperLib.reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay;
      coerce = "values";
      example = literalExpression "reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay.bigSmallLanes";
      description = ''
        Fixed lane display mode toggled by the fixed lane collapse button.
      '';
    };

    trackGroupingIndicators = reaEnum {
      enum = reaperLib.reaperAppearance.trackControlPanels.trackGroupingIndicators;
      example = literalExpression "reaperAppearance.trackControlPanels.trackGroupingIndicators.ribbons";
      description = ''
        Track grouping indicator display mode in Track Control Panel
        preferences.
      '';
    };

    volumeFaderRange = {
      minimum = mkOption {
        type = types.nullOr sliderMinimum;
        default = null;
        example = -72;
        description = ''
          Minimum TCP volume fader range in dB.
        '';
      };

      maximum = mkOption {
        type = types.nullOr sliderMaximum;
        default = null;
        example = 12;
        description = ''
          Maximum TCP volume fader range in dB.
        '';
      };
    };

    volumeFaderShape = mkOption {
      type = types.nullOr sliderShape;
      default = null;
      example = literalExpression "reaperAppearance.trackControlPanels.volumeFaderShape.default";
      description = ''
        TCP volume fader shape. Use
        `reaperAppearance.trackControlPanels.volumeFaderShape`
        for REAPER's named choices, or a custom shape between `0.25` and `4.0`.
      '';
    };

    panFaderUnitDisplay = reaEnum {
      enum = reaperLib.reaperAppearance.trackControlPanels.panFaderUnitDisplay;
      example = literalExpression "reaperAppearance.trackControlPanels.panFaderUnitDisplay.percent100";
      description = ''
        TCP pan fader unit display mode.
      '';
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.appearance.trackControlPanels.trackGroupingIndicators";
        value = cfg.trackGroupingIndicators;
        section = "reaper";
        key = "groupdispmode";
        codec = "integer";
      }
      {
        path = "preferences.appearance.trackControlPanels.volumeFaderRange.minimum";
        value = cfg.volumeFaderRange.minimum;
        section = "reaper";
        key = "sliderminv";
        codec = "float";
      }
      {
        path = "preferences.appearance.trackControlPanels.volumeFaderRange.maximum";
        value = cfg.volumeFaderRange.maximum;
        section = "reaper";
        key = "slidermaxv";
        codec = "float";
      }
      {
        path = "preferences.appearance.trackControlPanels.volumeFaderShape";
        value = cfg.volumeFaderShape;
        section = "reaper";
        key = "slidershex";
        codec = "float";
      }
      {
        path = "preferences.appearance.trackControlPanels.panFaderUnitDisplay";
        value = cfg.panFaderUnitDisplay;
        section = "reaper";
        key = "pandispmode";
        codec = "integer";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) reaperBitfieldContributions;
}
