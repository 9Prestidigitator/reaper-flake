{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
  cfg = config.programs.reaper.preferences.project.trackSendDefaults;

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
in {
  options.programs.reaper.preferences.project.trackSendDefaults = {
    tracks = {
      defaultVolume = mkOption {
        type = types.nullOr types.float;
        default = null;
        example = 1.0;
        description = "Default new-track volume as REAPER's slider value, where `1.0` is 0 dB.";
      };

      visibleEnvelopes = {
        preFxVolume = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks show the pre-FX volume envelope.";
        };
        preFxPan = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks show the pre-FX pan envelope.";
        };
        volume = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks show the volume envelope.";
        };
        pan = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks show the pan envelope.";
        };
        mute = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks show the mute envelope.";
        };
      };

      defaultEnvelopePointShape = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames envelopePointShapes));
        default = null;
        example = "linear";
        description = "Default point shape for new track envelopes.";
      };

      defaultAutomationMode = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames automationModes));
        default = null;
        example = "trimRead";
        description = "Default automation mode for new tracks.";
      };

      armNewEnvelopes = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new track envelopes are armed by default.";
      };

      defaultHeight = mkOption {
        type = types.nullOr (types.ints.between 0 40);
        default = null;
        example = 6;
        description = "Default track height in new projects, using REAPER's 0–40 zoom value (`6` is Medium).";
      };

      showInMixer = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new tracks are shown in the mixer.";
      };

      mainParentSend = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new tracks enable their Main (parent) send.";
      };

      freeItemPositioning = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new tracks enable free item positioning.";
      };

      recording = {
        arm = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks are record-armed.";
        };

        automaticallyArmWhenSelected = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether selecting a new track automatically record-arms it.";
        };

        modeBitfield = mkOption {
          type = types.nullOr (types.ints.between 0 15);
          default = null;
          example = 0;
          description = ''
            Native four-bit value for REAPER's Record configuration menu. This
            menu includes input, MIDI overdub/replace, output, and force-format
            recording modes; its available labels vary with REAPER versions.
          '';
        };

        input = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = 6112;
          description = ''
            Native REAPER value for the default recording input. Use `-1` for
            None; audio and MIDI device/input values are hardware-dependent.
          '';
        };

        monitorInput = mkOption {
          type = types.nullOr (types.enum (builtins.attrNames monitorInputModes));
          default = null;
          example = "on";
          description = "Default input-monitoring mode for new tracks.";
        };

        monitorTrackMediaWhenRecording = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks monitor existing media while recording.";
        };

        preservePdcDelayedMonitoringInRecordedItems = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether new tracks preserve PDC-delayed monitoring in recorded items.";
        };
      };
    };

    newVolumeEnvelopes = {
      scaling = mkOption {
        type = types.nullOr (types.enum ["amplitude" "volumeFader"]);
        default = null;
        example = "volumeFader";
        description = "Scaling used for new volume envelopes.";
      };

      warnWhenChangingScalingChangesEnvelopeSound = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether REAPER warns when changing envelope scaling changes the envelope's sound.";
      };
    };

    sendsAndTrackHardwareOutputs = {
      defaultSendVolume = mkOption {
        type = types.nullOr types.float;
        default = null;
        example = 1.0;
        description = "Default send gain as REAPER's slider value, where `1.0` is 0 dB.";
      };

      defaultHardwareOutputVolume = mkOption {
        type = types.nullOr types.float;
        default = null;
        example = 1.0;
        description = "Default hardware-output gain as REAPER's slider value, where `1.0` is 0 dB.";
      };

      defaultMode = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames sendHardwareOutputModes));
        default = null;
        example = "postFaderPostPan";
        description = "Default routing mode for new sends and track hardware outputs.";
      };

      sendMidiByDefault = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new sends send MIDI by default.";
      };

      sendAudioByDefault = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new sends send audio by default.";
      };
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.tracks.defaultVolume != null) {
      deftrackvol = cfg.tracks.defaultVolume;
    }
    // optionalAttrs (cfg.tracks.defaultHeight != null) {
      defvzoom = cfg.tracks.defaultHeight;
    }
    // optionalAttrs (cfg.tracks.recording.input != null) {
      deftrackrecinput = cfg.tracks.recording.input;
    }
    // optionalAttrs (cfg.sendsAndTrackHardwareOutputs.defaultSendVolume != null) {
      defsendvol = cfg.sendsAndTrackHardwareOutputs.defaultSendVolume;
    }
    // optionalAttrs (cfg.sendsAndTrackHardwareOutputs.defaultHardwareOutputVolume != null) {
      defhwvol = cfg.sendsAndTrackHardwareOutputs.defaultHardwareOutputVolume;
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    defenvs = [
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.visibleEnvelopes.preFxVolume";
        gui = "Default visible envelope: Volume (pre-FX)";
        option = cfg.tracks.visibleEnvelopes.preFxVolume;
        bit = 1;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.visibleEnvelopes.preFxPan";
        gui = "Default visible envelope: Pan (pre-FX)";
        option = cfg.tracks.visibleEnvelopes.preFxPan;
        bit = 2;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.visibleEnvelopes.volume";
        gui = "Default visible envelope: Volume";
        option = cfg.tracks.visibleEnvelopes.volume;
        bit = 4;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.visibleEnvelopes.pan";
        gui = "Default visible envelope: Pan";
        option = cfg.tracks.visibleEnvelopes.pan;
        bit = 8;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.visibleEnvelopes.mute";
        gui = "Default visible envelope: Mute";
        option = cfg.tracks.visibleEnvelopes.mute;
        bit = 32768;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.defaultEnvelopePointShape";
        gui = "Default envelope point shape";
        option = cfg.tracks.defaultEnvelopePointShape;
        mask = 458752;
        value = envelopePointShapes.${cfg.tracks.defaultEnvelopePointShape};
      }
    ];

    defautomode = [
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.defaultAutomationMode";
        gui = "Default automation mode";
        option = cfg.tracks.defaultAutomationMode;
        mask = 7;
        value = automationModes.${cfg.tracks.defaultAutomationMode};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.armNewEnvelopes";
        gui = "Arm new envelopes";
        option = cfg.tracks.armNewEnvelopes;
        bit = 512;
        inverted = true;
      }
    ];

    newtflag = [
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.showInMixer";
        gui = "Show in mixer";
        option = cfg.tracks.showInMixer;
        bit = 1;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.mainParentSend";
        gui = "Main (parent) send";
        option = cfg.tracks.mainParentSend;
        bit = 2;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.freeItemPositioning";
        gui = "Free item positioning";
        option = cfg.tracks.freeItemPositioning;
        bit = 4;
      }
    ];

    deftrackrecflags = [
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.recording.arm";
        gui = "Record arm";
        option = cfg.tracks.recording.arm;
        bit = 1;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.recording.automaticallyArmWhenSelected";
        gui = "Automatic record-arm when track selected";
        option = cfg.tracks.recording.automaticallyArmWhenSelected;
        bit = 2;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.recording.modeBitfield";
        gui = "Record configuration";
        option = cfg.tracks.recording.modeBitfield;
        mask = 240;
        value = cfg.tracks.recording.modeBitfield * 16;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.recording.monitorInput";
        gui = "Monitor input";
        option = cfg.tracks.recording.monitorInput;
        mask = 768;
        value = monitorInputModes.${cfg.tracks.recording.monitorInput};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.recording.monitorTrackMediaWhenRecording";
        gui = "Monitor track media when recording";
        option = cfg.tracks.recording.monitorTrackMediaWhenRecording;
        bit = 4096;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.tracks.recording.preservePdcDelayedMonitoringInRecordedItems";
        gui = "Preserve PDC delayed monitoring in recorded items";
        option = cfg.tracks.recording.preservePdcDelayedMonitoringInRecordedItems;
        bit = 8192;
      }
    ];

    volenvrange = [
      {
        optionPath = "preferences.project.trackSendDefaults.newVolumeEnvelopes.scaling";
        gui = "Scaling for new volume envelopes";
        option = cfg.newVolumeEnvelopes.scaling;
        mask = 2;
        value =
          if cfg.newVolumeEnvelopes.scaling == "volumeFader"
          then 2
          else 0;
      }
    ];

    errnowarn = [
      {
        optionPath = "preferences.project.trackSendDefaults.newVolumeEnvelopes.warnWhenChangingScalingChangesEnvelopeSound";
        gui = "Warn when changing volume envelope scaling changes envelope sound";
        option = cfg.newVolumeEnvelopes.warnWhenChangingScalingChangesEnvelopeSound;
        bit = 16;
        inverted = true;
      }
    ];

    defsendflag = [
      {
        optionPath = "preferences.project.trackSendDefaults.sendsAndTrackHardwareOutputs.defaultMode";
        gui = "Send/hardware output default mode";
        option = cfg.sendsAndTrackHardwareOutputs.defaultMode;
        mask = 3;
        value = sendHardwareOutputModes.${cfg.sendsAndTrackHardwareOutputs.defaultMode};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.sendsAndTrackHardwareOutputs.sendMidiByDefault";
        gui = "Sends send MIDI by default";
        option = cfg.sendsAndTrackHardwareOutputs.sendMidiByDefault;
        bit = 256;
        inverted = true;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.sendsAndTrackHardwareOutputs.sendAudioByDefault";
        gui = "Sends send audio by default";
        option = cfg.sendsAndTrackHardwareOutputs.sendAudioByDefault;
        bit = 512;
        inverted = true;
      }
    ];
  };
}
