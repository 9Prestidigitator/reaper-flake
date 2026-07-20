{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption optionalAttrs types;
  inherit (reaperLib) reaperBitfield;
  cfg = config.programs.reaper.preferences.project;
in {
  imports = [
    ./backups.nix
  ];

  options.programs.reaper.preferences.project = {
    defaultProjectTemplate = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/user/.config/REAPER/ProjectTemplates/default.RPP";
      description = "Project file REAPER uses as the template when creating new projects.";
    };

    promptToSaveOnNewProject = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER prompts to save when creating a new project.";
    };

    openPropertiesOnNewProject = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER opens Project Settings when creating a new project.";
    };

    projectLoading = {
      lookForProjectMediaInProjectDirectoryBeforeQualifiedPath = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER looks for project media in the project directory before using its qualified path.";
      };

      promptWhenFilesAreNotFound = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER prompts when files are not found while loading a project.";
      };

      showLoadStatusAndSplash = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether REAPER shows load status and the splash screen while loading projects.";
      };
    };

    projectSaving = {
      saveFileReferencesWithRelativePathnames = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether project file references are saved with relative pathnames.";
      };

      defaultSaveAsWildcardPattern = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "$project";
        description = "Default wildcard pattern used by Save Project As.";
      };

      saveNewVersionSuffix = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "_001";
        description = "Filename suffix used by Save New Version of Project.";
      };
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (cfg.defaultProjectTemplate != null) {
      newprojtmpl = cfg.defaultProjectTemplate;
    }
    // optionalAttrs (cfg.projectLoading.lookForProjectMediaInProjectDirectoryBeforeQualifiedPath != null) {
      rfprojfirst = cfg.projectLoading.lookForProjectMediaInProjectDirectoryBeforeQualifiedPath;
    }
    // optionalAttrs (cfg.projectLoading.promptWhenFilesAreNotFound != null) {
      pmfol = cfg.projectLoading.promptWhenFilesAreNotFound;
    }
    // optionalAttrs (cfg.projectSaving.saveFileReferencesWithRelativePathnames != null) {
      projrelpath = cfg.projectSaving.saveFileReferencesWithRelativePathnames;
    }
    // optionalAttrs (cfg.projectSaving.defaultSaveAsWildcardPattern != null) {
      newprojwildcards = cfg.projectSaving.defaultSaveAsWildcardPattern;
    }
    // optionalAttrs (cfg.projectSaving.saveNewVersionSuffix != null) {
      projversuffix = cfg.projectSaving.saveNewVersionSuffix;
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    newprojdo = [
      {
        optionPath = "preferences.project.promptToSaveOnNewProject";
        gui = "Prompt to save on new project";
        option = cfg.promptToSaveOnNewProject;
        bit = 1;
      }
      {
        optionPath = "preferences.project.openPropertiesOnNewProject";
        gui = "Open properties on new project";
        option = cfg.openPropertiesOnNewProject;
        bit = 2;
      }
    ];

    splash_options = [
      {
        optionPath = "preferences.project.projectLoading.showLoadStatusAndSplash";
        gui = "Show load status and splash while loading project";
        option = cfg.projectLoading.showLoadStatusAndSplash;
        bit = 1;
        inverted = true;
      }
    ];
  };
}
