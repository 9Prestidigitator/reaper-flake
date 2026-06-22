{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib {inherit lib;};
  cfg = config.programs.reaper.preferences.windows;
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
}
