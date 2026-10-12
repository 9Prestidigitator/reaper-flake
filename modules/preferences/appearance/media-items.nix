{
  config,
  lib,
  reaBool,
  reaEnum,
  reaperLib,
  ...
}: let
  inherit (lib) types;
  inherit (reaperLib) reaperBitfield reaperPreference;
  cfg = config.programs.reaper.preferences.appearance.mediaItems;
  itemTakeRatePitch = {
    normalLabels = 0;
    abbreviate = 512;
    numbersOnly = 1024;
  };
in {
  options.programs.reaper.preferences.appearance.mediaItems = {
    displayMediaItemTakeName = reaBool "Display media item take name.";
    displayMediaItemPitchPlayrateIfSet = reaBool "Display media item pitch/playrate if set.";
    displayMediaItemGainIfSet = reaBool "Display media item gain if set.";
    drawLabelsOverSolidBackgroundForEasierReading = reaBool "Draw labels over solid background for easier reading.";
    showLabelsForItemsWhenItemEdgesAreNotVisible = reaBool "Show labels for items when item edges are not visible.";
    drawLabelsAboveTheItemWhenMediaItemHeightIsMoreThan.enable = reaBool "Draw labels above the item when media item height is more than.";
    automaticallyColorAnyRecordingPassThatAddsTakesOrLanes = reaBool "Automatically color any recording pass that adds takes or lanes.";
    automaticallyColorAnyMediaItemsThatSharePooledMidiEvents = reaBool "Automatically color any media items that share pooled MIDI events.";
    fasterLessPreciseItemBackgroundDisplayRequiresThemeReload = reaBool "Faster/less precise item background display (requires theme reload).";
    drawSelectionIndicatorOnItems = reaBool "Draw selection indicator on items.";
    drawLabelsAboveTheItemWhenMediaItemHeightIsMoreThan.pixels = reaperPreference.option {
      type = types.nullOr types.ints.unsigned;
      example = 28;
      description = "Media item height threshold in pixels. Retained independently of the enable checkbox; zero is allowed.";
    };
    hideLabelsWhenMediaItemHeightIsLessThan = reaperPreference.option {
      type = types.nullOr types.ints.unsigned;
      example = 28;
      description = "Hide labels below this media item height, in whole pixels. Zero disables this height threshold.";
    };
    maximumStretchMarkerHandleSize.pixels = reaperPreference.option {
      type = types.nullOr (types.ints.between 1 100);
      example = 6;
      description = "Maximum stretch marker handle size in whole pixels, from 1 to 100. REAPER also limits the size by the percentage of take height.";
    };
    maximumStretchMarkerHandleSize.percentOfTakeHeight = reaperPreference.option {
      type = types.nullOr (types.ints.between 1 30);
      example = 12;
      description = "Maximum stretch marker handle size as a whole percentage of take height, from 1 to 30. REAPER also limits the size by the pixel maximum.";
    };
    itemTakeRatePitch = reaEnum {
      enum = builtins.attrNames itemTakeRatePitch;
      example = "normalLabels";
      description = "Item take rate/pitch label format: Normal labels, Abbreviate, or Numbers only.";
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.appearance.mediaItems.drawLabelsAboveTheItemWhenMediaItemHeightIsMoreThan.pixels";
        gui = "Draw labels above the item when media item height is more than";
        value = cfg.drawLabelsAboveTheItemWhenMediaItemHeightIsMoreThan.pixels;
        section = "reaper";
        key = "itemlabel_minheight";
        codec = "integer";
      }
      {
        path = "preferences.appearance.mediaItems.hideLabelsWhenMediaItemHeightIsLessThan";
        gui = "Hide labels when media item height is less than";
        value = cfg.hideLabelsWhenMediaItemHeightIsLessThan;
        section = "reaper";
        key = "itemlabel_hideheight";
        codec = "integer";
      }
      {
        path = "preferences.appearance.mediaItems.maximumStretchMarkerHandleSize.pixels";
        gui = "Maximum stretch marker handle size: pixels";
        value = cfg.maximumStretchMarkerHandleSize.pixels;
        section = "reaper";
        key = "smmaxsz";
        codec = "integer";
      }
      {
        path = "preferences.appearance.mediaItems.maximumStretchMarkerHandleSize.percentOfTakeHeight";
        gui = "Maximum stretch marker handle size: % of take height";
        value = cfg.maximumStretchMarkerHandleSize.percentOfTakeHeight;
        section = "reaper";
        key = "smmaxsz_pct";
        codec = "integer";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
      labelitems2 = [
        {
          optionPath = "preferences.appearance.mediaItems.displayMediaItemTakeName";
          gui = "Display media item take name";
          option = cfg.displayMediaItemTakeName;
          bit = 1;
        }
        {
          optionPath = "preferences.appearance.mediaItems.displayMediaItemPitchPlayrateIfSet";
          gui = "Display media item pitch/playrate if set";
          option = cfg.displayMediaItemPitchPlayrateIfSet;
          bit = 4;
        }
        {
          optionPath = "preferences.appearance.mediaItems.displayMediaItemGainIfSet";
          gui = "Display media item gain if set";
          option = cfg.displayMediaItemGainIfSet;
          bit = 16;
          inverted = true;
        }
        {
          optionPath = "preferences.appearance.mediaItems.showLabelsForItemsWhenItemEdgesAreNotVisible";
          gui = "Show labels for items when item edges are not visible";
          option = cfg.showLabelsForItemsWhenItemEdgesAreNotVisible;
          bit = 2;
        }
        {
          optionPath = "preferences.appearance.mediaItems.drawLabelsAboveTheItemWhenMediaItemHeightIsMoreThan.enable";
          gui = "Draw labels above the item when media item height is more than";
          option = cfg.drawLabelsAboveTheItemWhenMediaItemHeightIsMoreThan.enable;
          bit = 8;
        }
        {
          optionPath = "preferences.appearance.mediaItems.drawSelectionIndicatorOnItems";
          gui = "Draw selection indicator on items";
          option = cfg.drawSelectionIndicatorOnItems;
          bit = 1024;
          inverted = true;
        }
      ];
      peaksedges = [
        {
          optionPath = "preferences.appearance.mediaItems.drawLabelsOverSolidBackgroundForEasierReading";
          gui = "Draw labels over solid background for easier reading";
          option = cfg.drawLabelsOverSolidBackgroundForEasierReading;
          bit = 8;
        }
      ];
      tinttcp = [
        {
          optionPath = "preferences.appearance.mediaItems.automaticallyColorAnyRecordingPassThatAddsTakesOrLanes";
          gui = "Automatically color any recording pass that adds takes or lanes";
          option = cfg.automaticallyColorAnyRecordingPassThatAddsTakesOrLanes;
          bit = 512;
        }
        {
          optionPath = "preferences.appearance.mediaItems.automaticallyColorAnyMediaItemsThatSharePooledMidiEvents";
          gui = "Automatically color any media items that share pooled MIDI events";
          option = cfg.automaticallyColorAnyMediaItemsThatSharePooledMidiEvents;
          bit = 1024;
        }
        {
          optionPath = "preferences.appearance.mediaItems.fasterLessPreciseItemBackgroundDisplayRequiresThemeReload";
          gui = "Faster/less precise item background display (requires theme reload)";
          option = cfg.fasterLessPreciseItemBackgroundDisplayRequiresThemeReload;
          bit = 4096;
          inverted = true;
        }
      ];
      itemicons = [
        {
          optionPath = "preferences.appearance.mediaItems.itemTakeRatePitch";
          gui = "Item take rate/pitch";
          option = cfg.itemTakeRatePitch;
          mask = 1536;
          valueFor = value: itemTakeRatePitch.${value};
          importValues = itemTakeRatePitch;
        }
      ];
    });
}
