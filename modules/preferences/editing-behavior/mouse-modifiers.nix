{
  config,
  lib,
  ...
}: let
  inherit (lib) mapAttrs mkOption optionalString types;

  cfg = config.programs.reaper.preferences.editingBehavior.mouseModifiers;

  bindingType = types.oneOf [
    types.str
    (types.submodule {
      options = {
        action = mkOption {
          type = types.oneOf [types.int types.str];
          description = "REAPER mouse modifier action id.";
        };

        mode = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "m";
          description = "Optional REAPER mouse modifier mode suffix.";
        };
      };
    })
  ];

  formatBinding = value:
    if builtins.isString value
    then value
    else "${toString value.action}${optionalString (value.mode != null) " ${value.mode}"}";
in {
  options.programs.reaper.preferences.editingBehavior.mouseModifiers = {
    importedContexts = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["MM_CTX_ARRANGE_MMOUSE" "MM_CTX_MIDI_NOTE_CLK"];
      description = "Raw mouse modifier contexts whose REAPER factory defaults have been imported.";
    };

    contexts = mkOption {
      type = types.attrsOf (types.attrsOf bindingType);
      default = {};
      example = {
        MM_CTX_ARRANGE_MMOUSE = {
          mm_0 = {
            action = 2;
            mode = "m";
          };
          mm_1 = "7 m";
        };
      };
      description = "Raw REAPER mouse modifier bindings by `reaper-mouse.ini` context and modifier key.";
    };
  };

  config.programs.reaper.ini.files."reaper-mouse.ini" =
    {
      hasimported = builtins.listToAttrs (map (context: {
          name = context;
          value = true;
        })
        cfg.importedContexts);
    }
    // mapAttrs (_: bindings: mapAttrs (_: formatBinding) bindings) cfg.contexts;
}
