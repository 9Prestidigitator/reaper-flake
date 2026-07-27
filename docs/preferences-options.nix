{lib, pkgs}:
let
  # The Home Manager module normally supplies `hm`. The preferences option
  # declarations do not depend on its DAG implementation, but the complete
  # module must still be evaluable to expose its options.
  hm = {
    dag.entryAfter = _after: value: value;
  };

  reaperLib = import ../modules/lib {inherit lib;};

  evaluated = lib.evalModules {
    specialArgs = reaperLib // {inherit hm pkgs; reaperLib = reaperLib;};
    modules = [
      ../modules/ini.nix
      ../modules/preferences/general
      ../modules/preferences/project
      ../modules/preferences/appearance
      ../modules/preferences/editing-behavior
      ../modules/preferences/media
      ../modules/preferences/plugins
      ../modules/preferences/control-osc-web.nix
      {
        # These assertions are normally supplied by Home Manager/NixOS. The
        # preference modules use them for validation, so declare the minimal
        # host options needed for an options-only evaluation.
        options.assertions = lib.mkOption {
          type = lib.types.listOf lib.types.unspecified;
          default = [];
        };
        options.warnings = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };

      }
    ];
  };

in
  pkgs.nixosOptionsDoc {
    # Keep the generated reference scoped to REAPER preferences while wrapping
    # the subtree again so the documented paths retain their public prefix.
    options = {
      programs.reaper.preferences = evaluated.options.programs.reaper.preferences;
    };
    # Some legacy preference scaffolding predates mandatory option
    # descriptions. Keep documenting those options while the warnings are
    # surfaced during generation.
    warningsAreErrors = false;
  }
