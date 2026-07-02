{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  cfg = config.programs.reaper.preferences.general;
in {
  options.programs.reaper.preferences.general = {
    startupSettings = {
      openProjectOnStartup = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperGeneral.openProjectOnStartup));
        default = null;
        example = literalExpression "reaperGeneral.openProjectOnStartup.newProjectIgnoreDefaultTemplate";
        description = ''
          The project(s) to open on startup. Default null value is reaperGeneral.lastProjectTabs.
        '';
      };
      showSplashScreenOnStartup = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          Displays the splash screeen and REAPER logo when the application starts.
        '';
      };
      skipAnimation = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          Skips the REAPER logo animation and potentially slightly reduces startup time.
        '';
      };
    };
  };
  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.startupSettings.openProjectOnStartup != null) {loadlastproj = cfg.startupSettings.openProjectOnStartup;}
    // optionalAttrs (cfg.startupSettings.showSplashScreenOnStartup != null) {splash = cfg.startupSettings.showSplashScreenOnStartup;}
    // optionalAttrs (cfg.startupSettings.skipAnimation != null) {splashanim = cfg.startupSettings.skipAnimation;};
}
