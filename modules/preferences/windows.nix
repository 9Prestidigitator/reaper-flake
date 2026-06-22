{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib;
  cfg = config.programs.reaper.preferences.windows;
  transportDockPositions = builtins.attrValues reaperLib.reaperWindows.transport;
  transportDockPosition =
    if cfg.transport_dock_position != null
    then cfg.transport_dock_position
    else cfg.transport_dock_pos;
in {
  options.programs.reaper.preferences.windows = {
    transport_dock_position = mkOption {
      type = types.nullOr (types.enum transportDockPositions);
      default = null;
      example = literalExpression "reaperWindows.transport.topOfMainWindow";
      description = ''
        Position of the transport in REAPER's main window. Named values are
        available from `reaperWindows.transport`.
      '';
    };

    transport_dock_pos = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Raw REAPER `[reaper].transport_dock_pos` value. Prefer
        `transport_dock_position` with `reaperWindows.transport` values.
      '';
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (transportDockPosition != null) {
      transport_dock_pos = transportDockPosition;
    };
}
