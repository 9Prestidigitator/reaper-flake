{
  config,
  lib,
  pkgs,
  reaperControlOscWeb,
  reaperLib,
  ...
}: let
  inherit (lib) all imap0 literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
  inherit (reaperControlOscWeb) mackieControlFlags oscModes surfaceModes;

  cfg = config.programs.reaper.preferences.controlOscWeb;

  portType = types.addCheck types.ints.unsigned (value: value <= 65535);

  controlSurfaceType = types.submodule {
    options = {
      mode = mkOption {
        type = types.enum (builtins.attrNames surfaceModes);
        example = "mackieControlUniversal";
        description = "Control surface mode.";
      };

      midiInput = mkOption {
        type = types.int;
        default = -1;
        description = "Zero-based native MIDI input device index, or `-1` for none.";
      };

      midiOutput = mkOption {
        type = types.int;
        default = -1;
        description = "Zero-based native MIDI output device index, or `-1` for none.";
      };

      surfaceOffsetTracks = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Surface offset (tracks). When unset, REAPER's mode default is used: `1` for HUI and `0` for the other applicable modes.";
      };

      sizeTweak = mkOption {
        type = types.ints.positive;
        default = 9;
        description = "Size tweak. REAPER recommends leaving this at `9` unless the surface requires another value.";
      };

      faderCount = mkOption {
        type = types.ints.positive;
        default = 8;
        description = "HUI fader count; usually `8`, but it may be larger for multichannel HUI devices.";
      };

      ignoreFaderMovesWhenFaderIsNotBeingTouched = mkOption {
        type = types.bool;
        default = false;
        description = "Ignore fader moves when the fader is not being touched.";
      };

      mapF1F8ToGoToMarkers = mkOption {
        type = types.bool;
        default = false;
        description = "Map F1-F8 to go to markers.";
      };

      ignoreGlobalBankOffsetsAlwaysMapToTracksSpecified = mkOption {
        type = types.bool;
        default = false;
        description = "Ignore global bank offsets and always map to the tracks specified by the surface offset.";
      };

      deviceName = mkOption {
        type = types.str;
        default = "";
        description = "OSC device name.";
      };

      patternConfig = mkOption {
        type = types.str;
        default = "";
        example = "Default.ReaperOSC";
        description = "OSC pattern config. An empty string selects REAPER's Default pattern config.";
      };

      oscMode = mkOption {
        type = types.enum (builtins.attrNames oscModes);
        default = "disabled";
        example = "configureDeviceIpAndLocalPort";
        description = "OSC network mode.";
      };

      devicePort = mkOption {
        type = portType;
        default = 9000;
        description = "OSC device port.";
      };

      deviceIp = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "OSC device IP address or hostname.";
      };

      localListenPort = mkOption {
        type = portType;
        default = 8000;
        description = "OSC local listen port.";
      };

      allowBindingMessagesToReaperActionsAndFxLearn = mkOption {
        type = types.bool;
        default = false;
        description = "Allow binding OSC messages to REAPER actions and FX learn.";
      };

      outgoingMaxPacketSize = mkOption {
        type = types.ints.positive;
        default = 1024;
        description = "Outgoing OSC maximum packet size.";
      };

      waitBetweenPacketsMilliseconds = mkOption {
        type = types.ints.unsigned;
        default = 10;
        description = "Milliseconds to wait between outgoing OSC packets.";
      };

      runWebServerOnPort = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Run the web browser interface server.";
        };

        port = mkOption {
          type = portType;
          default = 8080;
          description = "Web browser interface server port.";
        };
      };

      usernamePassword = mkOption {
        type = types.str;
        default = "";
        example = "user:password";
        description = "Web browser interface username and password in REAPER's `username:password` format; blank disables authentication.";
      };

      defaultInterface = mkOption {
        type = types.str;
        default = "index.html";
        description = "Default web browser interface page, from user pages or REAPER's built-in pages.";
      };

      useRcReaperFm = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Publish the web browser interface through rc.reaper.fm.";
        };

        id = mkOption {
          type = types.str;
          default = "";
          description = "rc.reaper.fm interface ID.";
        };
      };
    };
  };

  quote = builtins.toJSON;
  boolFlag = value: bit:
    if value
    then bit
    else 0;

  midiPair = surface: "0 0 ${toString surface.midiInput} ${toString surface.midiOutput}";
  surfaceOffset = surface:
    if surface.surfaceOffsetTracks != null
    then surface.surfaceOffsetTracks
    else if surface.mode == "huiPartial"
    then 1
    else 0;
  offsetSize = surface: "${toString (surfaceOffset surface)} ${toString surface.sizeTweak} ${toString surface.midiInput} ${toString surface.midiOutput}";

  mackieFlags = surface:
    boolFlag surface.ignoreFaderMovesWhenFaderIsNotBeingTouched mackieControlFlags.ignoreFaderMovesWhenFaderIsNotBeingTouched
    + boolFlag surface.mapF1F8ToGoToMarkers mackieControlFlags.mapF1F8ToGoToMarkers
    + boolFlag surface.ignoreGlobalBankOffsetsAlwaysMapToTracksSpecified mackieControlFlags.ignoreGlobalBankOffsetsAlwaysMapToTracksSpecified;

  renderSurface = surface: let
    tag = surfaceModes.${surface.mode};
  in
    if builtins.elem surface.mode ["frontierAlphaTrack" "frontierTranzport" "preSonusFaderPort" "preSonusFaderPortV2_2018"]
    then "${tag} ${midiPair surface}"
    else if builtins.elem surface.mode ["behringerBcf2000UsingPreset1" "yamaha01x"]
    then "${tag} ${offsetSize surface}"
    else if surface.mode == "huiPartial"
    then "${tag} ${toString (surfaceOffset surface)} ${toString surface.faderCount} ${toString surface.midiInput} ${toString surface.midiOutput}"
    else if builtins.elem surface.mode ["mackieControlExtender" "mackieControlUniversal"]
    then "${tag} ${offsetSize surface} ${toString (mackieFlags surface)}"
    else if surface.mode == "console1MkIII"
    then "${tag} 0"
    else if surface.mode == "oscOpenSoundControl"
    then let
      mode = oscModes.${surface.oscMode};
      flags = mode.flags + boolFlag surface.allowBindingMessagesToReaperActionsAndFxLearn 4;
      localPort =
        if mode.useLocalPort
        then surface.localListenPort
        else 0;
      devicePort =
        if mode.useDevicePort
        then surface.devicePort
        else 0;
    in "${tag} ${quote surface.deviceName} ${toString flags} ${toString localPort} ${quote surface.deviceIp} ${toString devicePort} ${toString surface.outgoingMaxPacketSize} ${toString surface.waitBetweenPacketsMilliseconds} ${quote surface.patternConfig}"
    else "${tag} ${
      if surface.runWebServerOnPort.enable
      then "0"
      else "1"
    } ${toString surface.runWebServerOnPort.port} ${quote surface.usernamePassword} ${quote surface.defaultInterface} ${
      if surface.useRcReaperFm.enable
      then "1"
      else "0"
    } ${quote surface.useRcReaperFm.id}";

  renderedSurfaces =
    if cfg.controlSurfaces == null
    then {}
    else
      builtins.listToAttrs (imap0 (index: surface: {
          name = "csurf_${toString index}";
          value = renderSurface surface;
        })
        cfg.controlSurfaces);

  safeString = value: builtins.match ".*[\n\r].*" value == null;
  stringsAreSafe = surface:
    all safeString [surface.deviceName surface.patternConfig surface.deviceIp surface.usernamePassword surface.defaultInterface surface.useRcReaperFm.id];
