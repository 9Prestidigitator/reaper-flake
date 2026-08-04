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
- Which masks within a shared bitfield key did it own?
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

The ownership state records the aggregate mask managed for every bitfield key. When a previously managed option becomes null or is removed, the writer computes and clears only the released mask:

```text
releasedMask = previousMask & ~currentMask
new = (old & ~(releasedMask | currentMask)) | (value & currentMask)
```

REAPER's default value for an individual bit is zero, so clearing the released mask restores the default for those options while preserving every bit Nix never owned. A bitfield option that has always been null has no previous mask and therefore does not alter the existing key. Ownership-state version 1 did not distinguish direct keys from resolved bitfield values; it is migrated conservatively to the mask-aware version 2 format after one activation.

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

Bitfield contributions additionally provide `mask` and a masked `value`. Separate modules may contribute different masks to the same physical INI key; the reducer combines them before activation. Overlapping masks fail evaluation and report both source option paths.

Contribution records exist even when their public option is unset. Their `configured` field determines whether they participate in the forward INI writer, while every record remains available to the reverse schema. This keeps the `reaper2nix` vocabulary independent of the configuration used to build the app.

## Adding a GUI preference mapping

A supported preference has one source of truth for both directions: its INI contribution. Do not add a direct `ini.sections` assignment when the setting should round-trip through `reaper2nix`, because direct assignments write the file but do not provide reverse-schema metadata.

### Discover the encoding

Use an isolated REAPER resource directory and change only one GUI control at a time (git is very useful for this):

1. Record the original file, section, key, and value.
2. Change the GUI control, close REAPER cleanly, and compare the files.
3. Repeat for every user-facing enum or compound state.
4. For a bitfield, XOR the before and after integers to identify candidate bits, then test all states to determine the complete mask.
5. Restart REAPER and verify that the value is persistent configuration rather than transient runtime state.

The resulting mapping should identify the public option path and type, physical file, INI section and key, encoding or mask, inversion rules, and the corresponding GUI label.

### Define the public option

Preferences should normally be nullable and default to `null`. Null means that the flake knows about the option but it is not part of the current generation's managed values:

```nix
options.programs.reaper.preferences.audio.example.enable =
  reaperPreference.option {
    type = types.nullOr types.bool;
    default = null;
    example = true;
    description = "Whether the example feature is enabled.";
  };
```

The static schema still contains the contribution when this option is null. An option that has always been null leaves the existing INI value untouched. Transitioning a previously managed whole-key option to null invokes safe stale-key cleanup; transitioning a previously managed bitfield option to null clears its formerly owned mask to zero.

### Whole-key values

Register an independently encoded value with `reaperPreference.contributions`:

```nix
config.programs.reaper.ini.contributions =
  reaperPreference.contributions [
    {
      path = "preferences.audio.example.enable";
      value = cfg.enable;
      section = "reaper";
      key = "example_enable";
      codec = "bool";
      gui = "Enable example feature";
    }
  ];
```

Contribution paths are relative to `programs.reaper`. `file` defaults to `reaper.ini`; set it explicitly for another INI file. A contributed file is automatically added to the schema source allowlist.

Use the codec that describes the public value and its stored representation:

| Public value | Codec                      | Stored representation                 |
| ------------ | -------------------------- | ------------------------------------- |
| String       | `"identity"`               | Unmodified string                     |
| Boolean      | `"bool"`                   | `0` or `1`                            |
| Integer      | `"integer"`                | Decimal integer                       |
| Float        | `"float"`                  | Decimal number                        |
| String list  | `"list"`                   | Semicolon-separated values            |
| Named enum   | `reaperCodecs.enum values` | Name mapped to an INI value           |
| Decibels     | `{ type = "decibels"; }`   | REAPER linear amplitude decoded as dB |

Named enums should normally expose readable strings. Use the attribute names as the option type and the same mapping as the codec:

```nix
let
  modes = {
    disabled = 0;
    automatic = 1;
    always = 2;
  };
in {
  options.programs.reaper.preferences.audio.example.mode = mkOption {
    type = types.nullOr (types.enum (builtins.attrNames modes));
    default = null;
  };

  config.programs.reaper.ini.contributions =
    reaperPreference.contributions [
      {
        path = "preferences.audio.example.mode";
        value = cfg.mode;
        section = "reaper";
        key = "example_mode";
        codec = reaperCodecs.enum modes;
        gui = "Example mode";
      }
    ];
}
```

