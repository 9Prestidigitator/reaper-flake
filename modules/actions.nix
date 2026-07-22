{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) filter hasInfix hasPrefix intersectLists length literalExpression mkOption nameValuePair types unique;

  cfg = config.programs.reaper.actions;
  reaperCfg = config.programs.reaper;
  inherit (reaperLib.reaperActions) formatCustomAction formatKeyBinding formatScript;

  rawBindingType = types.submodule {
    options = {
      modifierFlags = mkOption {
        type = types.ints.unsigned;
        example = 29;
        description = "REAPER key modifier flag integer.";
      };

      keyCode = mkOption {
        type = types.ints.unsigned;
        example = 79;
        description = "REAPER virtual key code.";
      };

      command = mkOption {
        type = types.oneOf [types.int types.str];
        example = 1016;
        description = "REAPER command id or custom action id.";
      };

      section = mkOption {
        type = types.int;
        default = 0;
        example = 32060;
        description = "REAPER action section id. `0` is the main action section.";
      };

      comment = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Main : Ctrl+Alt+Shift+O : Transport: Stop";
        description = "Optional human-readable comment written after the key binding.";
      };
    };
  };

  scriptType = types.submodule ({config, ...}: {
    options = {
      flags = mkOption {
        type = types.ints.unsigned;
        default = 4;
        description = "REAPER script registration flags.";
      };

      section = mkOption {
        type = types.int;
        default = 0;
        description = "REAPER action section id for this script registration.";
      };

      commandId = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "RS1ee9bb229dabffe151848d7efa3c10f748e1a1cf";
        description = ''
          Stable REAPER script command id. When unset, a deterministic `RS...`
          id is generated from the script section and resolved path.
        '';
      };

      description = mkOption {
        type = types.str;
        default = "Custom: ${baseNameOf config.path}";
        defaultText = literalExpression ''"Custom: ''${baseNameOf config.path}"'';
        example = "Custom: lyrics.lua";
        description = ''
          Description stored in the `SCR` registration line. REAPER commonly
          displays script actions as `Script: <file name>` in the action list.
        '';
      };

      path = mkOption {
        type = types.str;
        example = "Cockos/lyrics.lua";
        description = ''
          Script path. Relative paths are resolved according to `location`;
          absolute paths require `location = "absolute"`.
        '';
      };

      location = mkOption {
        type = types.enum ["scripts" "resource" "absolute"];
        default = "scripts";
        description = ''
          How `path` is resolved before writing `reaper-kb.ini`: under
          `Scripts`, under the REAPER resource directory, or as an absolute path.
        '';
      };

      source = mkOption {
        type = types.nullOr (types.oneOf [types.path types.str]);
        default = null;
        example = literalExpression ''"''${pkgs.reaper}/opt/REAPER/InstallData/Scripts/Cockos/lyrics.lua"'';
        description = ''
          Optional Nix-owned script file to symlink into the REAPER resource
          directory. Only valid for `location = "scripts"` or `"resource"`.
        '';
      };
    };
  });

  customActionType = types.submodule ({config, ...}: {
    options = {
      name = mkOption {
        type = types.str;
        example = "Prepare recording";
        description = "Name used to derive a stable command id when `commandId` is unset.";
      };

      description = mkOption {
        type = types.str;
        default = "Custom: ${config.name}";
        defaultText = literalExpression ''"Custom: ''${config.name}"'';
        example = "Custom: Prepare recording";
        description = "Custom action description shown in REAPER's Actions list.";
      };

      commandId = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "prepare_recording";
        description = ''
          Stable custom-action command id. When unset, a deterministic `CA...`
          id is generated from the action section and `name`. Set this explicitly
          when a command id must remain unchanged after renaming the action.
        '';
      };

      section = mkOption {
        type = types.int;
        default = 0;
        description = "REAPER action section in which this custom action is available.";
      };

      actions = mkOption {
        type = types.listOf (types.oneOf [types.int types.str]);
        example = [40001 40044 "RS_toggle_click"];
        description = ''
          REAPER command ids, ReaScript ids, extension-action ids, or custom-action
          ids to run in order. String ids may be written with or without their
          leading underscore.
        '';
      };

      consolidateUndoPoints = mkOption {
        type = types.bool;
        default = false;
        description = "Consolidate the component actions into one undo point.";
      };

      showInActionsMenu = mkOption {
        type = types.bool;
        default = false;
        description = "Show this custom action in REAPER's Actions menu.";
      };
    };
  });

  resolvedScriptPath = script:
    if script.location == "absolute"
    then script.path
    else if script.location == "resource"
    then "${reaperCfg.configPath}/${script.path}"
    else "${reaperCfg.configPath}/Scripts/${script.path}";

  scriptResourcePath = script:
    if script.location == "resource"
    then script.path
    else "Scripts/${script.path}";

  normalizeScriptCommandId = script: let
    commandId =
      if script.commandId == null
      then "RS${builtins.hashString "sha1" "${toString script.section}:${resolvedScriptPath script}"}"
      else script.commandId;
  in
    if hasPrefix "_" commandId
    then builtins.substring 1 ((builtins.stringLength commandId) - 1) commandId
    else commandId;

  lineScript = script:
    script
    // {
      commandId = normalizeScriptCommandId script;
      path = resolvedScriptPath script;
    };

  configuredScriptIds = map (script: "${toString script.section}:${normalizeScriptCommandId script}") cfg.scripts;
  normalizeCustomActionCommandId = action: let
    commandId =
      if action.commandId == null
      then "CA${builtins.hashString "sha1" "${toString action.section}:${action.name}"}"
      else action.commandId;
  in
    if hasPrefix "_" commandId
    then builtins.substring 1 ((builtins.stringLength commandId) - 1) commandId
    else commandId;
  lineCustomAction = action: {
    inherit (action) actions description section;
    commandId = normalizeCustomActionCommandId action;
    flags =
      (
        if action.consolidateUndoPoints
        then 1
        else 0
      )
      + (
        if action.showInActionsMenu
        then 2
        else 0
      );
  };
  configuredCustomActionIds = map (action: "${toString action.section}:${normalizeCustomActionCommandId action}") cfg.customActions;
  badCustomActionCommandIds =
    filter (
      action: let
        commandId = normalizeCustomActionCommandId action;
      in
        (builtins.match "[^[:space:]\"]+" commandId) == null
    )
    cfg.customActions;
  emptyCustomActions = filter (action: action.actions == []) cfg.customActions;
  badCustomActionActionIds = filter (action: builtins.any (command: builtins.isString command && ((builtins.match "[^[:space:]\"]+" command) == null)) action.actions) cfg.customActions;
  badCustomActionNewlines = filter (action: hasInfix "\n" action.description) cfg.customActions;
  badScriptCommandIds =
    filter (
      script: let
        commandId = normalizeScriptCommandId script;
      in
        (builtins.match "RS[^[:space:]\"]+" commandId) == null
    )
    cfg.scripts;
  badRelativeScriptPaths = filter (script: script.location != "absolute" && hasPrefix "/" script.path) cfg.scripts;
  badAbsoluteScriptPaths = filter (script: script.location == "absolute" && !(hasPrefix "/" script.path)) cfg.scripts;
  badScriptSources = filter (script: script.source != null && script.location == "absolute") cfg.scripts;
  badScriptNewlines = filter (script: hasInfix "\n" script.path || hasInfix "\n" script.description) cfg.scripts;
  scriptsWithSources = filter (script: script.source != null) cfg.scripts;
  scriptResourcePaths = map scriptResourcePath scriptsWithSources;
  scriptResourceLinks = builtins.listToAttrs (map (script: nameValuePair (scriptResourcePath script) script.source) scriptsWithSources);
