{
  config,
  lib,
  reaperLib,
  ...
}: let
  cfg = config.programs.reaper.preferences.general;

  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
in {
  options.programs.reaper.preferences.general.undo = {
    maximumUndoMemory = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 256;
      description = "Maxmimum undo memory (default: 256 MB). Enter 0 to disable the Undo function as well as the prompt to save modified projects on close.";
    };
  };
}
