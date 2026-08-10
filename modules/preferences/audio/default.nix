{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types mkEnableOption;
  inherit (reaperLib) reaperBitfield reaperTypes reaperPreference reaperCodecs;

  cfg = config.programs.reaper.preferences.audio;
in {
  options.programs.reaper.preferences.audio = {
    closeAudioDeviceWhenStoppedAndApplicationIsInactive = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When enabled, REAPER will share audio devices with other applications by closing the audio hardware not active.";
    };
    closeAudioDeviceWhenInactiveAndTracksAreRecordArmed = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Wehn unchecked and any tracks are record armed, then REAPER will not share audio devices.";
    };
    closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When unchecked and any tracks are record armed, then REAPER will not share audio devices.";
    };
    closeAudioDeviceWhenStoppedAndActive = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When checked, REAPER will close the audio devices whenever not playing back audio (less responsive).";
    };

    warnWhenUnableToOpenAudioDevices = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Warn about audio devices that could not be opened.";
    };
    warnWhenUnableToOpenMidiDevices = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Warn about MIDI devices that could not be opened.";
    };
    warnWhenEnabledMidiDevicesAreNotPresent = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whan about MIDI devices that are enabled but could not be found.";
    };

    autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whan about MIDI devices that are enabled but could not be found.";
      };
      ms = mkOption {
        type = types.nullOr reaperTypes.number;
        default = null;
        example = 5.5;
        description = "When checked, plug-ins with more than this PDC amount by auto-bypassed when record-armed reducing monitoringlatency/improving performance.";
      };
    };
    onlyBypassWhileActuallyRecording = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "PDC auto-bypass only while recording, PDC FX will be active in stop/playback. This can result in glitches when punch-in recording.";
    };

    temporarilyBypassOversamplingOnRecordArmAffectedTrack = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Automatically disable oversampling on tracks that are record armed or receive from armed tracks. Oversampling changes only on playback start/stop";
    };
    autoBypassFxEvenWhenFxConfigurationOpen = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When auto-bypass is enabled in project settings or per-plug-in, this allows plug-ins to be auto-bypassed while the plug-in UI is open.";
    };
    stopProcessingAudioWhileWarningOfFailedDiskWrites = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "If checked, audio processing and output will be bypassed if a disk write error warning occurs (in order to draw attention to the issue).";
    };
    virtualLoopbackAudioHardwareChannel = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 4;
      description = "REAPER can support up to 128 virtual hardware loopback audio channels which can be used to route audio between projects.";
    };

    channelNamingMapping = {
      inputChannelNameAliasingRemapping = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Enables audio input name aliasing, letting you rename your inputs for easier selection.";
        };
      };
      outputChannelNameAliasingRemapping = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Enables audio input name aliasing, letting you rename your outputs for easier selection.";
        };
      };
      showNonStandardStereoChannelPairs = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "When checked, allows you to treat odd pairs of inputs/outputs as stereo pairs, i.e. not just Channels 1/2, but 2/3 as well.";
      };
      defaultMetronomeOutput = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 3;
        description = "Sets default output for metronome when project does not override -- default is project master outputs.";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion =
          cfg.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed
          != true
          || cfg.closeAudioDeviceWhenStoppedAndApplicationIsInactive == true;
        message = ''
          programs.reaper.preferences.audio.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed requires programs.reaper.preferences.audio.closeAudioDeviceWhenStoppedAndApplicationIsInactive to be true.
        '';
      }
    ];
    programs.reaper.ini.contributions =
      reaperPreference.contributions [
      ];
  };
}