If the public interface intentionally exposes REAPER's raw encoded values, use a numeric option type with the `integer` codec (or `valueType = "integer"` for a bitfield) instead of a named enum reverse mapping.

### Bitfields

Use `reaperBitfield.contributions` when multiple settings occupy independent masks in one integer key. A normal boolean bit needs only `bit`; `inverted = true` means that a set bit represents false:

```nix
config.programs.reaper.ini.contributions =
  map
  (entry: entry // { section = "reaper"; })
  (reaperBitfield.contributions {
    exampleflags = [
      {
        optionPath = "preferences.audio.example.enable";
        option = cfg.enable;
        bit = 8;
        inverted = true;
        gui = "Enable example feature";
      }
    ];
  });
```

For a boolean with a multi-bit or nonstandard encoding, provide its exact mask and values:

```nix
{
  optionPath = "preferences.audio.example.enable";
  option = cfg.enable;
  mask = 14;
  trueValue = 6;
  falseValue = 8;
}
```

For a named bitfield enum, provide both the forward value and reverse mapping:

```nix
{
  optionPath = "preferences.audio.example.mode";
  option = cfg.mode;
  mask = 48;
  value = modes.${cfg.mode};
  importValues = modes;
}
```

A genuinely numeric masked field can set `valueType = "integer"`. Use `ignoredValues` for encoded states that mean the public option should remain unset.

When one encoded state controls multiple public options, use `importAssignments`:

```nix
{
  optionPath = "preferences.audio.example.freeMode";
  configured = cfg.freeMode != null || cfg.fixedMode != null;
  mask = 12;
  value =
    if cfg.fixedMode or false
    then 8
    else if cfg.freeMode or false
    then 4
    else 0;
  importAssignments = {
    "0" = {
      "preferences.audio.example.freeMode" = false;
      "preferences.audio.example.fixedMode" = false;
    };
    "4" = {
      "preferences.audio.example.freeMode" = true;
      "preferences.audio.example.fixedMode" = false;
    };
    "8" = {
      "preferences.audio.example.freeMode" = false;
      "preferences.audio.example.fixedMode" = true;
    };
  };
}
```

Always declare the full mask owned by the GUI control. The INI reducer rejects overlapping contributions and the activation writer preserves all unmanaged bits.

### Codecs, adapters, and module imports

Add a codec when one value has a local reversible transformation, such as unit conversion or serialization. Implement the forward encoder in `modules/lib/codecs.nix`, the reverse decoder in `scripts/reaper2nix.py`, and add a round-trip test.

Use a semantic adapter instead when decoding requires relationships between multiple keys or records, dynamic identities, an ordered line format, or a non-INI structure. Databases should remain unsupported unless they have a stable public representation and can be changed safely; knowing a database field is not sufficient justification for managing it.

If the option is placed in a new module, ensure that module is reachable through both the runtime imports in `modules/default.nix` and the configuration-independent evaluation in `modules/schema.nix`. Prefer adding it beneath a directory-level module imported by both.

### Validation

Test both directions:

1. Set the Nix option, activate it, and inspect the resulting INI value or masked bits.
2. Confirm unrelated bits in a shared key remain unchanged.
3. Change the option in REAPER, close REAPER, and run `reaper2nix`.
4. Confirm the generated declaration uses the intended public path and user-facing value.
5. Apply that declaration and verify the same state appears in REAPER.

Run the repository checks before committing:

```console
python3 -m unittest discover -s tests -v
nix flake check
git diff --check
```

The flake bundles this static schema into `reaper2nix` and exposes it as the `reaper-schema` package. Home Manager also installs the schema at `<configPath>/.nix-managed/reaper-flake-schema.json`. An explicit `--schema` takes precedence; otherwise the bundled schema is used.

```console
nix run .#reaper2nix -- \
  /path/to/reaper-resource-directory
```

The argument may be either the REAPER resource directory or its `reaper.ini` file.

Use `--options` to emit only one public option or subtree while preserving its full nesting in the generated expression. The path must begin with `programs.reaper`:

```console
nix run .#reaper2nix -- \
  --options programs.reaper.preferences \
  /path/to/reaper-resource-directory
```

The flag is repeatable when several independent subtrees are wanted. It also accepts an exact leaf such as `programs.reaper.preferences.general.undo.maximumUndoMemory`. Selecting a parent includes all generated descendants; options absent from the current REAPER configuration simply produce no matching output.

Use `--schema` as an escape hatch for another configuration directory or a hand-authored schema:

```console
nix run .#reaper2nix -- \
  --schema /path/to/generated-schema.json \
  /path/to/reaper.ini
```