in {
  options.programs.reaper.preferences.controlOscWeb = {
    controlSurfaces = mkOption {
      type = types.nullOr (types.listOf controlSurfaceType);
      default = null;
      example = literalExpression ''
        [
          {
            mode = "mackieControlUniversal";
            midiInput = 0;
            midiOutput = 0;
          }
          {
            mode = "webBrowserInterface";
            runWebServerOnPort.port = 8080;
          }
        ]
      '';
      description = "Ordered control surfaces, OSC devices, and web browser interfaces. `null` preserves REAPER's current list; a list replaces it.";
    };

    controlSurfaceDisplayUpdateFrequency = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      example = 15;
      description = "Control surface display update frequency in Hz (REAPER defaults to 15 Hz).";
    };

    warnWhenErrorsOpeningSurfaceMidiDevices = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Warn when errors occur while opening surface MIDI devices.";
    };

    closeControlSurfaceDevicesWhenStoppedAndNotActiveApplication = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Close control surface devices when stopped and REAPER is not the active application.";
    };

    closeControlSurfaceDevicesWhenRendering = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Close control surface devices when rendering.";
    };
  };

  config = {
    programs.reaper.ini = {
      sections.reaper =
        optionalAttrs (cfg.controlSurfaces != null) (renderedSurfaces // {csurf_cnt = builtins.length cfg.controlSurfaces;})
        // optionalAttrs (cfg.controlSurfaceDisplayUpdateFrequency != null) {
          csurfrate = cfg.controlSurfaceDisplayUpdateFrequency;
        };

      bitfields.reaper =
        reaperBitfield.entry "errnowarn" [
          {
            bit = 4;
            option = cfg.warnWhenErrorsOpeningSurfaceMidiDevices;
            inverted = true;
          }
        ]
        // reaperBitfield.entry (
          if pkgs.stdenv.hostPlatform.isLinux
          then "audiocloseinactive_linux"
          else "audiocloseinactive"
        ) [
          {
            bit = 8;
            option = cfg.closeControlSurfaceDevicesWhenStoppedAndNotActiveApplication;
          }
          {
            bit = 16;
            option = cfg.closeControlSurfaceDevicesWhenRendering;
          }
        ];
    };

    assertions = [
      {
        assertion = cfg.controlSurfaces == null || all (surface: surface.midiInput >= -1 && surface.midiOutput >= -1) cfg.controlSurfaces;
        message = "REAPER control surface MIDI input/output indexes must be `-1` or greater.";
      }
      {
        assertion = cfg.controlSurfaces == null || all stringsAreSafe cfg.controlSurfaces;
        message = "REAPER control surface string values must not contain newlines.";
      }
    ];
  };
}
