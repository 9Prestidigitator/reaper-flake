{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib {inherit lib;};
  cfg = config.programs.reaper.preferences.general;
in {
}
