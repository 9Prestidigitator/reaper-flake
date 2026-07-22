# ReaPack

`programs.reaper.extensions.reapack` installs ReaPack, configures its
repositories and preferences, optionally synchronizes on activation, and can
declaratively install individual packages.

```nix
programs.reaper.extensions.reapack = {
  enable = true;

  repositories = [
    {
      name = "reaper-keys";
      url = "https://raw.githubusercontent.com/gwatcha/reaper-keys/master/index.xml";
    }
  ];

  packages = [
    {
      repository = "MPL Scripts";
      category = "FX";
      name = "mpl_Toggle bypass FX with latency (PDC) higher than X samples.lua";
    }
  ];

  promptToUninstallObsoletePackages = true;
  synchronizeOnActivation = true;
};
```

Package changes are applied when REAPER next starts. ReaPack has no standalone
command-line interface, so Home Manager writes a request and REAPER processes it
through ReaPack's native transaction engine.

## Extension package

### `enable`

Enables ReaPack and links the extension into the REAPER resource directory.

```nix
programs.reaper.extensions.reapack.enable = true;
```

### `package`

Selects the package that supplies the files under `UserPlugins`.

```nix
programs.reaper.extensions.reapack.package =
  inputs.reaper-flake.packages.${pkgs.system}.reapack;
```

The default is this flake's ReaPack package, built from the latest packaged
Codeberg release for Linux and macOS. It includes a small patch that exposes
ReaPack's transaction engine to the generated startup script.

An unmodified upstream ReaPack binary still supports normal interactive
ReaPack use and INI configuration, but it does not provide the managed-package
APIs required by `packages`. The current startup runner also checks these APIs
when only `synchronizeOnActivation` is enabled, so use the flake's patched build
for either automated workflow.

## Repositories

### Default repositories

`addDefaultRepositories` defaults to `true`. The following repositories are
added before custom repositories:

| Name               | Index URL                                                              |
| ------------------ | ---------------------------------------------------------------------- |
| ReaPack            | `https://reapack.com/index.xml`                                        |
| ReaTeam Scripts    | `https://github.com/ReaTeam/ReaScripts/raw/master/index.xml`           |
| ReaTeam JSFX       | `https://github.com/ReaTeam/JSFX/raw/master/index.xml`                 |
| ReaTeam Themes     | `https://github.com/ReaTeam/Themes/raw/master/index.xml`               |
| ReaTeam LangPacks  | `https://github.com/ReaTeam/LangPacks/raw/master/index.xml`            |
| ReaTeam Extensions | `https://github.com/ReaTeam/Extensions/raw/master/index.xml`           |
| MPL Scripts        | `https://github.com/MichaelPilyavskiy/ReaScripts/raw/master/index.xml` |
| X-Raym Scripts     | `https://github.com/X-Raym/REAPER-ReaScripts/raw/master/index.xml`     |

Disable this behavior with:

```nix
programs.reaper.extensions.reapack.addDefaultRepositories = false;
```

The interaction between `addDefaultRepositories` and `repositories` is:

| Configuration                                            | Result                                    |
| -------------------------------------------------------- | ----------------------------------------- |
| `addDefaultRepositories = true; repositories = null;`    | Manage the default repositories.          |
| `addDefaultRepositories = true; repositories = [ ... ];` | Defaults followed by custom repositories. |
| `addDefaultRepositories = false; repositories = null;`   | Leave the repository list unmanaged.      |
| `addDefaultRepositories = false; repositories = [];`     | Manage an empty repository list.          |

A custom repository with the same `name` as a default replaces that default.
This can be used to change its URL, enabled state, or auto-install policy.

### Custom repositories

```nix
repositories = [
  {
    name = "My Scripts";
    url = "https://example.org/reapack/index.xml";
    enable = true;
    installNewPackages = "manual";
  }
];
```

Each repository supports:

- `name`: exact display name stored by ReaPack. Required.
- `url`: repository index URL. Required.
- `enable`: whether ReaPack synchronizes the repository. Defaults to `true`.
- `installNewPackages`: behavior for packages newly added to the repository.
  Defaults to `global` and accepts:
  - `manual`: do not automatically install new packages;
  - `always`: automatically install new packages from this repository;
  - `global`: follow `installNewPackagesWhenSynchronizing`.

Repository names and URLs cannot contain `|` or newlines because ReaPack uses
those characters to encode its repository records.

If the goal is a precise set of individually declared packages, keep repository
auto-install set to `manual` or `global` with the global auto-install option
disabled. Packages installed by ReaPack's broad auto-install feature are not
automatically added to the Nix managed-package ledger.

## Individual packages

### Declaration

```nix
packages = [
  {
    repository = "ReaTeam Scripts";
    category = "MIDI Editor";
    name = "js_Mouse editing - Draw ramp.lua";

    version = null;
    pin = false;
    enablePrereleases = false;
  }
];
```

Each package supports:

