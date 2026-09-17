{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield reaperCodecs reaperPreference;

  cfg = config.programs.reaper.windows;
  transport = cfg.transport;
  transportTypes = reaperLib.reaperWindows.transportControls;

  # Going to make this a universal reaper library option to save space
  reaBool = description:
    mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      inherit description;
    };

  reaEnum = {
    enum,
    description ? null,
    example ? null,
    default ? null,
  }:
    mkOption {
      type = types.nullOr (types.enum (builtins.attrValues enum));
      example = literalExpression "${example}";
      inherit description default;
    };

  mixer = cfg.mixer;
  tcpHelpBar = cfg.tcpHelpBar;
  performanceMeter = cfg.performanceMeter;

  # TODO(max): This option set is scoped terribly. Will likely move these
  # options somewhere else that makes more sense.

  reaperBitfieldContributions = reaperBitfield.contributions {
    transflags = [
      {
        optionPath = "windows.transport.showPlayrateControl";
        gui = "Show playrate control";
        option = transport.showPlayrateControl;
        bit = 1;
        inverted = true;
      }
      {
        optionPath = "windows.transport.showPlayStateAsText";
        gui = "Show play state as text";
        option = transport.showPlayStateAsText;
        bit = 2;
        inverted = true;
      }
      {
        optionPath = "windows.transport.showTimeSignature";
        gui = "Show time signature";
        option = transport.showTimeSignature;
        bit = 4;
        inverted = true;
      }
      {
        optionPath = "windows.transport.centerTransportControls";
        gui = "Center transport controls";
        option = transport.centerTransportControls;
        bit = 8;
      }
      {
        optionPath = "windows.transport.flashOnPossibleAudioDeviceUnderrun";
        gui = "Flash transport yellow on possible audio device underrun";
        option = transport.flashOnPossibleAudioDeviceUnderrun;
        bit = 128;
      }
    ];

    viewadvance = [
      {
        optionPath = "windows.transport.automaticallyScrollViewDuringPlayback";
        gui = "Automatically scroll view during playback";
        option = transport.automaticallyScrollViewDuringPlayback;
        bit = 1;
      }
      {
        optionPath = "windows.transport.continuousScrolling";
        gui = "Continuous scrolling";
        option = transport.continuousScrolling;
        bit = 16;
      }
    ];

    smoothseek = [
      {
        optionPath = "windows.transport.smoothSeeking";
        gui = "Smooth seeking (seeks at end of measure)";
        option = transport.smoothSeeking;
        bit = 1;
      }
    ];

    rbn = [
      {
        optionPath = "windows.transport.chaseMidiNoteOnCcPitch";
        gui = "Chase MIDI note-on/CC/PC/pitch in project playback";
        option = transport.chaseMidiNoteOnCcPitch;
        bit = 128;
        inverted = true;
      }
    ];

    help = [
      {
        optionPath = "windows.tcpHelpBar.informationDisplay";
        gui = "TCP help bar information display";
        option = tcpHelpBar.informationDisplay;
        mask = 7;
        importValues = reaperLib.reaperWindows.tcpHelpBar.informationDisplay;
      }
      {
        optionPath = "windows.tcpHelpBar.showMouseEditingHelp";
        gui = "Show mouse editing help";
        option = tcpHelpBar.showMouseEditingHelp;
        bit = 65536;
        inverted = true;
      }
      {
        optionPath = "windows.performanceMeter.cpuUtilizationDisplay";
        gui = "Performance meter CPU utilization display";
        option = performanceMeter.cpuUtilizationDisplay;
        mask = 393216;
        importValues = reaperLib.reaperWindows.performanceMeter.cpuUtilizationDisplay;
      }
    ];

    mixerflag = [
      {
        optionPath = "windows.mixer.master.showInDockerOrWindow";
        gui = "Master Track > Show in separate window/Show in docker";
        option = mixer.master.showInDockerOrWindow;
        bit = 16;
      }
      {
        optionPath = "windows.mixer.showIconForLastTrackInFolder";
        gui = "Show icon for last track in folder";
        option = mixer.showIconForLastTrackInFolder;
        bit = 1;
        inverted = true;
      }
      {
        optionPath = "windows.mixer.clickableIconForFolderTracksToShowHideChildren";
        gui = "Clickable icon for folder tracks to show/hide children";
        option = mixer.clickableIconForFolderTracksToShowHideChildren;
        bit = 2;
      }
      {
        optionPath = "windows.mixer.allowEmptySlotsInFxLists";
        gui = "Allow empty slots in FX lists";
        option = mixer.allowEmptySlotsInFxLists;
        bit = 64;
      }
      {
        optionPath = "windows.mixer.allowReoarderingEmptySlotsInTcpMcpSendLists";
        gui = "Allow empty slots in FX lists";
        option = mixer.allowReoarderingEmptySlotsInTcpMcpSendLists;
        bit = 128;
        inverted = true;
      }
    ];

    mixeruiflag = [
      {
        optionPath = "windows.mixer.showNormalTopLevelTracks";
        gui = "Show normal top level tracks";
        option = mixer.showNormalTopLevelTracks;
        bit = 1;
      }
      {
        optionPath = "windows.mixer.showFolders";
        gui = "Show folders";
        option = mixer.showFolders;
        bit = 2;
      }
      {
        optionPath = "windows.mixer.groupFoldersToLeft";
        gui = "Group folders to left";
        option = mixer.groupFoldersToLeft;
        bit = 4;
      }
      {
        optionPath = "windows.mixer.showTracksThatHaveReceives";
        gui = "Show tracks that have receives";
        option = mixer.showTracksThatHaveReceives;
        bit = 8;
      }
      {
        optionPath = "windows.mixer.groupTracksThatHaveReceivesToLeft";
        gui = "Group tracks that have receives to left";
        option = mixer.groupTracksThatHaveReceivesToLeft;
        bit = 16;
      }
      {
        optionPath = "windows.mixer.showTracksThatAreInFolders";
        gui = "Show tracks that are in folders";
        option = mixer.showTracksThatAreInFolders;
        bit = 32;
        inverted = true;
      }
      {
        optionPath = "windows.mixer.autoArrangeTracks";
        gui = "Auto-arrange tracks in Mixer";
        option = mixer.autoArrangeTracks;
        bit = 64;
        inverted = true;
      }
    ];

    # This isn't really responding directly in reaper. But according to this (https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html#mixrowflags) it's valid.
    mixrowflags = [
      {
        optionPath = "windows.mixer.showMultipleRowsWhenSizePermits";
        gui = "Show multiple rows of tracks (when size permits)";
        option = mixer.showMultipleRowsWhenSizePermits;
        bit = 1;
        inverted = true;
      }
      {
        optionPath = "windows.mixer.showMaximumRowsEvenWhenTracksWouldFitInFewerRows";
        gui = "Show maximum rows even when tracks would fit in fewer rows";
        option = mixer.showMaximumRowsEvenWhenTracksWouldFitInFewerRows;
        bit = 2;
      }
      {
        optionPath = "windows.mixer.master.showOnRightSide";
        gui = "Show master track on right side of mixer window.";
        option = mixer.master.showOnRightSide;
        bit = 4;
      }
      {
        optionPath = "windows.mixer.showFxInserts";
        gui = "Show FX inserts (when size permits)";
        option = mixer.showFxInserts;
        bit = 16;
      }
      {
        optionPath = "windows.mixer.showSends";
        gui = "Show sends (when size permits)";
        option = mixer.showSends;
        bit = 32;
      }
      {
        optionPath = "windows.mixer.showTrackIconsInMixer";
        gui = "Show track icons in mixer";
        option = mixer.showTrackIconsInMixer;
        bit = 64;
      }
      {
        optionPath = "windows.mixer.showFxParameters";
        gui = "Show FX parameters (when size permits)";
        option = mixer.showFxParameters;
        bit = 128;
      }
      {
        optionPath = "windows.mixer.master.showInMixer";
        gui = "Show master track in mixer";
        option = mixer.master.showInMixer;
        bit = 256;
        inverted = true;
      }
    ];
  };
