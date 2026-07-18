{
  lib,
  pkgs,
  config,
  reaperLib,
  ...
}: let
  inherit (lib) concatMapStringsSep filter hasInfix hm literalExpression mkEnableOption mkIf mkOption optionalAttrs optionalString types;

  cfg = config.programs.reaper.extensions.reapack;

  repositoryType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "ReaTeam Scripts";
        description = "Repository display name as stored by ReaPack.";
      };

      url = mkOption {
        type = types.str;
        example = "https://github.com/ReaTeam/ReaScripts/raw/master/index.xml";
        description = "ReaPack repository index URL.";
      };

      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the repository is enabled in ReaPack.";
      };

      installNewPackages = mkOption {
        type = types.enum (builtins.attrNames reaperLib.reapack.autoInstallValues);
        default = "global";
        description = ''
          Per-repository behavior for new packages during synchronization:
          `manual`, `always`, or `global` to obey the global ReaPack setting.
        '';
      };
    };
  };

  managedRepositories =
    if cfg.repositories == null
    then []
    else cfg.repositories;

  repositoryLine = index: repository: {
    "remote${toString index}" = "${repository.name}|${repository.url}|${toString (
      if repository.enable
      then 1
      else 0
    )}|${toString reaperLib.reapack.autoInstallValues.${repository.installNewPackages}}";
  };

  repositoryLines = builtins.foldl' (
    acc: index:
      acc // repositoryLine index (builtins.elemAt managedRepositories index)
  ) {} (builtins.genList (index: index) (builtins.length managedRepositories));

  badRepositories = filter (repository:
    hasInfix "|" repository.name
    || hasInfix "|" repository.url
    || hasInfix "\n" repository.name
    || hasInfix "\n" repository.url)
  managedRepositories;

  # ReaPack has no standalone CLI, so synchronization has to run inside REAPER.
  startupScript = pkgs.writeText "reaper-flake-reapack-startup.lua" ''
    local resource_path = reaper.GetResourcePath()
    local sync_request = resource_path .. "/ReaPack/.nix-sync-requested"

    local file = io.open(sync_request, "r")
    if not file then
      return
    end
    file:close()
    os.remove(sync_request)

    local attempts = 0
    local function synchronize()
      attempts = attempts + 1
      local command = reaper.NamedCommandLookup("_REAPACK_SYNC")
      if command and command ~= 0 then
        reaper.Main_OnCommand(command, 0)
      elseif attempts < 50 then
        reaper.defer(synchronize)
      end
    end

    synchronize()
  '';
in {
  options.programs.reaper.extensions.reapack = {
    enable = mkEnableOption "Enable the ReaPack extension in the config.";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../../packages/reapack {};
      defaultText = literalExpression "inputs.reaper-flake.packages.${pkgs.system}.reapack";
      description = "Package that provides ReaPack files under `UserPlugins`.";
    };

    repositories = mkOption {
      type = types.nullOr (types.listOf repositoryType);
      default = null;
      example = literalExpression "config.lib.reaper.reapack.defaultRepositories";
      description = ''
        Ordered ReaPack repositories. `null` leaves `[remotes]` unmanaged.
        Setting a list writes ReaPack's `remoteN` entries and `size`.
      '';
    };

    installNewPackagesWhenSynchronizing = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Global ReaPack option: install every new package from enabled
        repositories when synchronizing.
      '';
    };

    enablePrereleasesGlobally = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Global ReaPack option: allow synchronize/update to move from stable
        versions to pre-releases.
      '';
    };

    promptToUninstallObsoletePackages = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = ''
        Global ReaPack option: prompt before uninstalling packages removed from
        their parent repository.
      '';
    };

    browser.expandSynonyms = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Expand synonyms in the ReaPack package browser filter.";
    };

    network = {
      proxy = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://127.0.0.1:8080";
        description = "Proxy URL used by ReaPack downloads.";
      };

      verifyPeer = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Verify TLS peers for ReaPack downloads.";
      };

      refreshIndexCacheAfterSeconds = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 86400;
        description = ''
          Refresh cached repository indexes older than this many seconds. `0`
          disables age-based refresh attempts for offline use.
        '';
      };

      fallbackProxy = mkOption {
        type = types.nullOr (types.enum (builtins.attrNames reaperLib.reapack.fallbackProxyValues));
        default = null;
        example = "ask";
        description = ''
          Whether ReaPack may download through reapack.com when GitHub rate limits
          file download requests.
        '';
      };
    };

    synchronizeOnActivation = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Request `ReaPack: Synchronize packages` on the next REAPER startup after
        each Home Manager activation. The actual synchronization must run inside
        REAPER because ReaPack is a REAPER extension, not a standalone CLI.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = badRepositories == [];
        message = "ReaPack repository names and URLs must not contain `|` or newlines.";
      }
    ];

    programs.reaper = {
      ini.files."reapack.ini" =
        {
          general = optionalAttrs (cfg.repositories != null) {
            version = 4;
          };

          install =
            optionalAttrs (cfg.installNewPackagesWhenSynchronizing != null) {
              autoinstall = cfg.installNewPackagesWhenSynchronizing;
            }
            // optionalAttrs (cfg.enablePrereleasesGlobally != null) {
              prereleases = cfg.enablePrereleasesGlobally;
            }
            // optionalAttrs (cfg.promptToUninstallObsoletePackages != null) {
              promptobsolete = cfg.promptToUninstallObsoletePackages;
            };

          network =
            optionalAttrs (cfg.network.proxy != null) {
              proxy = cfg.network.proxy;
            }
            // optionalAttrs (cfg.network.verifyPeer != null) {
              verifypeer = cfg.network.verifyPeer;
            }
            // optionalAttrs (cfg.network.refreshIndexCacheAfterSeconds != null) {
              stalethreshold = cfg.network.refreshIndexCacheAfterSeconds;
            }
            // optionalAttrs (cfg.network.fallbackProxy != null) {
              fallbackproxy = reaperLib.reapack.fallbackProxyValues.${cfg.network.fallbackProxy};
            };

          browser = optionalAttrs (cfg.browser.expandSynonyms != null) {
            synonyms = cfg.browser.expandSynonyms;
          };
        }
        // optionalAttrs (cfg.repositories != null) {
          remotes = repositoryLines // {size = builtins.length managedRepositories;};
        };

      resourceFiles.files = optionalAttrs cfg.synchronizeOnActivation {
        "Scripts/reaper-flake/reapack-startup.lua" = startupScript;
      };

      lineFiles.files = optionalAttrs cfg.synchronizeOnActivation {
        "Scripts/__startup.lua" = [
          ''pcall(dofile, reaper.GetResourcePath() .. "/Scripts/reaper-flake/reapack-startup.lua")''
        ];
      };

      home.activation.reaperReapack = hm.dag.entryAfter ["reaper"] ''
        mkdir -p "$reaper_resource_path/ReaPack"
        ${optionalString cfg.synchronizeOnActivation ''
          printf '%s\n' ${lib.escapeShellArg (concatMapStringsSep "," (repository: repository.name) managedRepositories)} > "$reaper_resource_path/ReaPack/.nix-sync-requested"
        ''}
        ${optionalString (!cfg.synchronizeOnActivation) ''
          rm -f "$reaper_resource_path/ReaPack/.nix-sync-requested"
        ''}
      '';
    };
  };
}
