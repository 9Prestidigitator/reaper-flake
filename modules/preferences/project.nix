{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption optionalAttrs types;
  cfg = config.programs.reaper.preferences.project;
  backups = cfg.backups;
  whenSaving = backups.whenSaving;
  autoSave = backups.autoSave;
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

  optionalBitfield = enabled: attrs:
    optionalAttrs enabled attrs;

  timestampedSaveBackups = whenSaving.preservePreviouslySavedVersionOfProjectAsRppBak;
  autoSaveToProjectFile = autoSave.autoSaveToProjectFile;
  projectDirectoryAutoSave = autoSave.autoSaveToTimestampedFileInProjectDirectory;
  additionalDirectoryAutoSave = autoSave.autoSaveToTimestampedFileInAdditionalDirectory;
  autoSaveInterval = autoSave.autoSaveInterval;
  autoSaveUnsavedProjectsToTemporaryFile = autoSave.autoSaveUnsavedProjectsToTemporaryFile;
  autoSaveBackupLimitCount =
    if projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.count != null
    then projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.count
    else additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.count;

  saveoptsMask =
    (
      if whenSaving.preservePreviousVersionAsRppBak != null
      then 1
      else 0
    )
    + (
      if autoSaveToProjectFile != null
      then 2
      else 0
    )
    + (
      if projectDirectoryAutoSave.enable != null
      then 4
      else 0
    )
    + (
      if additionalDirectoryAutoSave.enable != null
      then 8
      else 0
    )
    + (
      if timestampedSaveBackups.enable != null
      then 16
      else 0
    )
    + (
      if timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.enable != null
      then 32
      else 0
    )
    + (
      if timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.unit != null
      then 64
      else 0
    )
    + (
      if projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.enable != null
      then 128
      else 0
    )
    + (
      if projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.unit != null
      then 256
      else 0
    )
    + (
      if additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.enable != null
      then 512
      else 0
    )
    + (
      if additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.mode != null
      then 3072
      else 0
    )
    + (
      if timestampedSaveBackups.saveTimestampedBackupsToProjectBackupsSubdirectory != null
      then 4096
      else 0
    )
    + (
      if projectDirectoryAutoSave.saveBackupsToProjectAutoSavesSubdirectory != null
      then 8192
      else 0
    )
    + (
      if autoSaveUnsavedProjectsToTemporaryFile != null
      then 16384
      else 0
    );
  saveoptsValue =
    (
      if whenSaving.preservePreviousVersionAsRppBak == true
      then 1
      else 0
    )
    + (
      if autoSaveToProjectFile == true
      then 2
      else 0
    )
    + (
      if projectDirectoryAutoSave.enable == true
      then 4
      else 0
    )
    + (
      if additionalDirectoryAutoSave.enable == true
      then 8
      else 0
    )
    + (
      if timestampedSaveBackups.enable == true
      then 16
      else 0
    )
    + (
      if timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.enable == true
      then 32
      else 0
    )
    + (
      if timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.unit == "uniqueDays"
      then 64
      else 0
    )
    + (
      if projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.enable == true
      then 128
      else 0
    )
    + (
      if projectDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.unit == "uniqueDays"
      then 256
      else 0
    )
    + (
      if additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.enable == true
      then 512
      else 0
    )
    + (
      if additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.mode != null
      then additionalDirectoryLimitModes.${additionalDirectoryAutoSave.limitAutoSavedBackupsToMostRecent.mode}
      else 0
    )
    + (
      if timestampedSaveBackups.saveTimestampedBackupsToProjectBackupsSubdirectory == true
      then 4096
      else 0
    )
    + (
      if projectDirectoryAutoSave.saveBackupsToProjectAutoSavesSubdirectory == true
      then 8192
      else 0
    )
    + (
      if autoSaveUnsavedProjectsToTemporaryFile == true
      then 16384
      else 0
    );

  saveUndoStatesProjectMask =
    if whenSaving.preserveAllPreviousVersionsInOneRppBak != null
    then 512
    else 0;
  saveUndoStatesProjectValue =
    if whenSaving.preserveAllPreviousVersionsInOneRppBak == true
    then 512
    else 0;
in {
  options.programs.reaper.preferences.project = {
    backups = {
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
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.count != null) {
      savebackuplimit = timestampedSaveBackups.limitAutoSavedBackupsToMostRecent.count;
    }
    // optionalAttrs (autoSaveBackupLimitCount != null) {autosavebackuplimit = autoSaveBackupLimitCount;}
    // optionalAttrs (autoSaveInterval.minutes != null) {autosaveint = autoSaveInterval.minutes * 60;}
    // optionalAttrs (autoSaveInterval.mode != null) {autosavemode = autoSaveIntervalModes.${autoSaveInterval.mode};}
    // optionalAttrs (additionalDirectoryAutoSave.path != null) {autosavedir = additionalDirectoryAutoSave.path;}
    // optionalAttrs (autoSave.autoSavePathForUnsavedProjects.path != null) {autosavedir_unsaved = autoSave.autoSavePathForUnsavedProjects.path;};

  config.programs.reaper.ini.bitfields.reaper =
    optionalBitfield (saveoptsMask != 0) {
      saveopts = {
        mask = saveoptsMask;
        value = saveoptsValue;
      };
    }
    // optionalBitfield (saveUndoStatesProjectMask != 0) {
      saveundostatesproj = {
        mask = saveUndoStatesProjectMask;
        value = saveUndoStatesProjectValue;
      };
    };
}
