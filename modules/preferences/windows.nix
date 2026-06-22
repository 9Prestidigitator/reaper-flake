{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib;
  cfg = config.programs.reaper.preferences.windows;
  transport_dock_position = cfg.transportDockPosition;
in {
  options.programs.reaper.preferences.windows = {
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
        type = types.nullor types.bool;
        default = true;
        example = false;
        description = ''
          If set to true mixer panel will be show, otherwise it is hidden.
        '';
      };
    };
  };

  config.programs.reaper.ini.sections.reaper = optionalAttrs (transport_dock_position != null) {
    transport_dock_pos = transport_dock_position;
    mixwin_vis = cfg.mixer.hidden;
  };
}
