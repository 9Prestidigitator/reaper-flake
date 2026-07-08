{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) filterAttrs literalExpression mapAttrs mapAttrs' mapAttrsToList mkOption nameValuePair optionalAttrs types;

  cfg = config.programs.reaper.layout;

  legacyDockerPositionType = types.enum [
    "main"
    "left"
    "right"
    "top"
    "bottom"
  ];

  dockPositionType = types.enum [
    "left"
    "right"
    "top"
    "bottom"
  ];

  tabOrderType = reaperLib.reaperTypes.boundedNumber "dock tab order between 0 and 1" 0 1;

  legacyDockerType = types.submodule {
    options = {
      id = mkOption {
        type = types.int;
        default = reaperLib.reaperLayout.dock.mainDocker;
        defaultText = literalExpression "reaperLayout.dock.mainDocker";
        example = literalExpression "reaperLayout.dock.mainDocker";
        description = ''
          Raw REAPER docker ID used when assigning windows to this docker.
        '';
      };

      position = mkOption {
        type = legacyDockerPositionType;
        default = "main";
        example = "left";
        description = ''
          Legacy descriptive placement. Prefer `programs.reaper.layout.docks`
          for new configuration because it writes REAPER's `dockermodeN` keys.
        '';
      };

      size = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 320;
        description = ''
          Legacy descriptive size. Prefer `programs.reaper.layout.docks` for
          new configuration because dock sizes are global per screen edge.
        '';
      };

      splitRatio = mkOption {
        type = types.nullOr tabOrderType;
        default = null;
        example = 0.25;
        description = ''
          Legacy tab order value used for `[REAPERdockpref]` entries. Prefer
          the window or panel `tabOrder` option for new configuration.
        '';
      };

      preference = mkOption {
        type = types.nullOr reaperLib.reaperTypes.iniValue;
        default = null;
        example = "0.85531396 1";
        description = ''
          Raw `[REAPERdockpref]` value used for windows assigned to this docker.
          Prefer panel-level `dock` and `tabOrder` for new configuration.
        '';
      };
    };
  };

  dockType = types.submodule {
    options = {
      id = mkOption {
        type = types.int;
        example = 2;
        description = ''
          REAPER docker container ID. This is the `N` in `dockermodeN`,
          `dockerselN`, and the second value in `[REAPERdockpref]`.
        '';
      };

      position = mkOption {
        type = types.nullOr dockPositionType;
        default = null;
        example = "left";
        description = ''
          Physical edge where this docker container is attached. This writes
          `[reaper].dockermodeN` using REAPER's mode values: bottom = 0,
          left = 1, top = 2, right = 3.
        '';
      };

      mode = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = literalExpression "reaperLayout.dockMode.left";
        description = ''
          Raw `dockermodeN` value. Use this only when REAPER exposes a mode
          value that is not covered by `position`.
        '';
      };

      size = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 320;
        description = ''
          Size in pixels for the screen edge occupied by this dock. REAPER
          stores dock sizes globally per edge, not per docker ID.
        '';
      };

      sizeKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "dockheight_l";
        description = ''
          Raw `[reaper]` size key for this dock. When unset, the key is inferred
          from `position`: bottom = `dockheight`, left = `dockheight_l`,
          right = `dockheight_r`, top = `dockheight_t`.
        '';
      };

      selectedPanel = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "explorer";
        description = ''
          REAPER panel ID selected in this docker's tab strip. This writes
          `[reaper].dockerselN`.
        '';
      };
    };
  };

  dockedWindowType = types.submodule {
    options = {
      dock = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "left";
        description = ''
          Name of a `programs.reaper.layout.docks` entry where this REAPER
          window should be docked.
        '';
      };

      docker = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "left";
        description = ''
          Legacy alias for `dock`. Kept for existing configurations.
        '';
      };

      dockId = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = literalExpression "reaperLayout.dock.mainDocker";
        description = ''
          Raw REAPER docker ID for this window. Prefer `dock` when assigning the
          window to a named docker container.
        '';
      };

      dockPreference = mkOption {
        type = types.nullOr reaperLib.reaperTypes.iniValue;
        default = null;
        example = "0.85531396 1";
        description = ''
          Raw `[REAPERdockpref]` value for this window. This overrides `dock`,
          `docker`, `dockId`, and `tabOrder`.
        '';
      };

      tabOrder = mkOption {
        type = types.nullOr tabOrderType;
        default = null;
        example = 0.5;
        description = ''
          Relative tab order inside the target dock.
        '';
      };
    };
  };

  builtInDocks = {
    main = {
      id = reaperLib.reaperLayout.dock.mainDocker;
      position = null;
      mode = null;
      size = null;
      sizeKey = null;
      selectedPanel = null;
    };
  };

  legacyDocks =
    mapAttrs (_: docker: {
      inherit (docker) id size;
      position =
        if docker.position == "main"
        then null
        else docker.position;
      mode = null;
      sizeKey = null;
      selectedPanel = null;
      preference = docker.preference;
      splitRatio = docker.splitRatio;
    })
    cfg.dockers;

  namedDocks = builtInDocks // legacyDocks // cfg.docks;

  dockNameOf = window:
    if (window.dock or null) != null
    then window.dock
    else window.docker or null;

  dockIdOf = window: let
    dockName = dockNameOf window;
  in
    if (window.dockId or null) != null
    then window.dockId
    else if dockName != null && builtins.hasAttr dockName namedDocks
    then namedDocks.${dockName}.id
    else null;

  legacyDockPreferenceValue = dock:
    if (dock.preference or null) != null
    then dock.preference
    else if (dock.splitRatio or null) != null
    then "${toString dock.splitRatio} ${toString dock.id}"
    else dock.id;

  windowDockPreference = window: let
    dockName = dockNameOf window;
    dockId = dockIdOf window;
  in
    if (window.dockPreference or null) != null
    then window.dockPreference
    else if (window.tabOrder or null) != null && dockId != null
    then "${toString window.tabOrder} ${toString dockId}"
    else if dockName != null && builtins.hasAttr dockName namedDocks
    then legacyDockPreferenceValue namedDocks.${dockName}
    else if dockId != null
    then dockId
    else null;

  knownWindowDockPreferences =
    optionalAttrs (windowDockPreference cfg.mixer != null) {
      mixer = windowDockPreference cfg.mixer;
    }
    // optionalAttrs (windowDockPreference cfg.masterMixer != null) {
      mastermixer = windowDockPreference cfg.masterMixer;
    }
    // optionalAttrs (windowDockPreference cfg.transport != null) {
      transport = windowDockPreference cfg.transport;
    };

  arbitraryWindowDockPreferences =
    mapAttrs (_: window: windowDockPreference window)
    (filterAttrs (_: window: windowDockPreference window != null) cfg.dockedWindows);

  panelDockPreferences =
    mapAttrs'
    (_: panel: nameValuePair panel.id (windowDockPreference panel))
    (filterAttrs (_: panel: windowDockPreference panel != null) cfg.panels);

  dockPreferences =
    knownWindowDockPreferences
    // arbitraryWindowDockPreferences
    // panelDockPreferences
    // cfg.dockPreferences;

  referencedDocks =
    filterAttrs (_: value: value != null)
    ({
        mixer = dockNameOf cfg.mixer;
        mastermixer = dockNameOf cfg.masterMixer;
        transport = dockNameOf cfg.transport;
      }
      // mapAttrs (_: window: dockNameOf window) cfg.dockedWindows
      // mapAttrs (_: panel: dockNameOf panel) cfg.panels);

  modeValue = dock:
    if dock.mode != null
    then dock.mode
    else if dock.position != null
    then reaperLib.reaperLayout.dockMode.${dock.position}
    else null;

  sizeKeyFor = dock:
    if dock.sizeKey != null
    then dock.sizeKey
    else if dock.position != null
    then reaperLib.reaperLayout.dockSizeKey.${dock.position}
    else null;

  dockReaperAttrs =
    builtins.listToAttrs
    (
      mapAttrsToList
      (_: dock: nameValuePair "dockermode${toString dock.id}" (modeValue dock))
      (filterAttrs (_: dock: modeValue dock != null) cfg.docks)
      ++ mapAttrsToList
      (_: dock: nameValuePair "dockersel${toString dock.id}" dock.selectedPanel)
      (filterAttrs (_: dock: dock.selectedPanel != null) cfg.docks)
      ++ mapAttrsToList
      (_: dock: nameValuePair (sizeKeyFor dock) dock.size)
      (filterAttrs (_: dock: dock.size != null && sizeKeyFor dock != null) cfg.docks)
    );

  docksNeedingSizeKeys =
    filterAttrs (_: dock: dock.size != null && sizeKeyFor dock == null) cfg.docks;
in {
  options.programs.reaper.layout = {
    docks = mkOption {
      type = types.attrsOf dockType;
      default = {};
      example = literalExpression ''
        {
          left = {
            id = 2;
            position = "left";
            size = 395;
            selectedPanel = "explorer";
          };

          right = {
            id = 1;
            position = "right";
            size = 233;
            selectedPanel = "transport";
          };
        }
      '';
      description = ''
        Declarative REAPER docker containers. These entries write
        `[reaper].dockermodeN`, `[reaper].dockerselN`, and the global dock size
        keys for each physical edge.
      '';
    };

    dockers = mkOption {
      type = types.attrsOf legacyDockerType;
      default = {};
      defaultText = literalExpression ''
        {}
      '';
      example = literalExpression ''
        {
          main = {
            id = reaperLayout.dock.mainDocker;
            position = "main";
          };
        }
      '';
      description = ''
        Legacy named REAPER docker containers. Prefer
        `programs.reaper.layout.docks` for new configuration. This option still
        works for existing `docker = "name"` assignments and raw preferences.
      '';
    };

    dockedWindows = mkOption {
      type = types.attrsOf dockedWindowType;
      default = {};
      example = literalExpression ''
        {
          navigator.dock = "left";
        }
      '';
      description = ''
        Legacy way to write arbitrary REAPER window IDs into
        `[REAPERdockpref]`. Prefer `programs.reaper.layout.panels` when you also
        want to model the panel's own INI section.
      '';
    };

    dockPreferences = mkOption {
      type = types.attrsOf reaperLib.reaperTypes.iniValue;
      default = {};
      example = literalExpression ''
        {
          navigator = reaperLayout.dock.mainDocker;
        }
      '';
      description = ''
        Raw `[REAPERdockpref]` entries by REAPER window ID. This is the final
        escape hatch and overrides computed preferences from named docks.
      '';
    };
  };

  config = {
    assertions =
      mapAttrsToList
      (windowId: dockName: {
        assertion = builtins.hasAttr dockName namedDocks;
        message = ''
          REAPER layout window `${windowId}` refers to unknown dock `${dockName}`.
        '';
      })
      referencedDocks
      ++ mapAttrsToList
      (dockName: _: {
        assertion = false;
        message = ''
          REAPER layout dock `${dockName}` sets `size` but has neither
          `position` nor `sizeKey`, so the module cannot choose the `[reaper]`
          size key to write.
        '';
      })
      docksNeedingSizeKeys;

    programs.reaper.ini.sections =
      optionalAttrs (dockPreferences != {}) {
        REAPERdockpref = dockPreferences;
      }
      // optionalAttrs (dockReaperAttrs != {}) {
        reaper = dockReaperAttrs;
      };
  };
}
