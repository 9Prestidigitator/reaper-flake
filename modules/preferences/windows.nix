{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib {inherit lib;};
  cfg = config.programs.reaper.preferences.windows;
  tcpHelpBar = cfg.tcpHelpBar;
  performanceMeter = cfg.performanceMeter;
  helpMask =
    (
      if tcpHelpBar.informationDisplay != null
      then 7
      else 0
    )
    + (
      if tcpHelpBar.showMouseEditingHelp != null
      then 65536
      else 0
    )
    + (
      if performanceMeter.cpuUtilizationDisplay != null
      then 393216
      else 0
    );
  helpValue =
    (
      if tcpHelpBar.informationDisplay != null
      then tcpHelpBar.informationDisplay
      else 0
    )
    + (
      if tcpHelpBar.showMouseEditingHelp == false
      then 65536
      else 0
    )
    + (
      if performanceMeter.cpuUtilizationDisplay != null
      then performanceMeter.cpuUtilizationDisplay
      else 0
    );
in {
  options.programs.reaper.preferences.windows = {
    tcpHelpBar = {
      informationDisplay = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperWindows.tcpHelpBar.informationDisplay));
        default = null;
        example = literalExpression "reaperWindows.tcpHelpBar.informationDisplay.cpuRamUseTimeSinceLastSave";
        description = ''
          Information shown in the help bar below the track control panels.
          Named values are available from
          `reaperWindows.tcpHelpBar.informationDisplay`.
        '';
      };

      showMouseEditingHelp = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = ''
          Whether mouse editing help is shown in the help bar below the track control panels.
        '';
      };
    };

    performanceMeter = {
      cpuUtilizationDisplay = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperWindows.performanceMeter.cpuUtilizationDisplay));
        default = null;
        example = literalExpression "reaperWindows.performanceMeter.cpuUtilizationDisplay.allCoresFullyUtilized";
        description = ''
          CPU utilization display mode in the performance meter context menu.
          Named values are available from
          `reaperWindows.performanceMeter.cpuUtilizationDisplay`.
        '';
      };
    };

    transportDockPosition = mkOption {
      type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperWindows.transport));
      default = null;
      example = literalExpression "reaperWindows.transport.topOfMainWindow";
      description = ''
        Position of the transport in REAPER's main window. Named values are
        available from `reaperWindows.transport`.
      '';
    };
    mixer = {
      show = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          If set to true the mixer panel will be shown, otherwise it is hidden.
        '';
      };
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.transportDockPosition != null) {transport_dock_pos = cfg.transportDockPosition;}
    // optionalAttrs (cfg.mixer.show != null) {mixwin_vis = cfg.mixer.show;};

  config.programs.reaper.ini.bitfields.reaper = optionalAttrs (helpMask != 0) {
    help = {
      mask = helpMask;
      value = helpValue;
    };
  };
}
