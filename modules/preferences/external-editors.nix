{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  cfg = config.programs.reaper.preferences.externalEditors;
in {
}
