{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  reaperLib = import ../lib {inherit lib;};
  cfg = config.programs.reaper.preferences.appearance;
  normalizedPercentage =
    (types.addCheck (types.either types.int types.float) (value: value >= 0 && value <= 1))
    // {
      description = "normalized percentage between 0 and 1";
    };
in {
  options.programs.reaper.preferences.appearance = {
    zoomScrollOffset = {
      verticalZoomCenter = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.zoomScrollOffset.zoomCenter.vertical));
        default = null;
        example = literalExpression "reaperAppearance.zoomScrollOffset.zoomCenter.vertical.lastSelectedTrack";
        description = ''
          Vertical zoom center in Zoom/Scroll/Offset menu in Appearance preferences menu. Null default is `Track at view center`.
        '';
      };
      maximumVerticalZoom = mkOption {
        type = types.nullOr normalizedPercentage;
        default = null;
        example = 0.80;
        description = ''
          Maximum vertical zoom in Zoom/Scroll/Offset menu in Appearance preferences menu.
          Use a normalized percentage where `1.0` is `100%`. Null default is `100%`.
        '';
      };
      envelopeLaneVerticalZoom = mkOption {
        type = types.nullOr normalizedPercentage;
        default = null;
        example = 0.32;
        description = ''
          Envelope lane vertical zoom in Zoom/Scroll/Offset menu in Appearance preferences menu.
          Use a normalized percentage where `0.5` is `50%`. Null default is `50%`.
        '';
      };
      horizontalZoomCenter = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperAppearance.zoomScrollOffset.zoomCenter.horizontal));
        default = null;
        example = literalExpression "reaperAppearance.zoomScrollOffset.zoomCenter.horizontal.editCursor";
        description = ''
          Horizontal zoom center in Zoom/Scroll/Offset menu in Appearance preferences menu. Null default is `Edit cursor or play cursor (default)`.
        '';
      };
    };
  };
  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.zoomScrollOffset.verticalZoomCenter != null) {vzoommode = cfg.zoomScrollOffset.verticalZoomCenter;}
    // optionalAttrs (cfg.zoomScrollOffset.maximumVerticalZoom != null) {maxvzoom = cfg.zoomScrollOffset.maximumVerticalZoom;}
    // optionalAttrs (cfg.zoomScrollOffset.envelopeLaneVerticalZoom != null) {envvzoomscale = cfg.zoomScrollOffset.envelopeLaneVerticalZoom;}
    // optionalAttrs (cfg.zoomScrollOffset.horizontalZoomCenter != null) {zoommode = cfg.zoomScrollOffset.horizontalZoomCenter;};
}
