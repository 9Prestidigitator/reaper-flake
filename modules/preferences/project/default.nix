{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperPreference;
  cfg = config.programs.reaper.preferences.project;
in {
  imports = [
    ./backups.nix
    ./track-send-defaults.nix
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

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.project.defaultProjectTemplate";
        value = cfg.defaultProjectTemplate;
        section = "reaper";
        key = "newprojtmpl";
      }
      {
        path = "preferences.project.projectLoading.lookForProjectMediaInProjectDirectoryBeforeQualifiedPath";
        value = cfg.projectLoading.lookForProjectMediaInProjectDirectoryBeforeQualifiedPath;
        section = "reaper";
        key = "rfprojfirst";
        codec = "bool";
      }
      {
        path = "preferences.project.projectLoading.promptWhenFilesAreNotFound";
        value = cfg.projectLoading.promptWhenFilesAreNotFound;
        section = "reaper";
        key = "pmfol";
        codec = "bool";
      }
      {
        path = "preferences.project.projectSaving.saveFileReferencesWithRelativePathnames";
        value = cfg.projectSaving.saveFileReferencesWithRelativePathnames;
        section = "reaper";
        key = "projrelpath";
        codec = "bool";
      }
      {
        path = "preferences.project.projectSaving.defaultSaveAsWildcardPattern";
        value = cfg.projectSaving.defaultSaveAsWildcardPattern;
        section = "reaper";
        key = "newprojwildcards";
      }
      {
        path = "preferences.project.projectSaving.saveNewVersionSuffix";
        value = cfg.projectSaving.saveNewVersionSuffix;
        section = "reaper";
        key = "projversuffix";
      }
    ]
    ++ map (entry: entry // {section = "reaper";}) (reaperBitfield.contributions {
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
    });
}
