{lib}: let
  inherit (lib) types;

  number = types.either types.int types.float;
  boundedNumber = description: min: max:
    (types.addCheck number (value: value >= min && value <= max))
    // {
      inherit description;
    };
in {
  inherit boundedNumber number;

  percentage = {
    maxVerticalZoom = boundedNumber "zoom percentage between 0.125 and 8" 0.125 8;
    envelopeVerticalZoom = boundedNumber "zoom percentage between 0 and 1000" 0 1000;
    scrollStep = boundedNumber "scroll step percentage between 0.01 and 1" 0.01 1;
  };

  trackControlPanel = {
    sliderMinimum = boundedNumber "volume fader minimum between -160 and -6 dB" (-160) (-6);
    sliderMaximum = boundedNumber "volume fader maximum between 0 and 60 dB" 0 60;
    sliderShape =
      (types.addCheck number (value: value == -1.0 || (value >= 0.25 && value <= 4.0)))
      // {
        description = "volume fader shape of -1 for REAPER default, or between 0.25 and 4";
      };
  };

  general = {
    uiScale = boundedNumber "UI scale between 0.3 and 3" 0.3 3;
  };
}
