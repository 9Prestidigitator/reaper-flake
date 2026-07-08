{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield reaperTypes;
  cfg = config.programs.reaper.preferences.appearance.trackControlPanels;

  inherit (reaperTypes.trackControlPanel) sliderMaximum sliderMinimum sliderShape;

  mixer = config.programs.reaper.preferences.windows.mixer;

  groupSendsWithFxInserts =
    if mixer.groupSendsWithFxInserts != null
    then mixer.groupSendsWithFxInserts
    else cfg.groupSendsWithFxInserts;
  groupFxParametersWithInserts =
    if mixer.groupFxParametersWithInserts != null
    then mixer.groupFxParametersWithInserts
    else cfg.groupFxParametersWithInserts;

  reaperBitfields = reaperBitfield.entries {
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
        optionPath = "preferences.windows.mixer.groupSendsWithFxInserts";
        gui = "Group sends with FX inserts";
        option = groupSendsWithFxInserts;
        bit = 32;
      }
      {
        optionPath = "preferences.windows.mixer.groupFxParametersWithInserts";
        gui = "Group FX parameters with their inserts";
        option = groupFxParametersWithInserts;
        bit = 64;
      }
      {
        optionPath = "preferences.windows.mixer.allowEmptySlotsInFxLists";
        gui = "Allow empty slots in FX lists";
        option = mixer.allowEmptySlotsInFxLists;
        bit = 128;
        inverted = true;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights";
        gui = "Folder collapse button cycles track heights";
        option = cfg.folderCollapseButtonCyclesTrackHeights;
        mask = 768;
      }
      {
        optionPath = "preferences.appearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay";
        gui = "Fixed lane collapse button changes display";
        option = cfg.fixedLaneCollapseButtonChangesDisplay;
        mask = 1024;
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
    setTrackLabelBackgroundToCustomTrackColors = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Whether track label backgrounds are set to custom track colors.
      '';
    };

    tintTrackPanelBackgrounds = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = false;
      description = ''
        Whether track panel backgrounds are tinted.
      '';
    };

    alignTcpControlsWhenTrackIconsOrFixedItemLanesAreUsed = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Whether TCP controls are aligned when track icons or fixed item lanes are used.
      '';
    };

    showFxInserts = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Whether FX inserts are shown in the track control panel when size permits.
      '';
    };

    showSends = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Whether sends are shown in the track control panel when size permits.
      '';
    };

    groupSendsWithFxInserts = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = false;
      description = ''
        Whether sends are grouped with before/after FX inserts.
      '';
    };

    groupFxParametersWithInserts = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Whether FX parameters are grouped with their inserts.
      '';
    };

    folderCollapseButtonCyclesTrackHeights = mkOption {
      type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights));
      default = null;
      example = literalExpression "reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights.normalSmallCollapsed";
      description = ''
        Track height cycle used by the folder collapse button.
      '';
    };

    fixedLaneCollapseButtonChangesDisplay = mkOption {
      type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay));
      default = null;
      example = literalExpression "reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay.bigSmallLanes";
      description = ''
        Fixed lane display mode toggled by the fixed lane collapse button.
      '';
    };

    trackGroupingIndicators = mkOption {
      type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.trackControlPanels.trackGroupingIndicators));
      default = null;
      example = literalExpression "reaperAppearance.trackControlPanels.trackGroupingIndicators.ribbons";
      description = ''
        Track grouping indicator display mode in Track Control Panel preferences.
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
        TCP volume fader shape. Use `reaperAppearance.trackControlPanels.volumeFaderShape`
        for REAPER's named choices, or a custom shape between `0.25` and `4.0`.
      '';
    };

    panFaderUnitDisplay = mkOption {
      type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.trackControlPanels.panFaderUnitDisplay));
      default = null;
      example = literalExpression "reaperAppearance.trackControlPanels.panFaderUnitDisplay.percent100";
      description = ''
        TCP pan fader unit display mode.
      '';
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.trackGroupingIndicators != null) {groupdispmode = cfg.trackGroupingIndicators;}
    // optionalAttrs (cfg.volumeFaderRange.minimum != null) {sliderminv = cfg.volumeFaderRange.minimum;}
    // optionalAttrs (cfg.volumeFaderRange.maximum != null) {slidermaxv = cfg.volumeFaderRange.maximum;}
    // optionalAttrs (cfg.volumeFaderShape != null) {slidershex = cfg.volumeFaderShape;}
    // optionalAttrs (cfg.panFaderUnitDisplay != null) {pandispmode = cfg.panFaderUnitDisplay;};

  config.programs.reaper.ini.bitfields.reaper = reaperBitfields;
}
