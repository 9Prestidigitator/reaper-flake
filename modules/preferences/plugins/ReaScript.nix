{
  config,
  lib,
  pkgs,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkEnableOption mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;

  cfg = config.programs.reaper.preferences.plugIns.reascript;
in {
  options.programs.reaper.preferences.plugIns.reascript = {
    python = {
      enable = mkEnableOption "Python support in REAPER";

      package = mkOption {
        type = types.package;
        default = pkgs.python3;
        defaultText = literalExpression "pkgs.python3";
        description = ''
          Python package made available to REAPER for Python ReaScripts when
          using the module's default `programs.reaper.package` (BROKEN).
        '';
      };
    };
  };

  config.programs.reaper.ini = {
    sections.reaper = optionalAttrs cfg.python.enable {
      pythonlibpath64 = "${cfg.python.package}/lib";
      pythonlibdll64 = "libpython${cfg.python.package.pythonVersion}.so";
    };

    bitfields.reaper = reaperBitfield.entries {
      reascript = [
        {
          optionPath = "preferences.plugIns.reascript.python.enable";
          gui = "Enable ReaScript";
          configured = cfg.python.enable;
          option = cfg.python.enable;
          bit = 1;
        }
      ];
    };
  };
}
