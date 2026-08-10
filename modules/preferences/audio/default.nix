{
  config,
  lib,
  pkgs,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperTypes reaperPreference;

  cfg = config.programs.reaper.preferences.audio;
  audioCloseInactiveKey =
    if pkgs.stdenv.hostPlatform.isLinux
    then "audiocloseinactive_linux"
    else "audiocloseinactive";
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
      description = "When unchecked and any tracks are record armed, REAPER will not share audio devices.";
    };
    closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When unchecked and ReWire devices are open, REAPER will not share audio devices.";
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
      description = "Warn about MIDI devices that are enabled but could not be found.";
    };

    autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds = {
      enable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Automatically bypass FX above the configured PDC threshold on record-arm-affected tracks.";
      };
      ms = mkOption {
        type = types.nullOr reaperTypes.number;
        default = null;
        example = 5.5;
        description = "PDC threshold in milliseconds above which plug-ins are auto-bypassed when record-armed, reducing monitoring latency and improving performance.";
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
      description = "Automatically disable oversampling on tracks that are record armed or receive from armed tracks. Oversampling changes only on playback start/stop.";
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
      type = types.nullOr (types.ints.between 0 128);
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
          description = "Enables audio output name aliasing, letting you rename your outputs for easier selection.";
        };
      };
      showNonStandardStereoChannelPairs = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "When checked, allows you to treat odd pairs of inputs/outputs as stereo pairs, i.e. not just Channels 1/2, but 2/3 as well.";
      };
      defaultMetronomeOutput = mkOption {
        type = types.nullOr types.ints.unsigned;
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
      {
        assertion =
          cfg.closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened
          != true
          || cfg.closeAudioDeviceWhenStoppedAndApplicationIsInactive == true;
        message = ''
          programs.reaper.preferences.audio.closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened requires programs.reaper.preferences.audio.closeAudioDeviceWhenStoppedAndApplicationIsInactive to be true.
        '';
      }
      {
        assertion =
          cfg.onlyBypassWhileActuallyRecording
          != true
          || cfg.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.enable == true;
        message = ''
          programs.reaper.preferences.audio.onlyBypassWhileActuallyRecording requires programs.reaper.preferences.audio.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.enable to be true.
        '';
      }
    ];
    programs.reaper.ini.contributions =
      reaperPreference.contributions [
        {
          path = "preferences.audio.closeAudioDeviceWhenStoppedAndActive";
          value = cfg.closeAudioDeviceWhenStoppedAndActive;
          section = "reaper";
          key = "audioclosestop";
          codec = "bool";
        }
        {
          path = "preferences.audio.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.ms";
          value = cfg.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.ms;
          section = "reaper";
          key = "pdcautobypassms";
          codec = "float";
        }
        {
          path = "preferences.audio.virtualLoopbackAudioHardwareChannel";
          value = cfg.virtualLoopbackAudioHardwareChannel;
          section = "reaper";
          key = "loopback_size";
          codec = "integer";
        }
        {
          path = "preferences.audio.channelNamingMapping.showNonStandardStereoChannelPairs";
          value = cfg.channelNamingMapping.showNonStandardStereoChannelPairs;
          section = "reaper";
          key = "allstereopairs";
          codec = "bool";
        }
        {
          path = "preferences.audio.channelNamingMapping.defaultMetronomeOutput";
          value = cfg.channelNamingMapping.defaultMetronomeOutput;
          section = "reaper";
          key = "metronome_defout";
          codec = "integer";
        }
      ]
      ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
        ${audioCloseInactiveKey} = [
          {
            optionPath = "preferences.audio.closeAudioDeviceWhenStoppedAndApplicationIsInactive";
            gui = "Close audio device when stopped and application is inactive";
            option = cfg.closeAudioDeviceWhenStoppedAndApplicationIsInactive;
            bit = 1;
          }
          {
            optionPath = "preferences.audio.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed";
            gui = "Close audio device when inactive and tracks are record armed";
            option = cfg.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed;
            bit = 2;
          }
          {
            optionPath = "preferences.audio.closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened";
            gui = "Close audio device when inactive and ReWire devices are open";
            option = cfg.closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened;
            bit = 4;
          }
        ];

        errnowarn = [
          {
            optionPath = "preferences.audio.warnWhenUnableToOpenAudioDevices";
            gui = "Warn when unable to open audio devices";
            option = cfg.warnWhenUnableToOpenAudioDevices;
            bit = 1;
            inverted = true;
          }
          {
            optionPath = "preferences.audio.warnWhenUnableToOpenMidiDevices";
            gui = "Warn when unable to open MIDI devices";
            option = cfg.warnWhenUnableToOpenMidiDevices;
            bit = 2;
            inverted = true;
          }
          {
            optionPath = "preferences.audio.warnWhenEnabledMidiDevicesAreNotPresent";
            gui = "Warn when enabled MIDI devices are not present";
            option = cfg.warnWhenEnabledMidiDevicesAreNotPresent;
            bit = 32;
            inverted = true;
          }
          {
            optionPath = "preferences.audio.stopProcessingAudioWhileWarningOfFailedDiskWrites";
            gui = "Stop processing audio while warning of failed disk writes/disk full";
            option = cfg.stopProcessingAudioWhileWarningOfFailedDiskWrites;
            bit = 4096;
          }
        ];

        optimizesilence = [
          {
            optionPath = "preferences.audio.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.enable";
            gui = "Auto-bypass FX on record arm-affected tracks whose PDC exceeds threshold";
            option = cfg.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.enable;
            bit = 32;
          }
          {
            optionPath = "preferences.audio.onlyBypassWhileActuallyRecording";
            gui = "Only bypass while actually recording";
            option = cfg.onlyBypassWhileActuallyRecording;
            bit = 64;
          }
          {
            optionPath = "preferences.audio.temporarilyBypassOversamplingOnRecordArmAffectedTrack";
            gui = "Temporarily bypass oversampling on record arm-affected tracks";
            option = cfg.temporarilyBypassOversamplingOnRecordArmAffectedTrack;
            bit = 16;
          }
          {
            optionPath = "preferences.audio.autoBypassFxEvenWhenFxConfigurationOpen";
            gui = "Auto-bypass FX even when FX configuration is open";
            option = cfg.autoBypassFxEvenWhenFxConfigurationOpen;
            bit = 4;
          }
        ];

        useinnc = [
          {
            optionPath = "preferences.audio.channelNamingMapping.inputChannelNameAliasingRemapping.enable";
            gui = "Input channel name aliasing/remapping";
            option = cfg.channelNamingMapping.inputChannelNameAliasingRemapping.enable;
            bit = 1;
          }
          {
            optionPath = "preferences.audio.channelNamingMapping.outputChannelNameAliasingRemapping.enable";
            gui = "Output channel name aliasing/remapping";
            option = cfg.channelNamingMapping.outputChannelNameAliasingRemapping.enable;
            bit = 2;
          }
        ];
      });
  };
}
