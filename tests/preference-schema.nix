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
          appearance.zoomScrollOffset.verticalScrollStep.trackHeight = 0.25;
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
  assert bitfields.audiocloseinactive_linux
  == {
    mask = 152;
    value = 144;
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
