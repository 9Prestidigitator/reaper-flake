{
  lib,
  pkgs,
  runCommand,
}: let
  reaperLib = import ../modules/lib {inherit lib;};

  evaluated = lib.evalModules {
    specialArgs = reaperLib // {inherit pkgs reaperLib;};
    modules = [
      ../modules/ini.nix
      ../modules/windows.nix
      ../modules/preferences/general
      ../modules/preferences/project
      ../modules/preferences/audio
      ../modules/preferences/appearance
      ../modules/preferences/control-osc-web.nix
      {
        options.assertions = lib.mkOption {
          type = lib.types.listOf lib.types.unspecified;
          default = [];
        };
        options.warnings = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
        options.programs.reaper.configPath = lib.mkOption {
          type = lib.types.str;
          default = "/tmp/reaper-preference-schema-tests";
        };

        config.programs.reaper.preferences = {
          appearance = {
            tooltips = {
              uiElements = true;
              itemsEnvelopes = false;
              envsOnHover = false;
              peakAndLoudnessValueWhenMouseIsOverMediaItems = true;
              delay = 250;
            };
            fasterTextRendering = true;
            drawVerticalTextBottomUp = true;
            framelessFloatingToolbarWindows = true;
            dontScaleToolbarButtonsBelow1to1 = false;
            dontScaleToolbarButtonsAbove1to1 = false;
            dontAnimateArmedActionToolbarButtons = true;
            dontAnimateAnyToolbarButtons = false;
            verticalSpaceAtBottomOfTrackNumber = 7;
            visualTrackSpacerSize = 24;
            limitTcpSpacerHeightToLaneSize = true;
            antialiasedFadesAndEnvelopes = false;
            horizontalGridLinesInAutomationLanes = true;
            filledAutomationEnvelopes = true;
            filledEnvelopesWhenDrawnOverMedia = false;
            envelopePointSizeScaling = 1.5;
            scaleNonSelectedPoint = 0.5;
            hightlightEditCursorOverLastSelectedTrack = false;
            showGuideLinesWhenEditing = true;
            solidEdgeOnTimeSelectionHighlight = true;
            solidEdgeOnLoopSelection = false;
            displayVerticalLineAtMousePosition = {
              enable = true;
              snap = "ignoreSnapIfControlKeyHeld";
            };
            playCursorWidth = 4;
            hideDockerTabsWhenSingleWindowAndSmallerThanPixels = 300;
            zoomScrollOffset.verticalScrollStep.trackHeight = 0.25;
          };
          audio = {
            closeAudioDeviceWhenStoppedAndApplicationIsInactive = true;
            closeAudioDeviceWhenInactiveAndTracksAreRecordArmed = false;
            closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened = true;
            closeAudioDeviceWhenStoppedAndActive = true;
            warnWhenUnableToOpenAudioDevices = false;
            warnWhenUnableToOpenMidiDevices = true;
            warnWhenEnabledMidiDevicesAreNotPresent = false;
            autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds = {
              enable = true;
              ms = 5.5;
            };
            onlyBypassWhileActuallyRecording = false;
            temporarilyBypassOversamplingOnRecordArmAffectedTrack = true;
            autoBypassFxEvenWhenFxConfigurationOpen = true;
            stopProcessingAudioWhileWarningOfFailedDiskWrites = true;
            virtualLoopbackAudioHardwareChannel = 4;
            channelNamingMapping = {
              inputChannelNameAliasingRemapping.enable = true;
              outputChannelNameAliasingRemapping.enable = false;
              showNonStandardStereoChannelPairs = false;
              defaultMetronomeOutput = 3;
            };
          };
          controlOscWeb = {
            closeControlSurfaceDevicesWhenStoppedAndNotActiveApplication = false;
            closeControlSurfaceDevicesWhenRendering = true;
          };
          general = {
            startupSettings.skipAnimation = true;
            preventOsScreensaverWhenAudioActiveOrRendering = true;
            advancedUiSystemTweaks = {
              allowSnapGridRoutingWindowsToStayOpen = true;
              cpuAffinity.cpuIndexes = [0 2 4];
            };
            paths.doNotCopyOrMoveMediaFromTheFollowingPaths = ["/samples/a" "/samples/b"];
          };
          project = {
            defaultProjectTemplate = "/templates/default.RPP";
            itemFadeDefaults = {
              defaultFadeInFadeOutLength = 0.05;
              defaultCrossfadeLength = 0.08;
              defaultFadeInFadeOutShape = "exponential";
              defaultCrossfadeShape = "centerDip";
              importedMediaItems.fadeInFadeOut = true;
              recordedMediaItems = {
                fadeInFadeOut = false;
                overlap = "respectToolbarAutoCrossfadeButton";
              };
              splitMediaItems = {
                fadeInFadeOut = true;
                overlap = "overlapAndCrossfade";
                overlapCrossfadePosition = "center";
              };
              fixedLaneCompAreas = false;
              trimContentBehindMediaEditsEnabled = "noCrossfade";
              trimContentBehindRazorEditsEnabled = "respectToolbarAutoCrossfadeButton";
              limitSplitCreatedFadeCrossfadeTo = {
                enable = true;
                pixels = 75;
              };
              rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade = true;
              applyFadeInFadeOutCrossfadePreferencesToMidiItems = true;
              defaultStretchMarkerFadeSizeForNewItem = 3.75;
            };
            itemLoopDefaults = {
              loopSourceFor = {
                midiItems = true;
                importedItems = true;
                recordedItems = false;
                gluedItems = false;
              };
              timeSelectionAutoPunchAudioRecordingCreatesLoopableSelection = true;
            };
            backups = {
              whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak = {
                enable = true;
                limitAutoSavedBackupsToMostRecent.count = 7;
              };
              autoSave = {
                autoSaveInterval.mode = "anyTime";
                autoSaveToTimestampedFileInAdditionalDirectory.limitAutoSavedBackupsToMostRecent.count = 4;
                autoSaveToTimestampedFileInProjectDirectory.limitAutoSavedBackupsToMostRecent.count = 9;
              };
            };
          };
        };
      }
    ];
  };

  ini = evaluated.config.programs.reaper.ini;
  sections = ini.sections.reaper;
  bitfields = ini.bitfields.reaper;