- `repository`: exact configured repository name. Required.
- `category`: exact category path from the repository index. Required.
- `name`: exact `<reapack name="...">` value from the index. Required.
- `version`: exact version, or `null` for the latest eligible version. Defaults
  to `null`.
- `pin`: set ReaPack's pinned flag on the selected version. Defaults to `false`.
- `enablePrereleases`: permit selecting a prerelease and enable ReaPack's
  bleeding-edge flag for this package. Defaults to `false`.

The `(repository, category, name)` tuple must be unique in the list. Package
fields cannot contain tabs or newlines because the activation request is
tab-separated.

One package may install many files or register many actions. Declare the
package's index identity, not one of its `<source file="...">` entries.

### `null` versus an empty list

These have intentionally different meanings:

```nix
packages = null;
```

Disables declarative package management. Existing packages are left installed.
This is the default.

```nix
packages = [];
```

Enables declarative package management with an empty desired set. Packages
previously managed through this option are removed on the next REAPER start.
Unrelated packages installed manually remain untouched.

If a manually installed package is later added to `packages`, it becomes part
of the managed set. Removing that declaration later will uninstall it.

### Versions and pinning

The common combinations are:

| Declaration                       | Behavior                                                              |
| --------------------------------- | --------------------------------------------------------------------- |
| `version = null; pin = false;`    | Install the latest stable version and allow normal ReaPack updates.   |
| `version = null; pin = true;`     | Select the latest eligible version and pin it in ReaPack.             |
| `version = "1.2.3"; pin = false;` | Request version `1.2.3`, while allowing later normal ReaPack updates. |
| `version = "1.2.3"; pin = true;`  | Install and pin exactly version `1.2.3`.                              |

For a reproducibly fixed declaration, specify both an exact version and
`pin = true`.

`pin = true` with `version = null` does not permanently lock the Nix
declaration. A later Home Manager activation resolves "latest" again and may
advance the pinned version before pinning the new selection.

### Finding a package identity

The reliable source is ReaPack's synchronized repository cache:

```text
<REAPER resource path>/ReaPack/cache/
```

With the default flake configuration path this is normally:

```text
~/.config/reaper-flake/ReaPack/cache/
```

Each XML filename corresponds to a configured repository. Search all indexes
with context:

```bash
rg -ni -C 5 'part of the package name' \
  ~/.config/reaper-flake/ReaPack/cache/*.xml
```

For example:

```xml
<category name="FX">
  <reapack
    name="mpl_Toggle bypass FX with latency (PDC) higher than X samples.lua"
    desc="Toggle bypass FX with latency (PDC) higher than X samples">
```

This becomes:

```nix
{
  repository = "MPL Scripts";
  category = "FX";
  name = "mpl_Toggle bypass FX with latency (PDC) higher than X samples.lua";
}
```

Use these values:

- repository: configured repository name, normally the XML filename without
  `.xml`;
- category: enclosing `<category name="...">` value;
- name: exact `<reapack name="...">` value.

Do not substitute:

- `desc`, which is package-browser display text;
- a `<source file="...">`, which is one installed file;
- an action name displayed by REAPER;
- a shortened name with prefixes or file extensions removed.

Synchronize ReaPack before inspecting the cache so the indexes are current.

## Synchronization

### `synchronizeOnActivation`

```nix
programs.reaper.extensions.reapack.synchronizeOnActivation = true;
```

This writes a synchronization request during every Home Manager activation.
The next REAPER startup invokes `ReaPack: Synchronize packages` and removes the
request once synchronization starts.

Setting `packages` to any list, including `[]`, also requests synchronization
before package operations. Individual package declarations therefore do not
require `synchronizeOnActivation = true`.

Activation does not run ReaPack itself. REAPER must start before synchronization
and package changes can occur.

## Install and update policy

### `installNewPackagesWhenSynchronizing`

Global policy for packages newly added to enabled repositories:

```nix
installNewPackagesWhenSynchronizing = false;
```

The option is nullable. `null` leaves the corresponding setting unmanaged.
Repositories whose `installNewPackages = "global"` follow this value.

### `enablePrereleasesGlobally`

Controls whether normal ReaPack synchronization may move installed packages
from stable releases to prereleases:

```nix
enablePrereleasesGlobally = false;
```

This is distinct from a package declaration's `enablePrereleases`, which
controls selection and the bleeding-edge flag for that individual package.

### `promptToUninstallObsoletePackages`

Controls whether ReaPack prompts before removing installed packages that have
been removed from their parent repository:

```nix
promptToUninstallObsoletePackages = true;
```

This concerns packages made obsolete by repository synchronization. Removal
from the declarative `packages` list is an explicit managed transaction and
does not use this prompt.

All three policy options default to `null`.

## Package browser

### `browser.expandSynonyms`

Controls synonym expansion in ReaPack's package-browser filter:

```nix
browser.expandSynonyms = true;
```

It defaults to `null`.

## Network options

