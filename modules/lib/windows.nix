let
  # REAPER 7.80 primary-unit codes. The codec handles legacy combinations
  # and the secondary unit in the high byte of projtimemode2.
  timeUnits = {
    minutesSeconds = 0;
    measuresBeats = 2;
    seconds = 3;
    samples = 4;
    hoursMinutesSecondsFrames = 5;
    absoluteFrames = 8;
  };
in {
  transportControls = {
    inherit timeUnits;
    recordMode = {
      normal = 1;
      timeSelectionAutoPunch = 2;
      selectedItemsAutoPunch = 0;
    };
    timeDisplayCodec = {
      type = "transport-time-display";
      units = timeUnits;
    };
  };
  tcpHelpBar = {
    informationDisplay = {
      noInformationDisplay = 0;
      reaperTips = 1;
      trackItemCount = 2;
      selectedTrackItemEnvelopeDetails = 3;
      cpuRamUseTimeSinceLastSave = 4;
    };
  };

  performanceMeter = {
    cpuUtilizationDisplay = {
      allCoresFullyUtilized = 0;
      oneCoreFullyUtilized = 131072;
      longestBlockIsRealtime = 393216;
    };
  };

  transport = {
    belowArranger = 0;
    aboveRuler = 1;
    bottomOfMainWindow = 2;
    topOfMainWindow = 3;
  };
}
