{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types mkEnableOption literalExpression mkIf;
  cfg = config.programs.reaper.pythonSupport;
in {
  options.programs.reaper = {
    pythonSupport = {
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

  config.programs.reaper.ini.sections.reaper = mkIf cfg.enable {
    pythonlibpath64 = "${cfg.package}/lib";
    pythonlibdll64 = "libpython${cfg.package.pythonVersion}.so";
  };
}