The importer emits supported declarations and diagnostics when a schema-backed value cannot be decoded. Unmapped keys are silent because the schema is intentionally a proper subset of REAPER's state-bearing files. Pass `--show-unmapped` when developing new mappings and you need those keys reported.

VST, LV2, and CLAP search paths use the schema's list codec. Each effective path value consists of the explicit `searchPaths` list followed by paths enabled through that plug-in type's `enableNixPaths` and `enableUserPaths` options. `reaper2nix` emits the effective semicolon-separated INI value as `searchPaths` without classifying its entries, then sets both appenders to false so activating the generated configuration reproduces that exact list.

Generated output is a complete Nix attribute set. Public option paths are expanded into nested attribute sets, ordered records remain lists, and attribute names are quoted only when Nix syntax requires it. The output is formatted so it passes Alejandra without another rewrite.

The schema also contains a source catalog. A resource-directory import opens only files declared in that catalog; it never discovers inputs with an `*.ini` glob. Consequently, cache, window-position, recent-item, and other state files without a Nix mapping are skipped completely. A single-file import is narrower still and does not import supported sibling files.

Each non-INI structure has a named adapter. The first line-file adapter decodes `SCR`, `ACT`, and `KEY` records from `reaper-kb.ini` into `programs.reaper.actions.scripts`, `customActions`, and `keyBindings`. Unknown record types remain unmanaged instead of being copied into raw line options.

`reaper-menu.ini` combines the ordinary INI reader with the `reaper-menu` semantic adapter. The source's `adapterConfig` carries the known section kinds and REAPER toolbar text-icon spellings from `reaperLib.reaperMenus`, keeping the forward module and reverse importer synchronized. The adapter numerically orders indexed records, reconstructs nested submenus, and maps `icon_N` and `tbf_N` metadata onto toolbar entries. REAPER's generated `default` fingerprint is consumed as state rather than exposed as an option. Structurally invalid sections produce diagnostics and are not emitted.

`reaper-mouse.ini` combines the ordinary INI reader with the `reaper-mouse` semantic adapter. The adapter converts true entries in `[hasimported]` into `preferences.editingBehavior.mouseModifiers.importedContexts` and dynamically maps `MM_CTX_*` sections and `mm_*` keys into structured `contexts` bindings. Numeric action IDs become integers, named command IDs remain strings, and an optional mode suffix is preserved. Valid zero-valued import markers are consumed but omitted. Unknown keys and malformed values remain unconsumed so `--show-unmapped` can diagnose them and `--all-keys` can preserve them.

ReaPack uses two semantic adapters. The `reapack` adapter decodes preferences and ordered repository records from `reapack.ini`. The `reapack-packages` adapter reads the versioned `ReaPack/reaper-flake-state.json` snapshot exported by the patched extension and emits `extensions.reapack.packages`. It never opens `registry.db`; SQLite remains an implementation detail owned by ReaPack. Unpinned packages use `version = null` unless the importer is invoked with `--reapack-exact-versions`.

A physical source can also declare additional semantic adapters. `reaper.ini` uses this to combine ordinary preference mappings with the layout adapter. The layout adapter imports the first-class main window, mixer, master mixer, transport, docker topology, selected tabs, edge sizes, and `[REAPERdockpref]` values under `programs.reaper.layout`. It deliberately leaves unrelated editor and extension window state unmanaged.

To inspect unmapped keys inside the schema-declared INI sources, opt in to raw imports:

```console
nix run .#reaper2nix -- --all-keys /path/to/reaper-resource-directory
```

This does not broaden the source allowlist. It only emits unmapped values from already-declared INI sources under `programs.reaper.ini`; files absent from the schema still are not opened. The raw form is intentionally opt-in because even a configuration-bearing file may contain runtime state alongside settings.

Future ordered formats should receive dedicated adapters that emit their public semantic options. They should not be copied wholesale into `programs.reaper.lineFiles`, because ordering, identity, and ownership semantics differ between formats.

## Relevant implementation files

- `modules/ini.nix` — internal INI, bitfield, payload, and writer options.
- `modules/schema.nix` — configuration-independent schema evaluation.
- `scripts/reaper2nix.py` — schema allowlist and reverse-format adapters.
- `scripts/write_config.py` — preservation-aware and atomic INI merge logic.
- `modules/line-files.nix` — generated line-file fragments.
- `modules/resources.nix` — generated resource-file and immutable-link
  ownership checks.
- `modules/default.nix` — activation ordering, state cleanup, and the REAPER
  launcher wrapper.
