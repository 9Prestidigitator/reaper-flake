{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) filterAttrs literalExpression mapAttrs mapAttrsToList mkOption optionalAttrs types;

  cfg = config.programs.reaper.layout;
  dockers =
    {
      main = {
        id = reaperLib.reaperLayout.dock.mainDocker;
        position = "main";
        size = null;
        splitRatio = null;
        preference = null;
      };
    }
    // cfg.dockers;

  dockerPositionType = types.enum [
    "main"
    "left"
    "right"
    "top"
    "bottom"
  ];

  dockerType = types.submodule {
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
        type = dockerPositionType;
        default = "main";
        example = "left";
        description = ''
          Intended physical placement of this docker. REAPER stores some docker
          topology as opaque `[REAPERdockpref]` values, so use `preference` when
          the placement requires a captured composite value.
        '';
      };

      size = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 320;
        description = ''
          Intended size of this docker in pixels. This documents the target
          layout and gives the module a stable shape for first-class topology
          support as more REAPER docker geometry keys are verified.
        '';
      };

      splitRatio = mkOption {
        type = types.nullOr (reaperLib.reaperTypes.boundedNumber "dock split ratio between 0 and 1" 0 1);
        default = null;
        example = 0.25;
        description = ''
          Split ratio used for REAPER dock preferences that are stored as
          `<ratio> <docker-id>` composite values.
        '';
      };

      preference = mkOption {
        type = types.nullOr reaperLib.reaperTypes.iniValue;
        default = null;
        example = "0.85531396 1";
        description = ''
          Raw `[REAPERdockpref]` value used for windows assigned to this docker.
          This is the escape hatch for REAPER docker topology values that are not
          yet fully decoded.
        '';
      };
    };
  };

  dockedWindowType = types.submodule {
    options = {
      docker = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "left";
        description = ''
          Name of a `programs.reaper.layout.dockers` entry where this REAPER
          window should be docked.
        '';
      };

      dockId = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = literalExpression "reaperLayout.dock.mainDocker";
        description = ''
          Raw REAPER docker ID for this window. Prefer `docker` when assigning
          the window to a named docker container.
        '';
      };

      dockPreference = mkOption {
        type = types.nullOr reaperLib.reaperTypes.iniValue;
        default = null;
        example = "0.85531396 1";
        description = ''
          Raw `[REAPERdockpref]` value for this window. This overrides `docker`
          and `dockId`.
        '';
      };
    };
  };

  dockerPreferenceValue = docker:
    if docker.preference != null
    then docker.preference
    else if docker.splitRatio != null
    then "${toString docker.splitRatio} ${toString docker.id}"
    else docker.id;

  windowDockPreference = window:
    if (window.dockPreference or null) != null
    then window.dockPreference
    else if (window.docker or null) != null && builtins.hasAttr window.docker dockers
    then dockerPreferenceValue dockers.${window.docker}
    else if (window.dockId or null) != null
    then window.dockId
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

  dockPreferences =
    knownWindowDockPreferences
    // arbitraryWindowDockPreferences
    // cfg.dockPreferences;

  referencedDockers =
    filterAttrs (_: value: value != null)
    {
      mixer = cfg.mixer.docker;
      mastermixer = cfg.masterMixer.docker;
      transport = cfg.transport.docker;
    }
    // mapAttrs (_: window: window.docker)
    (filterAttrs (_: window: window.docker != null) cfg.dockedWindows);
in {
  options.programs.reaper.layout = {
    dockers = mkOption {
      type = types.attrsOf dockerType;
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

          left = {
            id = 1;
            position = "left";
            size = 320;
            preference = "0.85531396 1";
          };
        }
      '';
      description = ''
        Named REAPER docker containers. Windows can refer to these names through
        their `docker` option instead of hard-coding REAPER docker IDs. The
        `main` docker is available by default and can be overridden here.
      '';
    };

    dockedWindows = mkOption {
      type = types.attrsOf dockedWindowType;
      default = {};
      example = literalExpression ''
        {
          explorer.docker = "left";
          navigator.docker = "main";
        }
      '';
      description = ''
        Arbitrary REAPER window IDs to write into `[REAPERdockpref]`. Use this
        for dockable windows that do not yet have first-class layout options.
      '';
    };

    dockPreferences = mkOption {
      type = types.attrsOf reaperLib.reaperTypes.iniValue;
      default = {};
      example = literalExpression ''
        {
          explorer = "0.85531396 1";
          navigator = reaperLayout.dock.mainDocker;
        }
      '';
      description = ''
        Raw `[REAPERdockpref]` entries by REAPER window ID. This is the final
        escape hatch and overrides computed preferences from named dockers.
      '';
    };
  };

  config = {
    assertions =
      mapAttrsToList
      (windowId: dockerName: {
        assertion = builtins.hasAttr dockerName dockers;
        message = ''
          REAPER layout window `${windowId}` refers to unknown docker
          `${dockerName}`.
        '';
      })
      referencedDockers;

    programs.reaper.ini.sections = optionalAttrs (dockPreferences != {}) {
      REAPERdockpref = dockPreferences;
    };
  };
}