### `network.proxy`

Sets the proxy URL used for downloads:

```nix
network.proxy = "http://127.0.0.1:8080";
```

It defaults to `null`.

### `network.verifyPeer`

Controls TLS peer verification:

```nix
network.verifyPeer = true;
```

It defaults to `null`. Disabling peer verification weakens download security
and should only be used for a specifically understood environment.

### `network.refreshIndexCacheAfterSeconds`

Sets how old a cached index may be before ReaPack attempts to refresh it:

```nix
network.refreshIndexCacheAfterSeconds = 86400;
```

`0` disables age-based refresh attempts for offline use. The option defaults to
`null`.

### `network.fallbackProxy`

Controls whether ReaPack may use reapack.com as a fallback when GitHub rate
limits file downloads:

```nix
network.fallbackProxy = "ask";
```

Accepted values are:

- `disable`;
- `enable`;
- `ask`.

It defaults to `null`.

## Activation and runtime lifecycle

Home Manager writes persistent ReaPack preferences to `reapack.ini`. When
synchronization or package management is enabled, it also installs:

```text
Scripts/reaper-flake/reapack-startup.lua
Scripts/__startup.lua
```

The activation and startup sequence is:

1. Home Manager writes repository and preference configuration.
2. It creates `.nix-sync-requested` when synchronization is required.
3. A non-null `packages` value is serialized to `.nix-package-request`.
4. On the next REAPER start, the startup script waits for ReaPack's APIs.
5. ReaPack synchronizes enabled repositories.
6. The script queues declared installs and upgrades.
7. It queues removals that were in the previous managed set but are no longer
   declared.
8. ReaPack processes the transaction without an interactive completion dialog.
9. After the transaction finishes, the script writes `.nix-managed-packages`
   and removes the package request.

The files under `ReaPack/` have separate responsibilities:

| File                    | Owner and purpose                                                                        |
| ----------------------- | ---------------------------------------------------------------------------------------- |
| `registry.db`           | ReaPack's authoritative installed-package registry. Never edited directly by the module. |
| `cache/*.xml`           | Synchronized repository indexes owned by ReaPack.                                        |
| `.nix-sync-requested`   | One-shot synchronization request written by Home Manager.                                |
| `.nix-package-request`  | Desired package transaction waiting for REAPER startup.                                  |
| `.nix-managed-packages` | Identities successfully adopted by declarative package management.                       |

Nix declares desired state and schedules work. ReaPack remains responsible for
downloads, checksums, file placement, action registration, upgrades, rollback,
its SQLite registry, and removals.

Home Manager activation normally refuses to modify the REAPER resource
directory while REAPER is running. Close REAPER before rebuilding, or review
the risks before setting `programs.reaper.activation.allowRunning = true`.

## Why the patched ReaPack build is necessary

Upstream ReaPack exposes repository configuration and package inspection to
ReaScript, but it does not expose package installation and uninstallation, and
there is no standalone ReaPack CLI. Editing `registry.db` directly would bypass
downloads, checksums, action registration, file cleanup, transaction rollback,
and ReaPack's schema invariants.

The patch in `packages/reapack/managed-packages-api.patch` adds narrow
ReaScript APIs that:

- queue an exact package/version through ReaPack's native transaction engine;
- queue removal of an installed package identity;
- report whether a transaction is still running;
- permit noninteractive transactions without the completion report dialog.

The generated startup script combines these APIs with upstream's existing
`ReaPack_ProcessQueue` function. The same patched source is compiled into the
Linux shared object and macOS dylib.

## Troubleshooting

### `package not found`

The repository loaded successfully, but `(category, name)` did not exactly
match an index entry. Inspect the repository XML and use `<reapack name="...">`,
not `desc`. Prefixes such as `mpl_` and extensions such as `.lua` are part of
the identity.

### `repository not found`

The declaration's `repository` does not exactly match a configured repository
name. Check spelling, capitalization, `addDefaultRepositories`, and custom
repository names.

### `repository index is unavailable`

ReaPack could not load the repository's synchronized index. Confirm the
repository is enabled and reachable, then synchronize again.

### `package version not found`

The exact `version` is absent from the current repository index. Inspect the
package's `<version name="...">` entries or set `version = null`.

### Missing managed-package API

If the startup dialog lists `ReaPack_IsBusy`, `ReaPack_QueuePackage`, or
`ReaPack_QueueUninstallPackage`, the configured extension is an unpatched
upstream build. Remove the `package` override or select this flake's
`packages.${pkgs.system}.reapack` output.

### A rejected request reappears at every startup

The package request is deliberately retained after a lookup or queueing error.
Correct the declaration, close REAPER, activate the new configuration, and
start REAPER again. A completed transaction removes the request.

### A package was not removed

Only identities recorded in `.nix-managed-packages` are removed when omitted.
Packages installed interactively or by repository-wide auto-install remain
outside the declarative set unless they were later adopted through `packages`.
