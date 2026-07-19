{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
  cfg = config.programs.reaper.preferences.general;
  startupSettings = cfg.startupSettings;
  recentProjectList = cfg.recentProjectList;
  filenameAutoIncrement = cfg.filenameAutoIncrement;
  advancedUiSystemTweaks = cfg.advancedUiSystemTweaks;
  memoryThreshold = types.ints.unsigned;

  reaperBitfields = reaperBitfield.entries {
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
      type = types.nullOr memoryThreshold;
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
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.languagePack != null) {langpack = cfg.languagePack;}
    // optionalAttrs (startupSettings.openProjectOnStartup != null) {loadlastproj = startupSettings.openProjectOnStartup;}
    // optionalAttrs (startupSettings.showSplashScreenOnStartup != null) {splash = startupSettings.showSplashScreenOnStartup;}
    // optionalAttrs (startupSettings.skipAnimation != null) {
      splashanim =
        if startupSettings.skipAnimation
        then 0
        else 1;
    }
    // optionalAttrs (startupSettings.automaticallyCheckForNewVersions != null) {verchk = startupSettings.automaticallyCheckForNewVersions;}
    // optionalAttrs (recentProjectList.maximumProjects != null) {maxrecent = recentProjectList.maximumProjects;}
    // optionalAttrs (cfg.warnWhenMemoryUseReachesMegabytes != null) {warnmaxram64 = cfg.warnWhenMemoryUseReachesMegabytes;}
    // optionalAttrs (cfg.preventOsScreensaverWhenAudioActiveOrRendering != null) {
      audiocloseinactive_linux =
        if cfg.preventOsScreensaverWhenAudioActiveOrRendering
        then 128
        else 0;
    }
    // optionalAttrs (filenameAutoIncrement.suffix != null) {autoincrsuffix = filenameAutoIncrement.suffix;}
    // optionalAttrs (cfg.unloadProjectsInBackgroundWhenQuitting != null) {splash_options = cfg.unloadProjectsInBackgroundWhenQuitting;}
    // optionalAttrs (advancedUiSystemTweaks.customSplashScreenImage != null) {
      splashimage = advancedUiSystemTweaks.customSplashScreenImage;
    }
    // optionalAttrs (advancedUiSystemTweaks.uiScale != null) {uiscale = advancedUiSystemTweaks.uiScale;}
    // optionalAttrs (advancedUiSystemTweaks.fontSizeAdjustment != null) {
      fontscaling = advancedUiSystemTweaks.fontSizeAdjustment;
    }
    // optionalAttrs (advancedUiSystemTweaks.allowSnapGridRoutingWindowsToStayOpen != null) {
      autoclosetrackwnds =
        if advancedUiSystemTweaks.allowSnapGridRoutingWindowsToStayOpen
        then 0
        else 1;
    }
    // optionalAttrs (advancedUiSystemTweaks.allowKeyboardCommandsEvenWhenMouseEditing != null) {
      alwaysallowkb = advancedUiSystemTweaks.allowKeyboardCommandsEvenWhenMouseEditing;
    }
    // optionalAttrs (advancedUiSystemTweaks.modalWindowPositioning != null) {
      windowflags = advancedUiSystemTweaks.modalWindowPositioning;
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfields;
}
