{
  config,
  lib,
  reaBool,
  reaperLib,
  ...
}: let
  inherit (lib) types;
  inherit (reaperLib) reaperBitfield reaperPreference;

  cfg = config.programs.reaper.preferences.media;
  prefix = ["programs" "reaper" "preferences" "media"];
in {
  imports = [
    (lib.mkRenamedOptionModule (prefix ++ ["allowVideosToGoOffline"]) (prefix ++ ["allowVideosToGoOfflineSlow"]))
    (lib.mkRenamedOptionModule (prefix ++ ["tailLengthWhenUsingApplyFxToItemMs"]) (prefix ++ ["tailLengthWhenUsingApplyFxToItems"]))
    (lib.mkRenamedOptionModule (prefix ++ ["takeFxTailLengthMs"]) (prefix ++ ["takeFxTailLength"]))
    (lib.mkRenamedOptionModule (prefix ++ ["duplicateTakeFxWhenSplittingItems"]) (prefix ++ ["duplicateTakeFxWhenSplittingItemsIncludingSplitsCausedByRecordingNewTakes"]))
  ];

  options.programs.reaper.preferences.media = {
    setMediaItemsOfflineWhenApplicationIsNotActive = reaBool ''
      Set media items offline when application is not active, allowing other
      programs to access or modify their media files.
    '';
    allowVideosToGoOfflineSlow = reaBool ''
      Allow videos to go offline (slow). This also affects certain items decoded
      by VLC/FFmpeg and still images. Bringing these items back online can be
      slow. Only takes effect when "Set media items offline when application is
      not active" is enabled; REAPER retains this setting when that is disabled.
    '';
    promptToConfirmFilenameOnOpenCopyInEditor = reaBool ''
      Prompt to confirm filename on "open copy in editor". When disabled,
      REAPER uses the default filename without prompting.
    '';
    tailLengthWhenUsingApplyFxToItems = reaperPreference.option {
      type = types.nullOr types.ints.unsigned;
      example = 1000;
      description = ''
        Tail length when using Apply FX to items, in whole milliseconds.
        Adds time after the item for effects such as reverb and delay.
        Zero disables the extra tail.
      '';
    };
    takeFxTailLength = reaperPreference.option {
      type = types.nullOr types.ints.unsigned;
      example = 2000;
      description = ''
        Take FX tail length, in whole milliseconds. Adds time after the item
        for per-item/take FX in the batch converter and render/apply FX actions.
        Zero disables the extra tail.
      '';
    };
    duplicateTakeFxWhenSplittingItemsIncludingSplitsCausedByRecordingNewTakes = reaBool ''
      Duplicate take FX when splitting items (including splits caused by
      recording new takes). New split items receive copies of the take FX,
      which can increase memory usage.
    '';
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.media.tailLengthWhenUsingApplyFxToItems";
        gui = "Tail length when using Apply FX to items";
        value = cfg.tailLengthWhenUsingApplyFxToItems;
        section = "reaper";
        key = "applyfxtail";
        codec = "integer";
      }
      {
        path = "preferences.media.takeFxTailLength";
        gui = "Take FX tail length";
        value = cfg.takeFxTailLength;
        section = "reaper";
        key = "itemfxtail";
        codec = "integer";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      offlineinact = [
        {
          optionPath = "preferences.media.setMediaItemsOfflineWhenApplicationIsNotActive";
          gui = "Set media items offline when application is not active";
          option = cfg.setMediaItemsOfflineWhenApplicationIsNotActive;
          bit = 1;
        }
        {
          optionPath = "preferences.media.allowVideosToGoOfflineSlow";
          gui = "Allow videos to go offline (slow)";
          option = cfg.allowVideosToGoOfflineSlow;
          bit = 4;
        }
      ];
      opencopyprompt = [
        {
          optionPath = "preferences.media.promptToConfirmFilenameOnOpenCopyInEditor";
          gui = ''Prompt to confirm filename on "open copy in editor"'';
          option = cfg.promptToConfirmFilenameOnOpenCopyInEditor;
          bit = 1;
        }
      ];
      relativeedges = [
        {
          optionPath = "preferences.media.duplicateTakeFxWhenSplittingItemsIncludingSplitsCausedByRecordingNewTakes";
          gui = "Duplicate take FX when splitting items (including splits caused by recording new takes)";
          option = cfg.duplicateTakeFxWhenSplittingItemsIncludingSplitsCausedByRecordingNewTakes;
          bit = 8;
          inverted = true;
        }
      ];
    });
}
