{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mapAttrsToList mkMerge mkOption optionalAttrs types;

  cfg = config.programs.reaper.layout;
  windowStateType = types.enum (builtins.attrValues reaperLib.reaperLayout.windowState);
  panelKeyStyleType = types.enum [
    "reaper"
    "section-long"
    "section-short"
    "window"
    "simple"
  ];

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

      dock = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "left";
        description = ''
          Name of a `programs.reaper.layout.docks` entry where this window
          should be docked. Prefer this for new configuration.
        '';
      };

      dockId = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = literalExpression "reaperLayout.dock.mainDocker";
        description = ''
          Raw REAPER docker ID for `[REAPERdockpref]`. Prefer `dock` when
          assigning the window to a named docker container.
        '';
      };

      dockPreference = mkOption {
        type = types.nullOr reaperLib.reaperTypes.iniValue;
        default = null;
        example = "0.50000000 2";
        description = ''
          Raw `[REAPERdockpref]` value. This overrides `dock`, `docker`,
          `dockId`, and `tabOrder`.
        '';
      };

      tabOrder = mkOption {
        type = types.nullOr (reaperLib.reaperTypes.boundedNumber "dock tab order between 0 and 1" 0 1);
        default = null;
        example = 0.5;
        description = ''
          Relative tab order inside the target dock. REAPER stores this as the
          first number in `[REAPERdockpref]` values like `0.50000000 2`.
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

  sectionLongWindowAttrs = window:
    optionalAttrs (window.visible != null) {
      wnd_vis = window.visible;
    }
    // optionalAttrs (window.docked != null) {
      dock = window.docked;
    }
    // optionalAttrs (window.position != null) {
      wnd_left = window.position.x;
      wnd_top = window.position.y;
    }
    // optionalAttrs (window.size != null) {
      wnd_width = window.size.width;
      wnd_height = window.size.height;
    }
    // optionalAttrs ((window.maximized or null) != null) {
      wnd_max = window.maximized;
    };

  windowSectionAttrs = window:
    optionalAttrs (window.visible != null) {
      visible = window.visible;
    }
    // optionalAttrs (window.position != null) {
      window_x = window.position.x;
      window_y = window.position.y;
    }
    // optionalAttrs (window.size != null) {
      window_w = window.size.width;
      window_h = window.size.height;
    }
    // optionalAttrs ((window.maximized or null) != null) {
      window_max = window.maximized;
    };

  simplePanelAttrs = window:
    optionalAttrs (window.visible != null) {
      visible = window.visible;
    };

  transportAttrs =
    prefixedWindowAttrs "transport" cfg.transport
    // optionalAttrs (cfg.transport.dockPosition != null) {
      transport_dock_pos = cfg.transport.dockPosition;
    };

  panelType = types.submodule ({name, ...}: {
    options =
      dockableWindowOptions
      // {
        id = mkOption {
          type = types.str;
          default = name;
          defaultText = literalExpression "attribute name";
          example = "explorer";
          description = ''
            REAPER window ID used in `[REAPERdockpref]`. This is usually the
            same token that appears in `dockerselN`.
          '';
        };

        section = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "reaper_sexplorer";
          description = ''
            INI section where this panel stores its window state. When unset,
            the panel ID is used, except for `keyStyle = "reaper"` which writes
            into `[reaper]`.
          '';
        };

        prefix = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "mixwnd";
          description = ''
            Prefix used by `keyStyle = "reaper"` for keys such as
            `mixwnd_vis`, `mixwnd_dock`, and `mixwnd_h`. Defaults to the panel
            ID.
          '';
        };

        keyStyle = mkOption {
          type = panelKeyStyleType;
          default = "simple";
          example = "window";
          description = ''
            INI key family used for the panel's own window state:
            `reaper` writes prefixed keys in `[reaper]`, `section-long` writes
            keys like `wnd_left` and `wnd_width`, `section-short` writes keys
            like `wnd_x` and `wnd_w`, `window` writes keys like `window_x`, and
            `simple` writes only `visible` plus `raw`.
          '';
        };

        maximized = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether the floating panel window is maximized.";
        };

        raw = mkOption {
          type = types.attrsOf reaperLib.reaperTypes.iniValue;
          default = {};
          example = literalExpression ''
            {
              peak_height = 80;
              volume = 4096;
            }
          '';
          description = ''
            Extra keys to write into this panel's INI section. These override
            generated keys for the same panel.
          '';
        };
      };
  });

  panelSectionName = panel:
    if panel.section != null
    then panel.section
    else if panel.keyStyle == "reaper"
    then "reaper"
    else panel.id;

  panelAttrs = panel:
    (
      if panel.keyStyle == "reaper"
      then
        prefixedWindowAttrs (
          if panel.prefix != null
          then panel.prefix
          else panel.id
        )
        panel
      else if panel.keyStyle == "section-long"
      then sectionLongWindowAttrs panel
      else if panel.keyStyle == "section-short"
      then sectionWindowAttrs panel
      else if panel.keyStyle == "window"
      then windowSectionAttrs panel
      else simplePanelAttrs panel
    )
    // panel.raw;

  panelSections =
    mapAttrsToList
    (_: panel: {
      "${panelSectionName panel}" = panelAttrs panel;
    })
    cfg.panels;
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

    panels = mkOption {
      type = types.attrsOf panelType;
      default = {};
      example = literalExpression ''
        {
          explorer = {
            id = "explorer";
            section = "reaper_sexplorer";
            keyStyle = "window";
            visible = true;
            docked = true;
            dock = "left";
            tabOrder = 0.5;
            raw = {
              peak_height = 80;
              volume = 4096;
            };
          };

          routingMatrix = {
            id = "routing";
            section = "reaper_routing";
            keyStyle = "window";
            visible = true;
            dock = "top";
          };
        }
      '';
      description = ''
        Arbitrary REAPER panels. Each panel can render its own INI section and
        can also be assigned to a named dock through `[REAPERdockpref]`.
      '';
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

        mastermixer = sectionLongWindowAttrs cfg.masterMixer;
      }
      (mkMerge panelSections)
      cfg.rawSections
    ];
  };
}
