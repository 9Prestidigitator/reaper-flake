# Internal Configuration Model

This document describes how the Home Manager module turns Nix options into a mutable REAPER resource directory. It is implementation documentation, not a list of user-facing preference options.

## Resource directory and activation

`programs.reaper.configPath` is the REAPER resource directory managed by the module. The packaged `reaper` wrapper starts REAPER with:

```text
-cfgfile <configPath>/reaper.ini
```

On Home Manager activation the module:

1. Creates the resource directory.
2. Seeds missing stock REAPER resources when `stockResources.enable` is true.
3. Links enabled extension and theme assets.
4. Merges generated INI and line-oriented configuration into the mutable
   resource directory.
5. Removes obsolete values previously owned by the module.

The generated files are intentionally **not** linked from `/nix/store`: REAPER updates many of its configuration files itself. The module manages only the values it owns and leaves the rest mutable.

By default, activation checks for a running `reaper` process and fails before changing the resource directory. Close REAPER and retry. The check can be explicitly bypassed with:

```nix
programs.reaper.activation.allowRunning = true;
```

This is an unsafe override: REAPER can write its in-memory configuration on exit and overwrite values activation just changed.

## Generated state

The module records the last values it managed under:

```text
<configPath>/.nix-managed/
```

This is a state directory, not REAPER input. It lets a later activation answer two important questions:

- Which keys or records did the previous Nix generation own?
- Has the user changed one of those values since that generation?

The state is what permits scoped cleanup rather than replacing an entire configuration file. Deleting `.nix-managed` is safe in the sense that REAPER will still run, but the next activation treats existing configuration as unmanaged and cannot remove stale entries from an earlier generation.

## INI files

Preference modules contribute internal values to one of these option trees:

```nix
programs.reaper.ini.sections.<section>.<key>
programs.reaper.ini.files.<file>.<section>.<key>
```

The first targets `reaper.ini`; the second targets another INI file such as `reaper-menu.ini` or `reapack.ini`. `modules/ini.nix` collects all contributions and creates an immutable JSON payload for each target. During activation, `scripts/write_config.py` applies that payload to the mutable file.

For every managed key, the writer:

1. Parses the target while preserving comments, blank lines, order, and
   unrecognised content.
2. Removes an old managed key only when the on-disk value still exactly equals
   the prior managed value.
3. Replaces the final occurrence of a currently managed key, or inserts the
   key into its section when missing.
4. Atomically replaces the target file and writes the new ownership state.

Step 2 is intentional: if a user changed a formerly Nix-managed value by hand or through REAPER, the module does not delete that changed value merely because the corresponding Nix option was removed.

### Values and lists

Nix booleans become `1` or `0`. Lists become semicolon-separated values, which matches REAPER's convention for settings such as path lists. Other supported INI values are rendered as strings.

### Bitfields

Several REAPER preferences share one integer INI key. Modules contribute `mask`/`value` pairs through:

```nix
programs.reaper.ini.bitfields.<section>.<key>
programs.reaper.ini.fileBitfields.<file>.<section>.<key>
```

At activation, the writer reads the current integer and applies each managed bitfield as:

```text
new = (old & ~mask) | (value & mask)
```

This allows independent Nix options to control separate bits without clobbering unmanaged bits in the same REAPER setting. Direct key/value assignments take precedence over a bitfield result for the same key.

### Removing sections

`programs.reaper.ini.removeSections.<file>` removes complete sections from non-`reaper.ini` targets. It is used where REAPER represents an entire feature as a section, such as a menu/toolbar customization. Section removal is explicit because it is broader than ordinary key ownership.

## Line-oriented files

Some REAPER files are ordered records rather than independent INI keys. For example, `reaper-kb.ini` contains `SCR`, `ACT`, and `KEY` records. These use:

```nix
programs.reaper.lineFiles.files.<file> = [ line1 line2 ... ];
```

