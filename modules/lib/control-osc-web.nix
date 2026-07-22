{
  surfaceModes = {
    behringerBcf2000UsingPreset1 = "BCF2K";
    console1MkIII = "CONSOLE1";
    frontierAlphaTrack = "ALPHATRACK";
    frontierTranzport = "TRANZPORT";
    huiPartial = "HUI";
    mackieControlExtender = "MCUEX";
    mackieControlUniversal = "MCU";
    oscOpenSoundControl = "OSC";
    preSonusFaderPort = "FADERPORT";
    preSonusFaderPortV2_2018 = "FADERPORT2";
    webBrowserInterface = "HTTP";
    yamaha01x = "01X";
  };

  oscModes = {
    deviceIpPort = {
      flags = 3;
      useLocalPort = false;
      useDevicePort = true;
    };
    deviceIpPortSendOnly = {
      flags = 2;
      useLocalPort = true;
      useDevicePort = true;
    };
    localPort = {
      flags = 3;
      useLocalPort = true;
      useDevicePort = false;
    };
    localPortReceiveOnly = {
      flags = 1;
      useLocalPort = true;
      useDevicePort = true;
    };
    configureDeviceIpAndLocalPort = {
      flags = 3;
      useLocalPort = true;
      useDevicePort = true;
    };
    disabled = {
      flags = 0;
      useLocalPort = true;
      useDevicePort = true;
    };
  };

  mackieControlFlags = {
    ignoreFaderMovesWhenFaderIsNotBeingTouched = 1;
    mapF1F8ToGoToMarkers = 2;
    ignoreGlobalBankOffsetsAlwaysMapToTracksSpecified = 4;
  };
}
