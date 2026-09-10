{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperCodecs reaperPreference;
  cfg = config.programs.reaper.preferences.project.backups;

  whenSaving = cfg.whenSaving;
  autoSave = cfg.autoSave;

  backupLimit = types.ints.between 0 2147483647;
  positiveMinutes = types.ints.between 1 35791394;

  backupLimitUnits = {
    copies = 0;
    uniqueDays = 1;
  };

  autoSaveIntervalModes = {
    whenNotRecording = 0;
    whenStopped = 1;
    anyTime = 2;
  };
  additionalDirectoryLimitModes = {
    copiesForCurrentProject = 0;
    copiesForAllProjects = 2048;
    uniqueDaysForCurrentProject = 1024;
    uniqueDaysForAllProjects = 3072;
  };

  timestampedSaveBackups = whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak;
  autoSaveToProjectFile = autoSave.autoSaveToProjectFile;
  projectDirectoryAutoSave = autoSave.autoSaveToTimestampedFileInProjectDirectory;
  additionalDirectoryAutoSave = autoSave.autoSaveToTimestampedFileInAdditionalDirectory;
  autoSaveInterval = autoSave.autoSaveInterval;
  autoSaveUnsavedProjectsToTemporaryFile = autoSave.autoSaveUnsavedProjectsToTemporaryFile;
  configuredSaveBackupMode =
    whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak
    != null
    || whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak != null
    || timestampedSaveBackups.enable != null;

  enabledSaveBackupModes =
    builtins.length
    (builtins.filter (mode: mode) [
      (whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak == true)
      (whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak == true)
      (timestampedSaveBackups.enable == true)
    ]);

  reaperBitfieldContributions = reaperBitfield.contributions {
    saveopts = [
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak";
        gui = "Preserve previously-saved version of project as <project>.rpp-bak";
        configured = configuredSaveBackupMode;
        mask = 17;
        value =
          if timestampedSaveBackups.enable == true
          then 17
          else if whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak == true || whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak == true
          then 1
          else 0;
        importAssignments = {
          "0" = {
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak" = false;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.enable" = false;
          };
          "1" = {
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak" = true;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.enable" = false;
          };
          "16" = {
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak" = false;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.enable" = true;
          };
          "17" = {
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak" = false;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.enable" = true;
          };
        };
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToProjectFile";
        gui = "Auto-save to project file (not recommended)";
        option = autoSaveToProjectFile;
        bit = 2;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.enable";
        gui = "Auto-save to timestamped file in project directory";
        option = projectDirectoryAutoSave.enable;
        bit = 4;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.enable";
        gui = "Auto-save to timestamped file in additional directory";
        option = additionalDirectoryAutoSave.enable;
        bit = 8;
      }
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.limitBackupsToMostRecent.enable";
        gui = "Limit backups to most recent";
        option = timestampedSaveBackups.limitBackupsToMostRecent.enable;
        bit = 32;
      }
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.limitBackupsToMostRecent.unit";
        gui = "Timestamped save backup limit unit";
        option = timestampedSaveBackups.limitBackupsToMostRecent.unit;
        mask = 64;
        value =
          if timestampedSaveBackups.limitBackupsToMostRecent.unit == "uniqueDays"
          then 64
          else 0;
        importValues = {
          copies = 0;
          uniqueDays = 64;
        };
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.limitAutoSavedBackupsToMostRecent.enable";
        gui = "Limit auto-saved backups to most recent";
        option = projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.enable;
        bit = 128;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.limitAutoSavedBackupsToMostRecent.unit";
        gui = "Project-directory auto-save backup limit unit";
        option = projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.unit;
        mask = 256;
        value =
          if projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.unit == "uniqueDays"
          then 256
          else 0;
        importValues = {
          copies = 0;
          uniqueDays = 256;
        };
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.limitBackupsToMostRecent.enable";
        gui = "Limit backups to most recent";
        option = additionalDirectoryAutoSave.limitBackupsToMostRecent.enable;
        bit = 512;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.limitBackupsToMostRecent.mode";
        gui = "Additional-directory auto-save backup limit mode";
        option = additionalDirectoryAutoSave.limitBackupsToMostRecent.mode;
        mask = 3072;
        value = additionalDirectoryLimitModes.${additionalDirectoryAutoSave.limitBackupsToMostRecent.mode};
        importValues = additionalDirectoryLimitModes;
      }
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.saveTimestampedBackupsToBackupsProjectSubdirectory";
        gui = "Save timestamped backups to Backups project subdirectory";
        option = timestampedSaveBackups.saveTimestampedBackupsToBackupsProjectSubdirectory;
        bit = 4096;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.saveAutoSavedProjectBackupsToAutoSavesProjectSubdirectory";
        gui = "Save auto-saved project backups to AutoSaves project subdirectory";
        option = projectDirectoryAutoSave.saveAutoSavedProjectBackupsToAutoSavesProjectSubdirectory;
        bit = 8192;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveUnsavedProjectsToTemporaryFile";
        gui = "Auto-save unsaved projects to temporary file";
        option = autoSaveUnsavedProjectsToTemporaryFile;
        bit = 16384;
      }
    ];

    saveundostatesproj = [
      {
        optionPath = "preferences.project.backups.whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak";
        gui = "Preserve all previously-saved versions of project in one (large) <project>.rpp-bak";
        option = whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak;
        bit = 512;
        importAssignments = {
          "0" = {
            "preferences.project.backups.whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak" = false;
          };
          "512" = {
            "preferences.project.backups.whenSaving.preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak" = true;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsProjectRppBak" = false;
          };
        };
      }
    ];
  };
