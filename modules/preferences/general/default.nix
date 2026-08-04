{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption types;
  inherit (reaperLib) reaperBitfield reaperCodecs reaperPreference;

  cfg = config.programs.reaper.preferences.general;

  startupSettings = cfg.startupSettings;
  recentProjectList = cfg.recentProjectList;
  filenameAutoIncrement = cfg.filenameAutoIncrement;
  advancedUiSystemTweaks = cfg.advancedUiSystemTweaks;

  reaperBitfieldContributions = reaperBitfield.contributions {
    multinst = [
      {
        optionPath = "preferences.general.startupSettings.createNewProjectTabWhenOpeningMedia";
        gui = "Create new project tab when opening media from explorer/finder";
        option = startupSettings.createNewProjectTabWhenOpeningMedia;
        bit = 4;
        inverted = true;
      }
      {
        optionPath = "preferences.general.startupSettings.checkForMultipleInstancesWhenLaunching";
        gui = "Check for multiple instances when launching";
        option = startupSettings.checkForMultipleInstancesWhenLaunching;
        bit = 2;
        inverted = true;
      }
      {
        optionPath = "preferences.general.startupSettings.checkForMultipleInstancesWhenLaunchingWithProjectMedia";
        gui = "When launching with project/media";
        option = startupSettings.checkForMultipleInstancesWhenLaunchingWithProjectMedia;
        bit = 1;
        inverted = true;
      }
    ];

    renderclosewhendone = [
      {
        optionPath = "preferences.general.filenameAutoIncrement.ensureAutoIncrementedFilenamesHaveHigherNumberThanSimilarNamedFiles";
        gui = "Ensure auto-incremented filenames have a higher number than all similarly named files";
        option = filenameAutoIncrement.ensureAutoIncrementedFilenamesHaveHigherNumberThanSimilarNamedFiles;
        bit = 8388608;
      }
      {
        optionPath = "preferences.general.filenameAutoIncrement.treatUnderscoreAndDashAsInterchangeable";
        gui = "Treat _ and - as interchangeable when auto-incrementing";
        option = filenameAutoIncrement.treatUnderscoreAndDashAsInterchangeable;
        bit = 16777216;
        inverted = true;
      }
    ];

    actionmenu = [
      {
        optionPath = "preferences.general.recentProjectList.displayProjectTitle";
        gui = "Display project title (as set in Project Settings / Notes)";
        option = recentProjectList.displayProjectTitle;
        bit = 4;
      }
      {
        optionPath = "preferences.general.recentProjectList.display";
        gui = "Recent project list display";
        option = recentProjectList.display;
        mask = 11;
        importValues = reaperLib.reaperGeneral.recentProjectListDisplay;
      }
      {
        optionPath = "preferences.general.recentProjectList.addLoadedProjects";
        gui = "Add to recent list when loading projects";
        option = recentProjectList.addLoadedProjects;
        bit = 16;
        inverted = true;
      }
      {
        optionPath = "preferences.general.recentProjectList.removeOldProjectWhenSavingNewVersion";
        gui = "Remove old project from recent list when using 'Save new version of project'";
        option = recentProjectList.removeOldProjectWhenSavingNewVersion;
        bit = 32;
      }
      {
        optionPath = "preferences.general.recentProjectList.addSaveCopyProjects";
        gui = "Add to recent list when using 'Save copy of project'";
        option = recentProjectList.addSaveCopyProjects;
        bit = 64;
        inverted = true;
      }
    ];

    splash_options = [
      {
        optionPath = "preferences.general.unloadProjectsInBackgroundWhenQuitting";
        gui = "Unload projects in background when quitting";
        option = cfg.unloadProjectsInBackgroundWhenQuitting;
        bit = 2;
      }
    ];
  };
in {
  imports = [
    ./keyboard-multitouch.nix
    ./paths.nix
    ./undo.nix
  ];

  options.programs.reaper.preferences.general = {
    languagePack = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "";
      description = ''
        REAPER language pack setting. Use an empty string for REAPER's default language.
      '';
    };

    startupSettings = {
      openProjectOnStartup = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperGeneral.openProjectOnStartup));
        default = null;
        example = literalExpression "reaperGeneral.openProjectOnStartup.newProjectIgnoreDefaultTemplate";
        description = ''
          The project(s) to open on startup. Default null value is reaperGeneral.lastProjectTabs.
        '';
      };
      showSplashScreenOnStartup = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          Displays the splash screen and REAPER logo when the application starts.
        '';
      };
      skipAnimation = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          Skips the REAPER logo animation and potentially slightly reduces startup time.
        '';
      };
      automaticallyCheckForNewVersions = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether REAPER checks for new versions on startup.";
      };
      createNewProjectTabWhenOpeningMedia = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether media opened from the file browser creates a new project tab.";
      };
      checkForMultipleInstancesWhenLaunching = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER checks for multiple instances when launching.";
      };
      checkForMultipleInstancesWhenLaunchingWithProjectMedia = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether the multiple-instance check applies when launching with project or media files.";
      };
    };

    recentProjectList = {
      maximumProjects = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 50;
        description = "Maximum projects in REAPER's recent project list.";
      };
      displayProjectTitle = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether recent projects display the project title from Project Settings / Notes.";
      };
      display = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperGeneral.recentProjectListDisplay));
        default = null;
        example = literalExpression "reaperGeneral.recentProjectListDisplay.fullPath";
        description = ''
          File/path display mode for the recent project list. Named values are
          available from `reaperGeneral.recentProjectListDisplay`.
        '';
      };
      addLoadedProjects = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether loading projects adds them to the recent project list.";
      };
      addSaveCopyProjects = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether using Save copy of project adds that project to the recent project list.";
      };
      removeOldProjectWhenSavingNewVersion = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether using Save new version of project removes the old project from the recent project list.";
      };
    };

    warnWhenMemoryUseReachesMegabytes = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 1800;
      description = "Warn when REAPER's memory use reaches this many megabytes. Use 0 to never warn.";
    };

    preventOsScreensaverWhenAudioActiveOrRendering = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER prevents OS screensaver/screen blanking when audio is active or when rendering.";
    };

    filenameAutoIncrement = {
      suffix = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "-001";
        description = "Auto-increment filename suffix used by rendering/conversion filename collision handling.";
      };
      ensureAutoIncrementedFilenamesHaveHigherNumberThanSimilarNamedFiles = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether auto-incremented filenames must have a higher number than all similarly named files.";
      };
      treatUnderscoreAndDashAsInterchangeable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether `_` and `-` are treated as interchangeable when auto-incrementing filenames.";
      };
    };

    unloadProjectsInBackgroundWhenQuitting = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = false;
      description = "Whether projects are unloaded in the background when quitting REAPER.";
    };

    advancedUiSystemTweaks = {
      customSplashScreenImage = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/home/user/Pictures/reaper-splash.png";
        description = "Custom splash screen image path for REAPER startup.";
      };

      uiScale = mkOption {
        type = types.nullOr reaperLib.reaperTypes.general.uiScale;
        default = null;
        example = 1.25;
        description = ''
          Scale UI elements of track/mixer panels, transport, etc. The REAPER
          checkbox is enabled when this is set; leave null to omit `uiscale`,
          which REAPER reads as unchecked.
        '';
      };

      fontSizeAdjustment = mkOption {
        type = types.nullOr reaperLib.reaperTypes.number;
        default = null;
        example = 1.0;
        description = "Font size adjustment for theme, arrange view, and ruler text.";
      };

      allowSnapGridRoutingWindowsToStayOpen = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether snap/grid/routing windows are allowed to stay open.";
      };

      allowKeyboardCommandsEvenWhenMouseEditing = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether keyboard commands are allowed even when mouse-editing.";
      };

      modalWindowPositioning = mkOption {
        type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperGeneral.modalWindowPositioning));
        default = null;
        example = literalExpression "reaperGeneral.modalWindowPositioning.centerOnCurrentScreen";
        description = ''
          Modal window positioning behavior. Named values are available from
          `reaperGeneral.modalWindowPositioning`.
        '';
      };

      useLargeNonToolWindowFrames = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER uses large, non-tool window frames for windows.";
      };

      cpuAffinity = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether REAPER is restricted to the configured CPU indexes.";
        };

        cpuIndexes = mkOption {
          type = types.nullOr (types.listOf (types.ints.between 0 31));
          default = null;
          example = [0 2 4 6];
          description = "CPU indexes REAPER may use. REAPER supports indexes 0 through 31 in this setting.";
        };

        preventOsRelocatingWorkerThreads = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether REAPER prevents the OS from relocating worker threads between CPUs.";
        };
      };

      processWorkingSet = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether REAPER sets a process working-set size.";
        };

        minimum = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          example = 0;
          description = "Minimum process working-set size passed to REAPER.";
        };

        maximum = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          example = 0;
          description = "Maximum process working-set size passed to REAPER.";
        };
      };
    };
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.general.languagePack";
        value = cfg.languagePack;
        section = "reaper";
        key = "langpack";
        codec = "identity";
      }
      {
        path = "preferences.general.startupSettings.openProjectOnStartup";
        value = startupSettings.openProjectOnStartup;
        section = "reaper";
        key = "loadlastproj";
        codec = "integer";
      }
      {
        path = "preferences.general.startupSettings.showSplashScreenOnStartup";
        value = startupSettings.showSplashScreenOnStartup;
        section = "reaper";
        key = "splash";
        codec = "bool";
      }
      {
        path = "preferences.general.startupSettings.skipAnimation";
        value = startupSettings.skipAnimation;
        section = "reaper";
        key = "splashanim";
        codec = reaperCodecs.bool {
          trueValue = 0;
          falseValue = 1;
        };
      }
      {
        path = "preferences.general.startupSettings.automaticallyCheckForNewVersions";
        value = startupSettings.automaticallyCheckForNewVersions;
        section = "reaper";
        key = "verchk";
        codec = "bool";
      }
      {
        path = "preferences.general.recentProjectList.maximumProjects";
        value = recentProjectList.maximumProjects;
        section = "reaper";
        key = "maxrecent";
        codec = "integer";
      }
      {
        path = "preferences.general.warnWhenMemoryUseReachesMegabytes";
        value = cfg.warnWhenMemoryUseReachesMegabytes;
        section = "reaper";
        key = "warnmaxram64";
        codec = "integer";
      }
      {
        path = "preferences.general.filenameAutoIncrement.suffix";
        value = filenameAutoIncrement.suffix;
        section = "reaper";
        key = "autoincrsuffix";
        codec = "identity";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.customSplashScreenImage";
        value = advancedUiSystemTweaks.customSplashScreenImage;
        section = "reaper";
        key = "splashimage";
        codec = "identity";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.uiScale";
        value = advancedUiSystemTweaks.uiScale;
        section = "reaper";
        key = "uiscale";
        codec = "float";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.fontSizeAdjustment";
        value = advancedUiSystemTweaks.fontSizeAdjustment;
        section = "reaper";
        key = "fontscaling";
        codec = "float";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.allowSnapGridRoutingWindowsToStayOpen";
        value = advancedUiSystemTweaks.allowSnapGridRoutingWindowsToStayOpen;
        section = "reaper";
        key = "autoclosetrackwnds";
        codec = reaperCodecs.bool {
          trueValue = 0;
          falseValue = 1;
        };
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.allowKeyboardCommandsEvenWhenMouseEditing";
        value = advancedUiSystemTweaks.allowKeyboardCommandsEvenWhenMouseEditing;
        section = "reaper";
        key = "alwaysallowkb";
        codec = "bool";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.modalWindowPositioning";
        value = advancedUiSystemTweaks.modalWindowPositioning;
        section = "reaper";
        key = "windowflags";
        codec = "integer";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.useLargeNonToolWindowFrames";
        value = advancedUiSystemTweaks.useLargeNonToolWindowFrames;
        section = "reaper";
        key = "bigwndframes";
        codec = "bool";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.cpuAffinity.cpuIndexes";
        value = advancedUiSystemTweaks.cpuAffinity.cpuIndexes;
        section = "reaper";
        key = "cpuallowed";
        codec = reaperCodecs.cpuIndexes;
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.processWorkingSet.enable";
        value = advancedUiSystemTweaks.processWorkingSet.enable;
        section = "reaper";
        key = "workset_use";
        codec = "bool";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.processWorkingSet.minimum";
        value = advancedUiSystemTweaks.processWorkingSet.minimum;
        section = "reaper";
        key = "workset_min";
        codec = "integer";
      }
      {
        path = "preferences.general.advancedUiSystemTweaks.processWorkingSet.maximum";
        value = advancedUiSystemTweaks.processWorkingSet.maximum;
        section = "reaper";
        key = "workset_max";
        codec = "integer";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfieldContributions
      ++ reaperBitfield.contributions {
        audiocloseinactive_linux = [
          {
            optionPath = "preferences.general.preventOsScreensaverWhenAudioActiveOrRendering";
            gui = "Prevent OS screensaver when audio is active or rendering";
            option = cfg.preventOsScreensaverWhenAudioActiveOrRendering;
            bit = 128;
          }
        ];
        restrictcpu = [
          {
            optionPath = "preferences.general.advancedUiSystemTweaks.cpuAffinity.enable";
            gui = "Restrict REAPER to specific CPUs";
            option = advancedUiSystemTweaks.cpuAffinity.enable;
            bit = 1;
          }
          {
            optionPath = "preferences.general.advancedUiSystemTweaks.cpuAffinity.preventOsRelocatingWorkerThreads";
            gui = "Do not allow the OS to relocate worker threads to different CPUs";
            option = advancedUiSystemTweaks.cpuAffinity.preventOsRelocatingWorkerThreads;
            bit = 2;
          }
        ];
      });
}