in {
  options.programs.reaper.actions = {
    keyBindings = mkOption {
      type = types.listOf rawBindingType;
      default = [];
      description = "Raw managed `reaper-kb.ini` keyboard/action shortcuts.";
    };

    scripts = mkOption {
      type = types.listOf scriptType;
      default = [];
      description = "Managed `reaper-kb.ini` script action registrations.";
    };

    customActions = mkOption {
      type = types.listOf customActionType;
      default = [];
      description = "Managed REAPER custom actions that run a sequence of actions.";
    };

    rawLines = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Advanced raw `reaper-kb.ini` lines managed with previous-generation cleanup.";
    };
  };

  config = {
    assertions = [
      {
        assertion = length configuredScriptIds == length (unique configuredScriptIds);
        message = "REAPER action scripts must not reuse the same commandId in the same section.";
      }
      {
        assertion = length configuredCustomActionIds == length (unique configuredCustomActionIds);
        message = "REAPER custom actions must not reuse the same commandId in the same section.";
      }
      {
        assertion = intersectLists configuredScriptIds configuredCustomActionIds == [];
        message = "REAPER scripts and custom actions must not reuse the same commandId in the same section.";
      }
      {
        assertion = badScriptCommandIds == [];
        message = "REAPER action script commandId values must start with `RS` and contain no whitespace or quotes.";
      }
      {
        assertion = badCustomActionCommandIds == [];
        message = "REAPER custom action commandId values must contain no whitespace or quotes.";
      }
      {
        assertion = emptyCustomActions == [];
        message = "REAPER custom actions must contain at least one action.";
      }
      {
        assertion = badCustomActionActionIds == [];
        message = "REAPER custom action string action ids must contain no whitespace or quotes.";
      }
      {
        assertion = badCustomActionNewlines == [];
        message = "REAPER custom action descriptions must be single-line strings.";
      }
      {
        assertion = badRelativeScriptPaths == [];
        message = "REAPER action script paths with `location = \"scripts\"` or `\"resource\"` must be relative.";
      }
      {
        assertion = badAbsoluteScriptPaths == [];
        message = "REAPER action script paths with `location = \"absolute\"` must be absolute.";
      }
      {
        assertion = badScriptSources == [];
        message = "REAPER action script `source` cannot be used with `location = \"absolute\"`.";
      }
      {
        assertion = length scriptResourcePaths == length (unique scriptResourcePaths);
        message = "REAPER action scripts with `source` must not install to the same resource path.";
      }
      {
        assertion = badScriptNewlines == [];
        message = "REAPER action script paths and descriptions must be single-line strings.";
      }
    ];

    programs.reaper = {
      lineFiles.files."reaper-kb.ini" =
        (map (script: formatScript (lineScript script)) cfg.scripts)
        ++ (map (action: formatCustomAction (lineCustomAction action)) cfg.customActions)
        ++ (map formatKeyBinding cfg.keyBindings)
        ++ cfg.rawLines;

      resourceLinks.files = scriptResourceLinks;
    };
  };
}