in {
  options.programs.reaper.windows = {
    transport = {
      automaticallyScrollViewDuringPlayback = reaBool "Automatically scroll view during playback.";
      continuousScrolling = reaBool "Continuous scrolling.";
      smoothSeeking = reaBool "Smooth seeking (seeks at end of measure).";
      chaseMidiNoteOnCcPitch = reaBool "Chase MIDI note-on/CC/PC/pitch in project playback.";
      stopPlaybackAtEndOfLoopIfRepeatDisabled = reaBool "Stop playback at the end of the loop when repeat is disabled.";
      flashOnPossibleAudioDeviceUnderrun = reaBool "Flash transport yellow on possible audio device underrun.";

      recordMode = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames transportTypes.recordMode));
        default = null;
        example = "normal";
        description = "Default record mode for new projects. Existing projects retain their saved record mode.";
      };
      # recordMode = reaEnum {
      #   enum = transportTypes.recordMode;
      #   description = "Default record mode for new projects. Existing projects retain their saved record mode.";
      #   example = reaperLib.reaperWindows.recordMode.normal;
      # };

      showPlayrateControl = reaBool "Show playrate control.";
      showTimeSignature = reaBool "Show time signature.";
      showPlayStateAsText = reaBool "Show play state as text.";
      centerTransportControls = reaBool "Center transport controls.";

      timeDisplay = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            primary = mkOption {
              type = types.enum (["ruler"] ++ builtins.attrNames transportTypes.timeUnits);
              default = "ruler";
              description = "Default transport time unit for new projects, or ruler to follow the project's ruler.";
            };
            secondary = mkOption {
              type = types.enum (["none"] ++ builtins.attrNames transportTypes.timeUnits);
              default = "none";
              description = "Secondary transport time unit. Must be none when the primary unit follows the ruler.";
            };
          };
        });
        default = null;
        example = {
          primary = "measuresBeats";
          secondary = "minutesSeconds";
        };
        description = "Default transport time display for new projects. Existing projects retain their saved time display. Both units share one INI value and are managed together.";
      };
    };

    tcpHelpBar = {
      informationDisplay = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperWindows.tcpHelpBar.informationDisplay));
        default = null;
        example = literalExpression "reaperWindows.tcpHelpBar.informationDisplay.cpuRamUseTimeSinceLastSave";
        description = ''
          Information shown in the help bar below the track control panels.
          Named values are available from
          `reaperWindows.tcpHelpBar.informationDisplay`.
        '';
      };

      showMouseEditingHelp = reaBool "Whether mouse editing help is shown in the help bar below the track control panels.";
    };

    performanceMeter = {
      cpuUtilizationDisplay = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperWindows.performanceMeter.cpuUtilizationDisplay));
        default = null;
        example = literalExpression "reaperWindows.performanceMeter.cpuUtilizationDisplay.allCoresFullyUtilized";
        description = ''
          CPU utilization display mode in the performance meter context menu.
          Named values are available from
          `reaperWindows.performanceMeter.cpuUtilizationDisplay`.
        '';
      };
    };

    mixer = {
      showFolders = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether folder tracks are shown in the mixer.";
      };

      showNormalTopLevelTracks = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether normal top-level tracks are shown in the mixer.";
      };

      showTracksThatAreInFolders = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether tracks inside folders are shown in the mixer.";
      };

      showTracksThatHaveReceives = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether tracks that have receives are shown in the mixer.";
      };

      scrollViewWhenTracksActivated = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether the mixer scrolls its view when tracks are activated. Default null value is true.";
      };

      autoArrangeTracks = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether tracks are auto-arranged in the mixer. Default null value is true.";
      };

      groupFoldersToLeft = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether folder tracks are grouped to the left in the mixer. Default null value is false.";
      };

      groupTracksThatHaveReceivesToLeft = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether tracks that have receives are grouped to the left in the mixer. Default null value is false.";
      };

      clickableIconForFolderTracksToShowHideChildren = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether folder track icons are clickable to show or hide children. Default null value is false.";
      };

      showMultipleRowsWhenSizePermits = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether the mixer shows multiple rows of tracks when size permits. Default null value is false.";
      };

      showMaximumRowsEvenWhenTracksWouldFitInFewerRows = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether the mixer shows maximum rows even when tracks would fit in fewer rows. Default null value is false. Requires showMultipleRowsWhenSizePermits to be true.";
      };

      showFxInserts = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether FX inserts are shown in the mixer when size permits. Default null value is true.";
      };

      showFxParameters = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether FX parameters are shown in the mixer when size permits. Default null value is false.";
      };

      groupFxParametersWithInserts = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether FX parameters are grouped with FX inserts in the mixer. Default null value is false.";
      };

      showSends = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether sends are shown in the mixer when size permits. Default null value is true.";
      };

      groupSendsWithFxInserts = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether sends are grouped with FX inserts in the mixer. Default null value is false.";
      };

      allowEmptySlotsInFxLists = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether empty slots are allowed in mixer FX lists. Default null value is false.";
      };

      allowReoarderingEmptySlotsInTcpMcpSendLists = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Allow for reoarding of empty slots in the tcp/mcp send lists. Default null value is true.";
      };

      showTrackIconsInMixer = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether track icons are shown in the mixer. Default null value is false.";
      };

      showIconForLastTrackInFolder = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether the icon for the last track in a folder is shown. Default null value is true.";
      };

      master = {
        showInMixer = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether the master track is shown in the mixer.";
        };

        # TODO(max): Test this specifically
        showOnRightSide = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          visible = false;
          description = lib.mdDoc ''
            This option doesn't seem to work at all, even in standard reaper it
            does not retain whether this was enabled or not..
          '';
        };

        showInDockerOrWindow = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = ''
            Whether to show reaper master track in the mixer
            window/dock or to have it be in it's own dock or window.
          '';
        };
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = transport.timeDisplay == null || transport.timeDisplay.primary != "ruler" || transport.timeDisplay.secondary == "none";
        message = "REAPER transport timeDisplay.secondary must be none when primary is ruler.";
      }
      {
        assertion = cfg.mixer.showMaximumRowsEvenWhenTracksWouldFitInFewerRows != true || cfg.mixer.showMultipleRowsWhenSizePermits == true;
        message = ''
          REAPER mixer context menu option, "Show maximum rows even when tracks
          would fit in fewer rows", requires "Show Multiple rows of tracks (when
          size permits)" to be true to be true.
        '';
      }
    ];

    programs.reaper.ini.sections.reaper =
      optionalAttrs (mixer.scrollViewWhenTracksActivated != null) {showctinmix = mixer.scrollViewWhenTracksActivated;};

    programs.reaper.ini.contributions =
      map (entry: entry // {section = "reaper";}) reaperBitfieldContributions
      ++ reaperPreference.contributions [
        {
          path = "windows.transport.stopPlaybackAtEndOfLoopIfRepeatDisabled";
          gui = "Stop playback at end of loop if repeat is disabled";
          value = transport.stopPlaybackAtEndOfLoopIfRepeatDisabled;
          section = "reaper";
          key = "stopendofloop";
          codec = "bool";
        }
        {
          path = "windows.transport.recordMode";
          gui = "Record mode";
          value = transport.recordMode;
          section = "reaper";
          key = "projrecmode";
          codec = reaperCodecs.enum transportTypes.recordMode;
        }
        {
          path = "windows.transport.timeDisplay";
          gui = "Transport time unit / Secondary time unit";
          value = transport.timeDisplay;
          section = "reaper";
          key = "projtimemode2";
          codec = transportTypes.timeDisplayCodec;
        }
      ];
  };
}