in {
  # Keep existing declarations working while the public names follow the GUI.
  imports = [
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviousVersionAsRppBak"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionOfProjectAsProjectRppBak"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preserveAllPreviousVersionsInOneRppBak"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionOfProjectAsRppBak" "enable"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak" "enable"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionOfProjectAsRppBak" "saveTimestampedBackupsToProjectBackupsSubdirectory"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak" "saveTimestampedBackupsToBackupsProjectSubdirectory"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionOfProjectAsRppBak" "limitAutoSavedBackupsToMostRecent" "enable"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak" "limitBackupsToMostRecent" "enable"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionOfProjectAsRppBak" "limitAutoSavedBackupsToMostRecent" "count"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak" "limitBackupsToMostRecent" "count"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionOfProjectAsRppBak" "limitAutoSavedBackupsToMostRecent" "unit"]
      ["programs" "reaper" "preferences" "project" "backups" "whenSaving" "preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak" "limitBackupsToMostRecent" "unit"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInAdditionalDirectory" "limitAutoSavedBackupsToMostRecent" "enable"]
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInAdditionalDirectory" "limitBackupsToMostRecent" "enable"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInAdditionalDirectory" "limitAutoSavedBackupsToMostRecent" "count"]
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInAdditionalDirectory" "limitBackupsToMostRecent" "count"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInAdditionalDirectory" "limitAutoSavedBackupsToMostRecent" "mode"]
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInAdditionalDirectory" "limitBackupsToMostRecent" "mode"])
    (lib.mkRenamedOptionModule
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInProjectDirectory" "saveBackupsToProjectAutoSavesSubdirectory"]
      ["programs" "reaper" "preferences" "project" "backups" "autoSave" "autoSaveToTimestampedFileInProjectDirectory" "saveAutoSavedProjectBackupsToAutoSavesProjectSubdirectory"])
  ];

  options.programs.reaper.preferences.project.backups = {
    whenSaving = {
      preservePreviouslySavedVersionOfProjectAsProjectRppBak = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER preserves the previous project version as `<project>.rpp-bak` when saving.";
      };
      preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether REAPER preserves all previous saved project versions in one large `<project>.rpp-bak` file.";
      };
      preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether REAPER preserves previously saved project versions as timestamped `.rpp-bak` files.";
        };
        saveTimestampedBackupsToBackupsProjectSubdirectory = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether timestamped save backups are written to the project's `Backups` subdirectory.";
        };
        limitBackupsToMostRecent = {
          enable = mkOption {
            type = types.nullOr types.bool;
            default = null;
            example = true;
            description = "Whether timestamped save backups are limited to the most recent count.";
          };
          count = mkOption {
            type = types.nullOr backupLimit;
            default = null;
            example = 50;
            description = "Most recent save-backup copies or unique days to keep.";
          };
          unit = mkOption {
            type = types.nullOr (types.enum (builtins.attrNames backupLimitUnits));
            default = null;
            example = "copies";
            description = "Unit for the timestamped save-backup limit.";
          };
        };
      };
    };

    autoSave = {
      autoSaveToTimestampedFileInProjectDirectory = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = ''
            This option enables automatic saving of your project to an extra timestamped file.
          '';
        };
        saveAutoSavedProjectBackupsToAutoSavesProjectSubdirectory = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = ''
            Controls whether timestamped auto-saved files are saved alongside the project or in the AutoSaves directory.
          '';
        };
        limitAutoSavedBackupsToMostRecent = {
          enable = mkOption {
            type = types.nullOr types.bool;
            default = null;
            example = true;
            description = ''
              Limit timestamped auto-save backup files to a maximum number of copies or unique days for a given project.
            '';
          };
          count = mkOption {
            type = types.nullOr backupLimit;
            default = null;
            example = 50;
            description = ''
              Limit timestamped auto-save backup files to a maximum number of copies or unique days for a given project.
            '';
          };
          unit = mkOption {
            type = types.nullOr (types.enum (builtins.attrNames backupLimitUnits));
            default = null;
            example = "copies";
            description = ''
              Limit timestamped auto-save backup files to a maximum number of copies or unique days for a given project.
            '';
          };
        };
      };
      autoSaveToTimestampedFileInAdditionalDirectory = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = ''
            Auto-save to timestamped file in additional directory.
          '';
        };
        path = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/tmp/reaper-projects";
          description = ''
            REAPER can automatically save timestamped project files to this folder.
          '';
        };
        limitBackupsToMostRecent = {
          enable = mkOption {
            type = types.nullOr types.bool;
            default = null;
            example = true;
            description = "Whether additional-directory auto-saved backups are limited to the most recent count.";
          };
          count = mkOption {
            type = types.nullOr backupLimit;
            default = null;
            example = 50;
            description = ''
              Limit timestamped backup files in an alternate path to a maximum
              number of copies or unique days, for either a given project or
              for all backups.
            '';
          };
          mode = mkOption {
            type = types.nullOr (types.enum (builtins.attrNames additionalDirectoryLimitModes));
            default = null;
            example = "copiesForCurrentProject";
            description = "Scope and unit for the additional-directory auto-save backup limit.";
          };
        };
      };
      autoSaveToProjectFile = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether REAPER auto-saves directly to the project file.";
      };
      autoSaveUnsavedProjectsToTemporaryFile = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = ''
          If enabled, unsaved projects will be saved automatically to
          temporary files to be possibly re-loaded on relaunch (if configured
          to load last project).
        '';
      };
      autoSaveInterval = {
        minutes = mkOption {
          type = types.nullOr positiveMinutes;
          default = null;
          example = 15;
          description = "Auto-save interval in minutes.";
        };
        mode = mkOption {
          type = types.nullOr (types.enum (builtins.attrNames autoSaveIntervalModes));
          default = null;
          example = "whenNotRecording";
          description = "When REAPER may auto-save.";
        };
      };
      autoSavePathForUnsavedProjects = {
        path = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/tmp/reaper-unsaved";
          description = "Auto-save path for unsaved projects.";
        };
      };
    };
  };

  config.assertions = [
    {
      assertion = enabledSaveBackupModes <= 1;
      message = ''
        programs.reaper.preferences.project.backups.whenSaving preservePreviouslySavedVersionOfProjectAsProjectRppBak,
        preserveAllPreviouslySavedVersionsOfProjectInOneLargeProjectRppBak, and preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.enable
        are mutually exclusive.
      '';
    }
  ];

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionsOfProjectAsProjectTimestampRppBak.limitBackupsToMostRecent.count";
        value = timestampedSaveBackups.limitBackupsToMostRecent.count;
        section = "reaper";
        key = "savebackuplimit";
        codec = "integer";
      }
      {
        path = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.limitBackupsToMostRecent.count";
        value = additionalDirectoryAutoSave.limitBackupsToMostRecent.count;
        section = "reaper";
        key = "autosavebackuplimit2";
        codec = "integer";
      }
      {
        path = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.limitAutoSavedBackupsToMostRecent.count";
        value = projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.count;
        section = "reaper";
        key = "autosavebackuplimit";
        codec = "integer";
      }
      {
        path = "preferences.project.backups.autoSave.autoSaveInterval.minutes";
        value = autoSaveInterval.minutes;
        section = "reaper";
        key = "autosaveint";
        codec = "integer";
      }
      {
        path = "preferences.project.backups.autoSave.autoSaveInterval.mode";
        value = autoSaveInterval.mode;
        section = "reaper";
        key = "autosavemode";
        codec = reaperCodecs.enum autoSaveIntervalModes;
      }
      {
        path = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.path";
        value = additionalDirectoryAutoSave.path;
        section = "reaper";
        key = "autosavedir";
      }
      {
        path = "preferences.project.backups.autoSave.autoSavePathForUnsavedProjects.path";
        value = autoSave.autoSavePathForUnsavedProjects.path;
        section = "reaper";
        key = "autosavedir_unsaved";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) reaperBitfieldContributions;
}
