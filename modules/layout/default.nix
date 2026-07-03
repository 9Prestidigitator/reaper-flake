{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkMerge mkOption optionalAttrs types;

  cfg = config.programs.reaper.layout;
  windowStateType = types.enum (builtins.attrValues reaperLib.reaperLayout.windowState);

  floatingWindowOptions = {
    position = mkOption {
      type = types.nullOr reaperLib.reaperTypes.layout.position;
      default = null;
      example = {
        x = 80;
        y = 80;
      };
      description = "Floating window position.";
    };

    size = mkOption {
      type = types.nullOr reaperLib.reaperTypes.layout.size;
      default = null;
      example = {
        width = 1000;
        height = 360;
      };
      description = "Floating window size.";
    };
  };

  visibleWindowOptions =
    floatingWindowOptions
    // {
      visible = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether the window is visible.";
      };
    };

  dockableWindowOptions =
    visibleWindowOptions
    // {
      docked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether the window is docked in a REAPER docker.";
      };

      docker = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "main";
        description = ''
          Name of a `programs.reaper.layout.dockers` entry where this window
          should be docked.
        '';
      };

      dockId = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = literalExpression "reaperLayout.dock.mainDocker";
        description = ''
          Raw REAPER docker ID for `[REAPERdockpref]`. Prefer `docker` when
          assigning the window to a named docker container.
        '';
      };
    };

  mainWindowAttrs = window:
    optionalAttrs (window.position != null) {
      wnd_x = window.position.x;
      wnd_y = window.position.y;
    }
    // optionalAttrs (window.size != null) {
      wnd_w = window.size.width;
      wnd_h = window.size.height;
    }
    // optionalAttrs (window.state != null) {
      wnd_state = window.state;
    };

  prefixedWindowAttrs = prefix: window:
    optionalAttrs (window.visible != null) {
      "${prefix}_vis" = window.visible;
    }
    // optionalAttrs (window.docked != null) {
      "${prefix}_dock" = window.docked;
    }
    // optionalAttrs (window.position != null) {
      "${prefix}_x" = window.position.x;
      "${prefix}_y" = window.position.y;
    }
    // optionalAttrs (window.size != null) {
      "${prefix}_w" = window.size.width;
      "${prefix}_h" = window.size.height;
    }
    // optionalAttrs ((window.maximized or null) != null) {
      "${prefix}_max" = window.maximized;
    };

  sectionWindowAttrs = window:
    optionalAttrs (window.visible != null) {
      wnd_vis = window.visible;
    }
    // optionalAttrs (window.docked != null) {
      wnd_dock = window.docked;
    }
    // optionalAttrs (window.position != null) {
      wnd_x = window.position.x;
      wnd_y = window.position.y;
    }
    // optionalAttrs (window.size != null) {
      wnd_w = window.size.width;
      wnd_h = window.size.height;
    }
    // optionalAttrs ((window.maximized or null) != null) {
      wnd_max = window.maximized;
    };

  transportAttrs =
    prefixedWindowAttrs "transport" cfg.transport
    // optionalAttrs (cfg.transport.dockPosition != null) {
      transport_dock_pos = cfg.transport.dockPosition;
    };
in {
  imports = [
    ./dock.nix
  ];

  options.programs.reaper.layout = {
    mainWindow =
      floatingWindowOptions
      // {
        state = mkOption {
          type = types.nullOr windowStateType;
          default = null;
          example = literalExpression "reaperLayout.windowState.maximized";
          description = ''
            Main REAPER window state. Named values are available from
            `reaperLayout.windowState`.
          '';
        };
      };

    mixer =
      dockableWindowOptions
      // {
        maximized = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether the floating mixer window is maximized.";
        };
      };

    masterMixer =
      dockableWindowOptions
      // {
        maximized = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether the floating master mixer window is maximized.";
        };
      };

    transport =
      dockableWindowOptions
      // {
        dockPosition = mkOption {
          type = types.nullOr (types.enum (builtins.attrValues reaperLib.reaperWindows.transport));
          default = null;
          example = literalExpression "reaperWindows.transport.topOfMainWindow";
          description = ''
            Transport position in REAPER's main window. Named values are available
            from `reaperWindows.transport`.
          '';
        };
      };

    rawSections = mkOption {
      type = types.attrsOf (types.attrsOf reaperLib.reaperTypes.iniValue);
      default = {};
      example = literalExpression ''
        {
          reaper_explorer = {
            window_x = 80;
            window_y = 80;
            window_w = 900;
            window_h = 420;
          };
        }
      '';
      description = ''
        Additional layout-related INI sections. Use this for REAPER windows that
        do not yet have first-class layout options.
      '';
    };
  };

  config = {
    programs.reaper.ini.sections = mkMerge [
      {
        reaper =
          mainWindowAttrs cfg.mainWindow
          // prefixedWindowAttrs "mixwnd" cfg.mixer
          // transportAttrs;

        mastermixer = sectionWindowAttrs cfg.masterMixer;
      }
      cfg.rawSections
    ];
  };
}
