{lib}: let
  # REAPER stores fader gains as linear amplitudes, while its preferences GUI
  # presents them in decibels. Nix has no exponentiation builtin, so calculate
  # e^x with a scaled Taylor series and square it back up.
  power = base: exponent:
    if exponent == 0
    then 1.0
    else base * power base (exponent - 1);

  exponential = value: let
    scaledValue = value / 16.0;
    series =
      builtins.foldl'
      (state: index: let
        term = state.term * scaledValue / index;
      in {
        inherit term;
        sum = state.sum + term;
      })
      {
        term = 1.0;
        sum = 1.0;
      }
      (builtins.genList (index: index + 1) 24);
  in
    power series.sum 16;
in {
  decibelsToSlider = decibels:
    exponential (decibels * 0.11512925464970229);

  trackHeights = {
    useCurrent = 0;
    small = 2;
    medium = 6;
    large = 16;
  };

  trackMeterDisplays = {
    multichannelPeaks = 0;
    stereoPeaks = 128;
    stereoRms = 1152;
    combinedRms = 2176;
    lufsM = 3200;
    lufsSReadoutMaximum = 4224;
    lufsSReadoutCurrent = 5248;
  };

  fixedLaneRecordingBehaviors = {
    newRecordingDoesNotAddLanesRecordIntoPlayingLane = 262144;
    newRecordingAddsLanesNewLanesPlayExclusively = 131072;
    newRecordingAddsLanesInLayersMultipleLanesPlayAtOnce = 4194304;
  };

  recordConfigMonitorInputModes = {
    off = 0;
    monitorInput = 256;
    monitorInputTapeAutoStyle = 512;
  };

  recordConfigRecordModes = {
    recordInputAudioOrMidi = 0;
    recordOutputStereo = 16;
    recordDisableInputMonitoringOnly = 32;
    recordOutputStereoLatencyCompensated = 48;
    recordOutputMidi = 64;
    recordOutputMono = 80;
    recordOutputMonoLatencyCompensated = 96;
    recordMidiOverdub = 112;
    recordMidiReplace = 128;
    recordMidiTouchReplace = 144;
    recordOutputMultichannel = 160;
    recordOutputMultichannelLatencyCompensated = 176;
    recordInputForceMono = 192;
    recordInputForceStereo = 208;
    recordInputForceMultichannel = 224;
    recordInputForceMidi = 240;
  };

  envelopePointShapes = {
    linear = 0;
    square = 65536;
    slowStartEnd = 131072;
    fastStart = 196608;
    fastEnd = 262144;
    bezier = 327680;
  };
  automationModes = {
    trimRead = 0;
    read = 1;
    touch = 2;
    write = 3;
    latch = 4;
    latchPreview = 5;
  };
  sendHardwareOutputModes = {
    postFaderPostPan = 0;
    preFx = 1;
    postFx = 2;
    preFaderPostFx = 3;
  };
  monitorInputModes = {
    off = 0;
    on = 256;
    tapeAutoStyle = 512;
  };
}
