{
  lib,
  pkgs,
  config,
  reaperLib,
  ...
}: let
  inherit (lib) concatMapStringsSep filter hasInfix hm literalExpression mkEnableOption mkIf mkOption optionalAttrs optionalString types unique;

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

  packageType = types.submodule {
    options = {
      repository = mkOption {
        type = types.str;
        example = "ReaTeam Scripts";
        description = "Repository display name containing the package.";
      };

      category = mkOption {
        type = types.str;
        example = "MIDI Editor";
        description = "Exact ReaPack category path containing the package.";
      };

      name = mkOption {
        type = types.str;
        example = "js_Mouse editing - Draw ramp.lua";
        description = "Exact package name from the repository index.";
      };

      version = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "1.2.3";
        description = "Exact package version, or null to install the latest eligible version.";
      };

      pin = mkOption {
        type = types.bool;
        default = false;
        description = "Pin the selected version in ReaPack after installation.";
      };

      enablePrereleases = mkOption {
        type = types.bool;
        default = false;
        description = "Allow the latest eligible version to be a pre-release and enable bleeding-edge updates for this package.";
      };
    };
  };

  customRepositories =
    if cfg.repositories == null
    then []
    else cfg.repositories;
  customRepositoryNames = map (repository: repository.name) customRepositories;

  managedRepositories =
    (
      if cfg.addDefaultRepositories
      then filter (repository: !(builtins.elem repository.name customRepositoryNames)) reaperLib.reapack.defaultRepositories
      else []
    )
    ++ customRepositories;

  repositoriesManaged = cfg.repositories != null || cfg.addDefaultRepositories;

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

  packageIdentity = package: "${package.repository}\t${package.category}\t${package.name}";
  packageIdentities = map packageIdentity (
    if cfg.packages == null
    then []
    else cfg.packages
  );
  badPackages =
    filter (package:
      hasInfix "\t" package.repository
      || hasInfix "\n" package.repository
      || hasInfix "\t" package.category
      || hasInfix "\n" package.category
      || hasInfix "\t" package.name
      || hasInfix "\n" package.name
      || (package.version != null && (hasInfix "\t" package.version || hasInfix "\n" package.version)))
    (
      if cfg.packages == null
      then []
      else cfg.packages
    );

  packageRequest = pkgs.writeText "reaper-flake-reapack-packages.tsv" (
    concatMapStringsSep "\n" (package: "${packageIdentity package}\t${optionalString (package.version != null) package.version}\t${
        if package.pin
        then "1"
        else "0"
      }\t${
        if package.enablePrereleases
        then "1"
        else "0"
      }")
    (
      if cfg.packages == null
      then []
      else cfg.packages
    )
    + optionalString (cfg.packages != null && cfg.packages != []) "\n"
  );

  # ReaPack has no standalone CLI, so synchronization and package transactions
  # run inside REAPER through the small API extension in packages/reapack.
  startupScript = pkgs.writeText "reaper-flake-reapack-startup.lua" ''
    local resource_path = reaper.GetResourcePath()
    local sync_request = resource_path .. "/ReaPack/.nix-sync-requested"
    local package_request = resource_path .. "/ReaPack/.nix-package-request"
    local managed_packages = resource_path .. "/ReaPack/.nix-managed-packages"

    local function exists(path)
      local file = io.open(path, "r")
      if not file then return false end
      file:close()
      return true
    end

    local synchronize_requested = exists(sync_request)
    local packages_requested = exists(package_request)
    if not synchronize_requested and not packages_requested then
      return
    end

    local attempts = 0
    local start
    local function wait_for_api()
      attempts = attempts + 1
      local required_apis = {
        "ReaPack_IsBusy",
        "ReaPack_QueuePackage",
        "ReaPack_QueueUninstallPackage",
      }
      local missing_apis = {}
      for _, name in ipairs(required_apis) do
        if not reaper.APIExists(name) then
          missing_apis[#missing_apis + 1] = name
        end
      end

      if #missing_apis == 0 then
        start()
        return
      elseif attempts < 500 then
        reaper.defer(wait_for_api)
        return
      end

      reaper.ShowMessageBox(
        "The configured ReaPack package does not provide reaper-flake's managed-package API:\n\n" ..
          table.concat(missing_apis, "\n"),
        "reaper-flake: ReaPack", 0)
    end

    local function fields(line)
      local result = {}
      for field in (line .. "\t"):gmatch("(.-)\t") do
        result[#result + 1] = field
      end
      return result
    end

    local function read_lines(path)
      local result = {}
      local file = io.open(path, "r")
      if not file then return result end
      for line in file:lines() do
        if line ~= "" then result[#result + 1] = fields(line) end
      end
      file:close()
      return result
    end

    local function identity(entry)
      return entry[1] .. "\t" .. entry[2] .. "\t" .. entry[3]
    end

    local desired = {}
    local desired_by_identity = {}

    local function load_desired()
      desired = read_lines(package_request)
      for _, entry in ipairs(desired) do
        desired_by_identity[identity(entry)] = true
      end
    end

    local function write_managed()
      local file = io.open(managed_packages, "w")
      if not file then return end
      for _, entry in ipairs(desired) do
        file:write(identity(entry), "\n")
      end
      file:close()
      os.remove(package_request)
    end

    local function wait_for_package_transaction()
      if reaper.ReaPack_IsBusy(false) then
        reaper.defer(wait_for_package_transaction)
      else
        write_managed()
      end
    end

    local function apply_packages()
      if not packages_requested then return end

      load_desired()
      local errors = {}

      for _, entry in ipairs(desired) do
        local ok, err = reaper.ReaPack_QueuePackage(
          entry[1], entry[2], entry[3], entry[4],
          entry[5] == "1", entry[6] == "1")
        if not ok then
          errors[#errors + 1] = identity(entry) .. ": " .. (err or "unknown error")
        end
      end

      for _, entry in ipairs(read_lines(managed_packages)) do
        if not desired_by_identity[identity(entry)] then
          local ok, err = reaper.ReaPack_QueueUninstallPackage(
            entry[1], entry[2], entry[3])
          if not ok then
            errors[#errors + 1] = identity(entry) .. ": " .. (err or "unknown error")
          end
        end
      end

      reaper.ReaPack_ProcessQueue(false)

      if #errors > 0 then
        reaper.ShowMessageBox(table.concat(errors, "\n"),
          "reaper-flake: ReaPack package errors", 0)
      else
        wait_for_package_transaction()
      end
    end

    local function wait_for_synchronize()
      if reaper.ReaPack_IsBusy(false) then
        reaper.defer(wait_for_synchronize)
      else
        apply_packages()
      end
    end

    start = function()
      if synchronize_requested then
        local command = reaper.NamedCommandLookup("_REAPACK_SYNC")
        if command and command ~= 0 then
          os.remove(sync_request)
          reaper.Main_OnCommand(command, 0)
          wait_for_synchronize()
        end
      else
        apply_packages()
      end
    end

    wait_for_api()
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

    addDefaultRepositories = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Add the default repositories shipped by ReaPack alongside any
        explicitly configured `repositories`. Custom repositories with the
        same name replace the corresponding default. Set to `false` to omit
        the built-in repositories.
      '';
    };

    repositories = mkOption {
      type = types.nullOr (types.listOf repositoryType);
      default = null;
      example = literalExpression "reaperLib.reapack.defaultRepositories";
      description = ''
        Additional ordered ReaPack repositories. These are appended after the
        built-in repositories when `addDefaultRepositories` is enabled.
        Setting a list writes ReaPack's `remoteN` entries and `size`.
      '';
    };

    packages = mkOption {
      type = types.nullOr (types.listOf packageType);
      default = null;
      example = literalExpression ''
        [
          {
            repository = "ReaTeam Scripts";
            category = "MIDI Editor";
            name = "js_Mouse editing - Draw ramp.lua";
          }
        ]
      '';
      description = ''
        Declaratively managed individual ReaPack packages, identified by the
        exact repository name, category path, and package name from the
        repository index. null leaves package installation unmanaged. A list
        installs or updates its entries and removes packages that were present
        in this option on a previous activation but are no longer listed.

        ReaPack performs the actual synchronization and transaction the next
        time REAPER starts. Files, checksums, action registration, registry
        updates, upgrades, and removals therefore use ReaPack's native engine.
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
      {
        assertion = badPackages == [];
        message = "Managed ReaPack package repository, category, name, and version values must not contain tabs or newlines.";
      }
      {
        assertion = builtins.length packageIdentities == builtins.length (unique packageIdentities);
        message = "Managed ReaPack packages must have unique repository/category/name identities.";
      }
    ];

    programs.reaper = {
      ini.files."reapack.ini" =
        {
          general = optionalAttrs repositoriesManaged {
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
        // optionalAttrs repositoriesManaged {
          remotes = repositoryLines // {size = builtins.length managedRepositories;};
        };

      resourceFiles.files = optionalAttrs (cfg.synchronizeOnActivation || cfg.packages != null) {
        "Scripts/reaper-flake/reapack-startup.lua" = startupScript;
      };

      lineFiles.files = optionalAttrs (cfg.synchronizeOnActivation || cfg.packages != null) {
        "Scripts/__startup.lua" = [
          ''pcall(dofile, reaper.GetResourcePath() .. "/Scripts/reaper-flake/reapack-startup.lua")''
        ];
      };
    };

    home.activation.reaperReapack = hm.dag.entryAfter ["reaper"] ''
      mkdir -p "$reaper_resource_path/ReaPack"
      ${optionalString (cfg.synchronizeOnActivation || cfg.packages != null) ''
        printf '%s\n' ${lib.escapeShellArg (concatMapStringsSep "," (repository: repository.name) managedRepositories)} > "$reaper_resource_path/ReaPack/.nix-sync-requested"
      ''}
      ${optionalString (!(cfg.synchronizeOnActivation || cfg.packages != null)) ''
        rm -f "$reaper_resource_path/ReaPack/.nix-sync-requested"
      ''}
      ${optionalString (cfg.packages != null) ''
        install -m 0600 ${lib.escapeShellArg packageRequest} "$reaper_resource_path/ReaPack/.nix-package-request"
      ''}
      ${optionalString (cfg.packages == null) ''
        rm -f "$reaper_resource_path/ReaPack/.nix-package-request"
      ''}
    '';
  };
}