Activation removes records owned by the prior generation, preserves all other lines, then appends the current generated lines. Exact duplicate lines are deduplicated while preserving their first occurrence.

`reaper-kb.ini` receives additional identity-aware cleanup:

- `SCR` records are replaced by section and command ID.
- `ACT` records are replaced by section and command ID.

This prevents an updated script or custom action from leaving an older record with the same REAPER identity behind. `KEY` records are managed as exact lines; the ordering of current generated bindings is preserved because REAPER resolves duplicate shortcuts by their final record.

## Whole resource files and links

`resourceFiles.files` installs generated whole files. `resourceLinks.files` symlinks immutable Nix-provided assets, such as theme archives, scripts, fonts, or extension resources. A file cannot be both generated and linked; the module asserts this conflict during evaluation.

For a link that would replace an existing user-owned regular file, activation refuses by default. Set `programs.reaper.resourceLinks.backupFileExtension` (or the equivalent Home Manager backup option) to request an explicit backup before replacement.

## Preference contributions

Preference modules should eventually emit normalized contributions through `programs.reaper.ini.contributions`. A contribution identifies the physical INI target and records its semantic source:

```nix
{
  kind = "value";
  section = "reaper";
  key = "somekey";
  value = config.programs.reaper.preferences.example;
  codec = "identity";
  optionPath = "preferences.example";
}
```

Bitfield contributions additionally provide `mask` and a masked `value`. Separate modules may contribute different masks to the same physical INI key; the reducer combines them before activation. Overlapping masks fail evaluation and report both source option paths. The module generates a schema for migrated contributions during Home Manager activation at `<configPath>/.nix-managed/reaper-flake-schema.json`. The `reaper2nix` app discovers that file automatically when given an INI from the same REAPER resource directory:

```console
nix run .#reaper2nix -- \
  /path/to/reaper-resource-directory
```

The argument may be either the REAPER resource directory or its `reaper.ini` file.

Use `--schema` as an escape hatch for another configuration directory or a hand-authored schema:

```console
nix run .#reaper2nix -- \
  --schema /path/to/generated-schema.json \
  /path/to/reaper.ini
```

The importer emits supported declarations and comments for unmapped or unsupported values. The schema is intentionally incremental while legacy preference producers are migrated.

To inspect other parseable INI files in a resource directory, opt in to raw imports:

```console
nix run .#reaper2nix -- --all-files \
  /path/to/reaper-resource-directory
```

This scans `*.ini` files besides `reaper.ini` and emits their unmapped values under `programs.reaper.ini.files`, while unmapped values from `reaper.ini` are placed under `programs.reaper.ini.sections`. The line-oriented `reaper-kb.ini` and `reaper-jsfx.ini` are emitted under `programs.reaper.lineFiles.files`. Values already represented by the generated schema are still emitted as their higher-level declarations. The raw form is intentionally opt-in: REAPER stores runtime state, window positions, recent files, and other user-specific data in these files, so blindly importing every key can make a configuration noisy and can replay state that should remain mutable.

For example, an entry from `reaper-menu.ini` is represented as:

```nix
programs.reaper = {
  ini.files."reaper-menu.ini"."Main file".item_0 = "40023 &New project";
};
```

This raw importer is a migration aid. It does not infer the richer `programs.reaper.menus`, `programs.reaper.actions`, or ReaPack schemas from arbitrary files; those need dedicated importers because their records have ordering and identity semantics beyond ordinary INI key/value pairs.

## Relevant implementation files

- `modules/ini.nix` — internal INI, bitfield, payload, and writer options.
- `scripts/write_config.py` — preservation-aware and atomic INI merge logic.
- `modules/line-files.nix` — generated line-file fragments.
- `modules/resources.nix` — generated resource-file and immutable-link
  ownership checks.
- `modules/default.nix` — activation ordering, state cleanup, and the REAPER
  launcher wrapper.
