{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) filterAttrs literalExpression mapAttrs mapAttrs' mapAttrsToList mkOption nameValuePair optionalAttrs types;

  cfg = config.programs.reaper.layout;

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
        type = types.nullOr (types.enum reaperLib.reaperLayout.dockPositions);
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

  namedDocks = builtInDocks // cfg.docks;

  dockNameOf = window: window.dock or null;

  dockIdOf = window: let
    dockName = dockNameOf window;
  in
    if (window.dockId or null) != null
    then window.dockId
    else if dockName != null && builtins.hasAttr dockName namedDocks
    then namedDocks.${dockName}.id
    else null;

  windowDockPreference = window: let
    dockName = dockNameOf window;
    dockId = dockIdOf window;
  in
    if (window.dockPreference or null) != null
    then window.dockPreference
    else if (window.tabOrder or null) != null && dockId != null
    then "${toString window.tabOrder} ${toString dockId}"
    else if dockName != null && builtins.hasAttr dockName namedDocks
    then namedDocks.${dockName}.id
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

  panelDockPreferences =
    mapAttrs'
    (_: panel: nameValuePair panel.id (windowDockPreference panel))
    (filterAttrs (_: panel: windowDockPreference panel != null) cfg.panels);

  dockPreferences =
    knownWindowDockPreferences
    // panelDockPreferences
    // cfg.dockPreferences;

  referencedDocks =
    filterAttrs (_: value: value != null)
    ({
        mixer = dockNameOf cfg.mixer;
        mastermixer = dockNameOf cfg.masterMixer;
        transport = dockNameOf cfg.transport;
      }
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