in
  assert sections.splashanim == 0;
  assert sections.autoclosetrackwnds == 0;
  assert sections.cpuallowed == 21;
  assert sections.vscrollstep == 0.25;
  assert sections.nocopyfrompaths == ["/samples/a" "/samples/b"];
  assert sections.newprojtmpl == "/templates/default.RPP";
  assert sections.deffadelen == 0.05;
  assert sections.defsplitxfadelen == 0.08;
  assert sections.deffadeshape == 2;
  assert sections.defxfadeshape == 2;
  assert sections.splitmaxpix == 75;
  assert sections.stretchmarkerfade == 3.75;
  assert sections.savebackuplimit == 7;
  assert sections.autosavebackuplimit == 9;
  assert sections.autosavemode == 2;
  assert sections.tooltipdelay == 250;
  assert sections.trackitemgap == 7;
  assert sections.trackgapmax == 24;
  assert sections.env_pt_scale == 1.5;
  assert sections.env_pt_scale2 == 0.5;
  assert sections.playcursormode == 4;
  assert sections.dock_mini_tab_size == 300;
  assert sections.audioclosestop == 1;
  assert sections.pdcautobypassms == 5.5;
  assert sections.loopback_size == 4;
  assert sections.allstereopairs == 0;
  assert sections.metronome_defout == 3;
  assert bitfields.audiocloseinactive_linux
  == {
    mask = 159;
    value = 149;
  };
  assert bitfields.tooltips
  == {
    mask = 15;
    value = 13;
  };
  assert bitfields.textflags
  == {
    mask = 1;
    value = 1;
  };
  assert bitfields.nativedrawtext_linux
  == {
    mask = 1;
    value = 0;
  };
  assert bitfields.custommenu
  == {
    mask = 1812;
    value = 784;
  };
  assert bitfields.tcpalign
  == {
    mask = 8192;
    value = 0;
  };
  assert bitfields.envlanes
  == {
    mask = 120;
    value = 24;
  };
  assert bitfields.guidelines2
  == {
    mask = 252;
    value = 184;
  };
  assert bitfields.timeseledge
  == {
    mask = 3;
    value = 1;
  };
  assert bitfields.errnowarn
  == {
    mask = 4131;
    value = 4129;
  };
  assert bitfields.optimizesilence
  == {
    mask = 116;
    value = 52;
  };
  assert bitfields.useinnc
  == {
    mask = 3;
    value = 1;
  };
  assert bitfields.saveopts.mask == 17;
  assert bitfields.saveopts.value == 17;
  assert bitfields.loopnewitems
  == {
    mask = 62;
    value = 50;
  };
  assert bitfields.splitautoxfade
  == {
    mask = 524283;
    value = 387475;
  };
    runCommand "reaper-preference-schema-tests" {} ''
      touch "$out"
    ''
