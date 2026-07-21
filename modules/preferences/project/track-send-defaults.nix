{
  config,
  lib,
  reaperLib,
  reaperProject,
  ...
}: let
  inherit (lib) mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield reaperTypes;
  inherit (reaperProject) decibelsToSlider envelopePointShapes automationModes fixedLaneRecordingBehaviors recordConfigMonitorInputModes recordConfigRecordModes sendHardwareOutputModes trackHeights trackMeterDisplays;

  cfg = config.programs.reaper.preferences.project.trackSendDefaults;
in {
  options.programs.reaper.preferences.project.trackSendDefaults = {
    trackVolumeFaderGain = mkOption {
      type = types.nullOr reaperTypes.number;
      default = null;
      example = 1.0;
      description = "Track volume fader gain in dB for new tracks.";
    };

    mainParentSend = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Enable the Main (parent) send for new tracks.";
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

    envelopePointShape = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames envelopePointShapes));
      default = null;
      example = "linear";
      description = "Default envelope point shape for new track envelopes.";
    };

    automationMode = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames automationModes));
      default = null;
      example = "trimRead";
      description = "Default automation mode for new tracks.";
    };
    armNewEnvelopes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Arm new envelopes by default.";
    };

    trackHeightInNewProjects = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames trackHeights));
      default = null;
      example = "medium";
      description = "Track height in new projects.";
    };

    showInMixer = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Whether new tracks are shown in the mixer.";
    };

    freeItemPositioning = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Enable free item positioning for new tracks.";
    };

    fixedItemLanes = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Enable fixed item lanes for new tracks.";
    };

    fixedLaneDefaults = {
      laneSize = mkOption {
        type = types.nullOr (types.enum ["smallLanes" "bigLanes"]);
        default = null;
        example = "bigLanes";
        description = "Default fixed lane size.";
      };

      showPlayOnlyOneLane = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show/play only one lane.";
      };

      hideLaneButtons = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Hide lane buttons.";
      };

      mediaItemsInHigherNumberedLanesMaskPlaybackOfLowerNumberedLanes = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Media items in higher numbered lanes mask playback of lower numbered lanes.";
      };

      allowEditingSourceMediaWhileComping = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Allow editing source media while comping.";
      };

      createCompAreasForNewRecordingWhileComping = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Create comp areas for new recording while comping.";
      };

      newRecordingBehavior = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames fixedLaneRecordingBehaviors));
        default = null;
        example = "newRecordingAddsLanesNewLanesPlayExclusively";
        description = "Default behavior for new recording with fixed lanes.";
      };

      automaticallyDeleteEmptyLanesAtBottomOfTrack = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Automatically delete empty lanes at bottom of track.";
      };
    };

    recordArm = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Whether new tracks are record-armed.";
    };

    recordConfig = {
      monitorInput = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames recordConfigMonitorInputModes));
        default = null;
        example = "monitorInput";
        description = "Monitor Input mode.";
      };

      monitorTrackMediaWhenRecording = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Monitor track media when recording.";
      };

      preservePdcDelayedMonitoringInRecordedItems = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Preserve PDC delayed monitoring in recorded items.";
      };

      record = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames recordConfigRecordModes));
        default = null;
        example = "recordInputAudioOrMidi";
        description = "Record mode.";
      };

      input = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = -1;
        description = ''
          Input selection as REAPER's native `deftrackrecinput` value. Use `-1`
          for Input: None. Audio inputs are zero-based: `0` is mono channel 1,
          `7` is mono channel 8, `1024 + n` selects a stereo pair beginning at
          channel `n + 1`, and `2048 + n` selects a multichannel input beginning
          at channel `n + 1`. MIDI uses bit `4096` plus encoded device and channel
          fields; for example, `6112` is All MIDI Inputs on all channels and
          `6113` is All MIDI Inputs on channel 1. Specific MIDI-device values are
          hardware-dependent and may not be portable between machines.
        '';
      };

      automaticRecordArmWhenTrackSelected = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Automatic record-arm when track selected.";
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

    trackMeterDisplay = {
      display = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames trackMeterDisplays));
        default = null;
        example = "stereoPeaks";
        description = "Track meter display.";
      };

      lufsMeasuresFirstTwoChannelsOnlyIgnoreSidechain = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "LUFS measures first two channels only (ignore sidechain).";
      };

      displayGainReductionForPlugInsThatSupportIt = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Display gain reduction for plug-ins that support it.";
      };
    };

    sendsTrackHardwareOutputs = {
      sendGain = mkOption {
        type = types.nullOr reaperTypes.number;
        default = null;
        example = 1.0;
        description = "Send gain in dB for new sends.";
      };

      hardwareOutputGain = mkOption {
        type = types.nullOr reaperTypes.number;
        default = null;
        example = 1.0;
        description = "Hardware output gain in dB for new track hardware outputs.";
      };

      sendHardwareOutputMode = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames sendHardwareOutputModes));
        default = null;
        example = "postFaderPostPan";
        description = "Default routing mode for new sends and track hardware outputs.";
      };

      sendsSendMidiByDefault = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new sends send MIDI by default.";
      };

      sendsSendAudioByDefault = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether new sends send audio by default.";
      };
    };
  };

  config.assertions = [
    {
      assertion = !(cfg.freeItemPositioning == true && cfg.fixedItemLanes == true);
      message = ''
        programs.reaper.preferences.project.trackSendDefaults.freeItemPositioning and
        programs.reaper.preferences.project.trackSendDefaults.fixedItemLanes are mutually exclusive.
      '';
    }
  ];

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.trackVolumeFaderGain != null) {
      deftrackvol = decibelsToSlider cfg.trackVolumeFaderGain;
    }
    // optionalAttrs (cfg.trackHeightInNewProjects != null) {
      defvzoom = trackHeights.${cfg.trackHeightInNewProjects};
    }
    // optionalAttrs (cfg.recordConfig.input != null) {
      deftrackrecinput = cfg.recordConfig.input;
    }
    // optionalAttrs (cfg.sendsTrackHardwareOutputs.sendGain != null) {
      defsendvol = decibelsToSlider cfg.sendsTrackHardwareOutputs.sendGain;
    }
    // optionalAttrs (cfg.sendsTrackHardwareOutputs.hardwareOutputGain != null) {
      defhwvol = decibelsToSlider cfg.sendsTrackHardwareOutputs.hardwareOutputGain;
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    defenvs = [
      {
        optionPath = "preferences.project.trackSendDefaults.visibleEnvelopes.preFxVolume";
        gui = "Default visible envelope: Volume (pre-FX)";
        option = cfg.visibleEnvelopes.preFxVolume;
        bit = 1;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.visibleEnvelopes.preFxPan";
        gui = "Default visible envelope: Pan (pre-FX)";
        option = cfg.visibleEnvelopes.preFxPan;
        bit = 2;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.visibleEnvelopes.volume";
        gui = "Default visible envelope: Volume";
        option = cfg.visibleEnvelopes.volume;
        bit = 4;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.visibleEnvelopes.pan";
        gui = "Default visible envelope: Pan";
        option = cfg.visibleEnvelopes.pan;
        bit = 8;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.visibleEnvelopes.mute";
        gui = "Default visible envelope: Mute";
        option = cfg.visibleEnvelopes.mute;
        bit = 32768;
      }

      {
        optionPath = "preferences.project.trackSendDefaults.envelopePointShape";
        gui = "Default envelope point shape";
        option = cfg.envelopePointShape;
        mask = 458752;
        value = envelopePointShapes.${cfg.envelopePointShape};
      }
    ];

    defautomode = [
      {
        optionPath = "preferences.project.trackSendDefaults.automationMode";
        gui = "Default automation mode";
        option = cfg.automationMode;
        mask = 7;
        value = automationModes.${cfg.automationMode};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.armNewEnvelopes";
        gui = "Arm new envelopes";
        option = cfg.armNewEnvelopes;
        bit = 512;
        inverted = true;
      }
    ];

    newtflag = [
      {
        optionPath = "preferences.project.trackSendDefaults.showInMixer";
        gui = "Show in mixer";
        option = cfg.showInMixer;
        bit = 1;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.mainParentSend";
        gui = "Main (parent) send";
        option = cfg.mainParentSend;
        bit = 2;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.freeItemPositioning";
        gui = "Free item positioning / Fixed item lanes";
        configured = cfg.freeItemPositioning != null || cfg.fixedItemLanes != null;
        mask = 12;
        value =
          if cfg.fixedItemLanes or false
          then 8
          else if cfg.freeItemPositioning or false
          then 4
          else 0;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.laneSize";
        gui = "Fixed lane defaults: Small lanes / Big lanes";
        option = cfg.fixedLaneDefaults.laneSize;
        mask = 16;
        value =
          if cfg.fixedLaneDefaults.laneSize == "smallLanes"
          then 16
          else 0;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.showPlayOnlyOneLane";
        gui = "Fixed lane defaults: Show/play only one lane";
        option = cfg.fixedLaneDefaults.showPlayOnlyOneLane;
        bit = 1048576;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.hideLaneButtons";
        gui = "Fixed lane defaults: Hide lane buttons";
        option = cfg.fixedLaneDefaults.hideLaneButtons;
        bit = 524288;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.mediaItemsInHigherNumberedLanesMaskPlaybackOfLowerNumberedLanes";
        gui = "Fixed lane defaults: Media items in higher numbered lanes mask playback of lower numbered lanes";
        option = cfg.fixedLaneDefaults.mediaItemsInHigherNumberedLanesMaskPlaybackOfLowerNumberedLanes;
        bit = 2097152;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.allowEditingSourceMediaWhileComping";
        gui = "Fixed lane defaults: Allow editing source media while comping";
        option = cfg.fixedLaneDefaults.allowEditingSourceMediaWhileComping;
        bit = 65536;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.createCompAreasForNewRecordingWhileComping";
        gui = "Fixed lane defaults: Create comp areas for new recording while comping";
        option = cfg.fixedLaneDefaults.createCompAreasForNewRecordingWhileComping;
        bit = 64;
        inverted = true;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.newRecordingBehavior";
        gui = "Fixed lane defaults: Override project recording behavior";
        option = cfg.fixedLaneDefaults.newRecordingBehavior;
        mask = 4587520;
        value = fixedLaneRecordingBehaviors.${cfg.fixedLaneDefaults.newRecordingBehavior};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.fixedLaneDefaults.automaticallyDeleteEmptyLanesAtBottomOfTrack";
        gui = "Fixed lane defaults: Automatically delete empty lanes at bottom of track";
        option = cfg.fixedLaneDefaults.automaticallyDeleteEmptyLanesAtBottomOfTrack;
        bit = 32;
        inverted = true;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.trackMeterDisplay.display";
        gui = "Track meter display";
        option = cfg.trackMeterDisplay.display;
        mask = 7296;
        value = trackMeterDisplays.${cfg.trackMeterDisplay.display};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.trackMeterDisplay.lufsMeasuresFirstTwoChannelsOnlyIgnoreSidechain";
        gui = "LUFS measures first two channels only (ignore sidechain)";
        option = cfg.trackMeterDisplay.lufsMeasuresFirstTwoChannelsOnlyIgnoreSidechain;
        bit = 8192;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.trackMeterDisplay.displayGainReductionForPlugInsThatSupportIt";
        gui = "Display gain reduction for plug-ins that support it";
        option = cfg.trackMeterDisplay.displayGainReductionForPlugInsThatSupportIt;
        bit = 16384;
      }
    ];

    deftrackrecflags = [
      {
        optionPath = "preferences.project.trackSendDefaults.recordArm";
        gui = "Record arm";
        option = cfg.recordArm;
        bit = 1;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.recordConfig.automaticRecordArmWhenTrackSelected";
        gui = "Automatic record-arm when track selected";
        option = cfg.recordConfig.automaticRecordArmWhenTrackSelected;
        bit = 2;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.recordConfig.record";
        gui = "Record";
        option = cfg.recordConfig.record;
        mask = 240;
        value = recordConfigRecordModes.${cfg.recordConfig.record};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.recordConfig.monitorInput";
        gui = "Monitor Input";
        option = cfg.recordConfig.monitorInput;
        mask = 768;
        value = recordConfigMonitorInputModes.${cfg.recordConfig.monitorInput};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.recordConfig.monitorTrackMediaWhenRecording";
        gui = "Monitor track media when recording";
        option = cfg.recordConfig.monitorTrackMediaWhenRecording;
        bit = 4096;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.recordConfig.preservePdcDelayedMonitoringInRecordedItems";
        gui = "Preserve PDC delayed monitoring in recorded items";
        option = cfg.recordConfig.preservePdcDelayedMonitoringInRecordedItems;
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
        optionPath = "preferences.project.trackSendDefaults.sendsTrackHardwareOutputs.sendHardwareOutputMode";
        gui = "Send/hardware output default mode";
        option = cfg.sendsTrackHardwareOutputs.sendHardwareOutputMode;
        mask = 3;
        value = sendHardwareOutputModes.${cfg.sendsTrackHardwareOutputs.sendHardwareOutputMode};
      }
      {
        optionPath = "preferences.project.trackSendDefaults.sendsTrackHardwareOutputs.sendsSendMidiByDefault";
        gui = "Sends send MIDI by default";
        option = cfg.sendsTrackHardwareOutputs.sendsSendMidiByDefault;
        bit = 256;
        inverted = true;
      }
      {
        optionPath = "preferences.project.trackSendDefaults.sendsTrackHardwareOutputs.sendsSendAudioByDefault";
        gui = "Sends send audio by default";
        option = cfg.sendsTrackHardwareOutputs.sendsSendAudioByDefault;
        bit = 512;
        inverted = true;
      }
    ];
  };
}
