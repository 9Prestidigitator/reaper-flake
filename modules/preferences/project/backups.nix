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

  timestampedSaveBackups = whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak;
  autoSaveToProjectFile = autoSave.autoSaveToProjectFile;
  projectDirectoryAutoSave = autoSave.autoSaveToTimestampedFileInProjectDirectory;
  additionalDirectoryAutoSave = autoSave.autoSaveToTimestampedFileInAdditionalDirectory;
  autoSaveInterval = autoSave.autoSaveInterval;
  autoSaveUnsavedProjectsToTemporaryFile = autoSave.autoSaveUnsavedProjectsToTemporaryFile;
  configuredSaveBackupMode =
    whenSaving.preservePreviousVersionAsRppBak
    != null
    || whenSaving.preserveAllPreviousVersionsInOneRppBak != null
    || timestampedSaveBackups.enable != null;

  enabledSaveBackupModes =
    builtins.length
    (builtins.filter (mode: mode) [
      (whenSaving.preservePreviousVersionAsRppBak == true)
      (whenSaving.preserveAllPreviousVersionsInOneRppBak == true)
      (timestampedSaveBackups.enable == true)
    ]);

  reaperBitfieldContributions = reaperBitfield.contributions {
    saveopts = [
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak";
        gui = "Preserve previous project versions when saving";
        configured = configuredSaveBackupMode;
        mask = 17;
        value =
          if timestampedSaveBackups.enable == true
          then 17
          else if whenSaving.preservePreviousVersionAsRppBak == true || whenSaving.preserveAllPreviousVersionsInOneRppBak == true
          then 1
          else 0;
        importAssignments = {
          "0" = {
            "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak" = false;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.enable" = false;
          };
          "1" = {
            "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak" = true;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.enable" = false;
          };
          "16" = {
            "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak" = false;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.enable" = true;
          };
          "17" = {
            "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak" = false;
            "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.enable" = true;
          };
        };
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToProjectFile";
        gui = "Auto-save to project file";
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
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.limitAutoSavedBackupsToMostRecent.enable";
        gui = "Limit timestamped save backups";
        option = timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.enable;
        bit = 32;
      }
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.limitAutoSavedBackupsToMostRecent.unit";
        gui = "Timestamped save backup limit unit";
        option = timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.unit;
        mask = 64;
        value =
          if timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.unit == "uniqueDays"
          then 64
          else 0;
        importValues = {
          copies = 0;
          uniqueDays = 64;
        };
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.limitAutoSavedBackupsToMostRecent.enable";
        gui = "Limit project-directory auto-save backups";
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
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.limitAutoSavedBackupsToMostRecent.enable";
        gui = "Limit additional-directory auto-save backups";
        option = additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.enable;
        bit = 512;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.limitAutoSavedBackupsToMostRecent.mode";
        gui = "Additional-directory auto-save backup limit mode";
        option = additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.mode;
        mask = 3072;
        value = additionalDirectoryLimitModes.${additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.mode};
        importValues = additionalDirectoryLimitModes;
      }
      {
        optionPath = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.saveTimestampedBackupsToProjectBackupsSubdirectory";
        gui = "Save timestamped backups to project Backups subdirectory";
        option = timestampedSaveBackups.saveTimestampedBackupsToProjectBackupsSubdirectory;
        bit = 4096;
      }
      {
        optionPath = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInProjectDirectory.saveBackupsToProjectAutoSavesSubdirectory";
        gui = "Save project-directory auto-save backups to AutoSaves subdirectory";
        option = projectDirectoryAutoSave.saveBackupsToProjectAutoSavesSubdirectory;
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
        optionPath = "preferences.project.backups.whenSaving.preserveAllPreviousVersionsInOneRppBak";
        gui = "Preserve all previous versions in one RPP-BAK";
        option = whenSaving.preserveAllPreviousVersionsInOneRppBak;
        bit = 512;
        importAssignments = {
          "0" = {
            "preferences.project.backups.whenSaving.preserveAllPreviousVersionsInOneRppBak" = false;
          };
          "512" = {
            "preferences.project.backups.whenSaving.preserveAllPreviousVersionsInOneRppBak" = true;
            "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak" = false;
          };
        };
      }
    ];
  };
in {
  options.programs.reaper.preferences.project.backups = {
    whenSaving = {
      preservePreviousVersionAsRppBak = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER preserves the previous project version as `<project>.rpp-bak` when saving.";
      };
      preserveAllPreviousVersionsInOneRppBak = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = "Whether REAPER preserves all previous saved project versions in one large `<project>.rpp-bak` file.";
      };
      preservePreviouslySavedVersionOfProjectAsRppBak = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether REAPER preserves previously saved project versions as timestamped `.rpp-bak` files.";
        };
        saveTimestampedBackupsToProjectBackupsSubdirectory = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether timestamped save backups are written to the project's `Backups` subdirectory.";
        };
        limitAutoSavedBackupsToMostRecent = {
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
        saveBackupsToProjectAutoSavesSubdirectory = mkOption {
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
              Limit timestamped auto-save backup files to a maximum number of copes or unique days for a given project.
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
            Whether additional-directory auto-saved backups are limited to the most recent count.
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
        limitAutoSavedBackupsToMostRecent = {
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
        programs.reaper.preferences.project.backups.whenSaving preservePreviousVersionAsRppBak,
        preserveAllPreviousVersionsInOneRppBak, and preservePreviouslySavedVersionOfProjectAsRppBak.enable
        are mutually exclusive.
      '';
    }
  ];

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.project.backups.whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak.limitAutoSavedBackupsToMostRecent.count";
        value = timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.count;
        section = "reaper";
        key = "savebackuplimit";
        codec = "integer";
      }
      {
        path = "preferences.project.backups.autoSave.autoSaveToTimestampedFileInAdditionalDirectory.limitAutoSavedBackupsToMostRecent.count";
        value = additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.count;
        section = "reaper";
        key = "autosavebackuplimit";
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
