{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield reaperTypes reaperPreference reaperCodecs;

  cfg = config.programs.reaper.preferences.media;
in {
  options.programs.reaper.preferences.media = {
    setMediaItemsOfflineWhenApplicationIsNotActive = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Sets project media inactive when REAPER is inactive, so that other programs can access/modify the media.";
    };
    allowVideosToGoOffline = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Allows video items (and certain items decoded by VLC/FFmpeg, and still images) to be set offline, which can be slow to bring back online.";
    };
    promptToConfirmFilenameOnOpenCopyInEditor = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Allow choosing the filename used when using 'open copy' action. If unchecked, the default filename will be used.";
    };

    tailLengthWhenUsingApplyFxToItemMs = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 1250;
      description = "When using apply FX action, allow this much extra time at the end for reverb tails, delay lines, etc.";
    };
    takeFxTailLengthMs = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 2500;
      description = "When using the batch converter or various render/apply FX actions with per-item/take FX, add this much time past the item end for tails.";
    };

    duplicateTakeFxWhenSplittingItems = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When using take FX, duplicate take FX when splitting (so that new split items get copies of the FX). Caution, this can use a lot of RAM if you aren't careful.";
    };
  };
}
