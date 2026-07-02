{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
  cfg = config.programs.reaper.preferences.appearance.rulerGrid;
  shadeInterval = types.either types.int types.float;
in {
  options.programs.reaper.preferences.appearance.rulerGrid = {
    rulerLabelSpacing = mkOption {
      default = null;
    };
    gridLines = mkOption {
      default = null;
    };
    markerLines = mkOption {
      default = null;
    };
    showInArrangeView = mkOption {
      default = null;
    };
    divideArrangeViewVerticallyWhenRulerDisplaysTimeFramesOrSamples = {
      enable = lib.mkEnableOption "Use color theme odd/even track colors to divide the arrange view vertically.";
      shadeEvery = mkOption {
        type = types.nullOr shadeInterval;
        default = null;
        description = "In seconds, 0 (null) = zoom dependent.";
      };
    };
    divideArrangeViewVerticallyWhenRulerDisplaysBeats = {
      enable = lib.mkEnableOption "Use color theme odd/even track colors to divide the arrange view vertically.";
      shadeEvery = mkOption {
        type = types.nullOr shadeInterval;
        default = null;
        description = "In seconds, 0 (null) = zoom dependent.";
      };
    };
  };
}
