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
              defaultFadeInFadeOutShape = "exponential";
              defaultCrossfadeShape = "centerDip";
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
  assert sections.deffadeshape == 2;
  assert sections.defxfadeshape == 2;
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
    runCommand "reaper-preference-schema-tests" {} ''
      touch "$out"
    ''
