#!/usr/bin/env python3
"""Convert supported REAPER INI values into reaper-flake declarations."""

import argparse
import configparser
import json
import math
import os
import re
import shlex
from pathlib import Path
from typing import Any


def decode(codec: Any, value: str) -> Any:
    if codec in (None, "identity"):
        return value
    if codec == "bool":
        return value not in ("0", "false", "False", "")
    if codec == "integer":
        return int(value)
    if codec == "float":
        return float(value)
    if codec == "list":
        return value.split(";") if value else []
    if isinstance(codec, dict) and codec.get("type") == "decibels":
        return 20 * math.log10(float(value))
    if isinstance(codec, dict) and codec.get("type") == "enum":
        for name, encoded in codec["values"].items():
            if str(encoded) == value:
                return name
        raise ValueError(f"unknown enum value {value!r}")
    raise ValueError(f"unsupported codec {codec!r}")


NIX_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_'-]*$")
NIX_KEYWORDS = {
    "assert",
    "else",
    "if",
    "in",
    "inherit",
    "let",
    "or",
    "rec",
    "then",
    "with",
}


def nix_attr_name(value: str) -> str:
    if NIX_IDENTIFIER_RE.match(value) and value not in NIX_KEYWORDS:
        return value
    return nix(value)


def nix(value: Any, indent: int = 0) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("Nix output cannot represent a non-finite float")
        return repr(value)
    if isinstance(value, str):
        if any(ord(character) < 32 and character not in "\n\r\t" for character in value):
            raise ValueError("Nix output cannot represent control characters")
        escaped = (
            value.replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("${", "\\${")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
        )
        return f'"{escaped}"'
    if isinstance(value, list):
        if not value:
            return "[]"
        compact = "[" + " ".join(nix(item, indent) for item in value) + "]"
        if all(not isinstance(item, (dict, list)) for item in value) and len(compact) <= 88:
            return compact
        child_indent = "  " * (indent + 1)
        return (
            "[\n"
            + "\n".join(f"{child_indent}{nix(item, indent + 1)}" for item in value)
            + f"\n{'  ' * indent}]"
        )
    if isinstance(value, dict):
        if not value:
            return "{}"
        child_indent = "  " * (indent + 1)
        entries = "\n".join(
            f"{child_indent}{nix_attr_name(str(key))} = {nix(item, indent + 1)};"
            for key, item in value.items()
        )
        return f"{{\n{entries}\n{'  ' * indent}}}"
    raise TypeError(f"unsupported Nix value {value!r}")


def set_path(tree: dict[str, Any], path: list[str], value: Any) -> None:
    """Set a leaf in the nested output tree without flattening Nix paths."""

    current = tree
    for component in path[:-1]:
        existing = current.setdefault(component, {})
        if not isinstance(existing, dict):
            raise ValueError(f"Nix output path conflicts at {component!r}")
        current = existing
    leaf = path[-1]
    if leaf in current and current[leaf] != value:
        raise ValueError(f"Nix output path has conflicting values: {'.'.join(path)}")
    current[leaf] = value


def merge_tree(target: dict[str, Any], incoming: dict[str, Any], path: str = "") -> None:
    """Recursively merge semantic adapters while rejecting conflicting leaves."""

    for key, value in incoming.items():
        current_path = f"{path}.{key}" if path else key
        if key not in target:
            target[key] = value
        elif isinstance(target[key], dict) and isinstance(value, dict):
            merge_tree(target[key], value, current_path)
        elif target[key] != value:
            raise ValueError(f"Nix output path has conflicting values: {current_path}")


def normalize_option_filter(value: str) -> tuple[str, ...]:
    """Convert a public option path to its path below ``programs.reaper``."""

    components = tuple(value.split("."))
    if any(not component for component in components):
        raise ValueError(f"invalid option path {value!r}")
    root = ("programs", "reaper")
    if components[: len(root)] != root:
        raise ValueError(
            f"option path must start with {'.'.join(root)}: {value!r}"
        )
    return components[len(root) :]


def select_option_subtrees(
    tree: dict[str, Any], selectors: list[tuple[str, ...]]
) -> dict[str, Any]:
    """Select exact leaves or subtrees while retaining their full Nix paths."""

    # A selected ancestor already contains every descendant. Removing redundant
    # descendants also prevents insertion order from affecting the merge.
    minimal: list[tuple[str, ...]] = []
    for selector in sorted(set(selectors), key=lambda item: (len(item), item)):
        if not any(selector[: len(parent)] == parent for parent in minimal):
            minimal.append(selector)

    if () in minimal:
        return tree

    selected: dict[str, Any] = {}
    for selector in minimal:
        current: Any = tree
        for component in selector:
            if not isinstance(current, dict) or component not in current:
                break
            current = current[component]
        else:
            set_path(selected, list(selector), current)
    return selected


def schema_sources(schema: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Return the curated physical files understood by this schema.

    Version 1 schemas did not have an explicit source table, so retain a
    compatibility path that derives INI sources from their option mappings.
    """

    sources = schema.get("sources")
    if isinstance(sources, dict):
        return {
            str(file_name): source
            for file_name, source in sources.items()
            if isinstance(source, dict)
        }

    return {
        str(option.get("file", "reaper.ini")): {
            "format": "ini",
            "adapter": "ini",
        }
        for option in schema.get("options", [])
        if isinstance(option, dict)
    }


def source_adapters(source: dict[str, Any]) -> list[str]:
    """Return all import adapters declared for a physical source."""

    adapters: list[str] = []
    adapter = source.get("adapter")
    if isinstance(adapter, str):
        adapters.append(adapter)
    for additional in source.get("adapters", []):
        if isinstance(additional, str) and additional not in adapters:
            adapters.append(additional)
    return adapters


def ini_files(
    resource_dir: Path, file_names: list[str]
) -> dict[str, configparser.ConfigParser]:
    """Read the INI files in a REAPER resource directory.

    REAPER has a few line-oriented files which are deliberately not parsed
    here.  The files that are valid INI files can still be imported as raw
    ``programs.reaper.ini`` declarations when ``--all-keys`` is requested.
    """

    paths = [resource_dir / file_name for file_name in sorted(set(file_names))]

    result: dict[str, configparser.ConfigParser] = {}
    for path in paths:
        if not path.is_file():
            continue
        parser = configparser.ConfigParser(
            interpolation=None, delimiters=("=",), strict=False
        )
        parser.optionxform = str
        try:
            parser.read(path)
        except configparser.Error as error:
            print(f"# Could not parse {path.name}: {error}")
            continue
        result[path.name] = parser
    return result


def line_file(resource_dir: Path, file_name: str) -> list[str]:
    path = resource_dir / file_name
    if not path.is_file():
        return []
    return [line.rstrip("\n") for line in path.read_text().splitlines() if line.strip()]


INTEGER_RE = re.compile(r"^-?[0-9]+$")


def command_value(value: str) -> int | str:
    if INTEGER_RE.match(value):
        return int(value)
    return value


MENU_ITEM_RE = re.compile(r"^item_([0-9]+)$")
MENU_ICON_RE = re.compile(r"^icon_([0-9]+)$")
MENU_FLAGS_RE = re.compile(r"^tbf_([0-9]+)$")
FLOATING_TOOLBAR_RE = re.compile(r"^Floating toolbar ([1-9]|[12][0-9]|3[0-2])$")
FLOATING_MIDI_TOOLBAR_RE = re.compile(r"^Floating MIDI toolbar ([1-9]|1[0-6])$")


def parse_reaper_menu(
    current_ini: configparser.ConfigParser,
    adapter_config: dict[str, Any] | None = None,
) -> tuple[dict[str, Any], set[tuple[str, str]], list[str]]:
    """Decode ``reaper-menu.ini`` into public menu and toolbar options."""

    config = adapter_config or {}
    section_kinds = config.get("sectionKinds", {})
    if not isinstance(section_kinds, dict):
        section_kinds = {}
    text_icons = config.get("toolbarTextIcons", {})
    if not isinstance(text_icons, dict):
        text_icons = {}
    text_icon_modes = {
        text_icons.get("normal", "text"): ("textIcon", "normal"),
        text_icons.get("wide", "text_wide"): ("textIcon", "wide"),
        text_icons.get("tooltip", "text_tt"): ("useTextAsTooltip", True),
    }

    decoded: dict[str, Any] = {}
    consumed: set[tuple[str, str]] = set()
    diagnostics: list[str] = []

    for section in current_ini.sections():
        items: dict[int, tuple[str, str]] = {}
        icons: dict[int, tuple[str, str]] = {}
        flags: dict[int, tuple[str, str]] = {}
        title: str | None = None
        recognized: set[tuple[str, str]] = set()

        for key, value in current_ini.items(section):
            item_match = MENU_ITEM_RE.match(key)
            icon_match = MENU_ICON_RE.match(key)
            flags_match = MENU_FLAGS_RE.match(key)
            if item_match:
                items[int(item_match.group(1))] = (key, value)
                recognized.add((section, key))
            elif icon_match:
                icons[int(icon_match.group(1))] = (key, value)
                recognized.add((section, key))
            elif flags_match:
                flags[int(flags_match.group(1))] = (key, value)
                recognized.add((section, key))
            elif key == "title":
                title = value
                recognized.add((section, key))
            elif key == "default":
                # REAPER owns this generated default-menu fingerprint. It is
                # intentionally not represented by a public Nix option.
                recognized.add((section, key))

        if not items and title is None:
            consumed.update(recognized)
            continue

        known_kind = section_kinds.get(section)
        dynamic_toolbar = bool(
            FLOATING_TOOLBAR_RE.match(section)
            or FLOATING_MIDI_TOOLBAR_RE.match(section)
        )
        inferred_toolbar = bool(icons or flags or "toolbar" in section.lower())
        kind = known_kind or ("toolbar" if dynamic_toolbar or inferred_toolbar else "menu")
        fatal: list[str] = []

        orphan_indices = sorted((set(icons) | set(flags)) - set(items))
        for index in orphan_indices:
            diagnostics.append(
                f"# reaper-menu.ini [{section}]: toolbar metadata has no item_{index}"
            )

        root_entries: list[dict[str, Any]] = []
        entry_stack: list[list[dict[str, Any]]] = [root_entries]

        for index in sorted(items):
            _, raw_item = items[index]
            command, separator, label = raw_item.strip().partition(" ")
            label = label.lstrip() if separator else None
            if not command:
                fatal.append(f"item_{index} has no command")
                continue

            action = command_value(command)
            metadata: dict[str, Any] = {}
            if index in icons and icons[index][1]:
                icon_value = icons[index][1]
                mapped_icon = text_icon_modes.get(icon_value)
                if mapped_icon is None:
                    metadata["icon"] = icon_value
                else:
                    metadata[mapped_icon[0]] = mapped_icon[1]
            if index in flags:
                flag_value = flags[index][1]
                try:
                    parsed_flags = int(flag_value)
                    if parsed_flags < 0:
                        raise ValueError
                    metadata["toolbarFlags"] = parsed_flags
                except ValueError:
                    fatal.append(f"tbf_{index} is not an unsigned integer: {flag_value!r}")

            if metadata and kind != "toolbar":
                fatal.append(f"item_{index} has toolbar metadata in a {kind} section")

            if action == -3:
                if label:
                    fatal.append(f"item_{index} submenu terminator has a label")
                if metadata:
                    fatal.append(f"item_{index} submenu terminator has toolbar metadata")
                if len(entry_stack) == 1:
                    fatal.append(f"item_{index} closes a submenu that is not open")
                else:
                    entry_stack.pop()
                continue

            if action == -2:
                if kind == "toolbar":
                    fatal.append(f"item_{index} opens a submenu in a toolbar")
                if not label:
                    fatal.append(f"item_{index} submenu has no label")
                if metadata:
                    fatal.append(f"item_{index} submenu has toolbar metadata")
                entry = {"label": label, "entries": []}
                entry_stack[-1].append(entry)
                entry_stack.append(entry["entries"])
                continue

            if action == -1:
                if label:
                    fatal.append(f"item_{index} separator has a label")
                if metadata:
                    fatal.append(f"item_{index} separator has toolbar metadata")
                entry_stack[-1].append({"separator": True})
                continue

            if action == -4:
                if not label:
                    fatal.append(f"item_{index} disabled entry has no label")
                if metadata:
                    fatal.append(f"item_{index} disabled entry has toolbar metadata")
                entry_stack[-1].append({"disabled": True, "label": label})
                continue

            entry = {"action": action}
            if label is not None:
                entry["label"] = label
            entry.update(metadata)
            entry_stack[-1].append(entry)

        if len(entry_stack) != 1:
            fatal.append(f"{len(entry_stack) - 1} submenu(s) are not closed")

        if fatal:
            diagnostics.extend(
                f"# reaper-menu.ini [{section}]: {message}" for message in fatal
            )
            continue

        menu: dict[str, Any] = {"entries": root_entries}
        if title is not None:
            menu["title"] = title
        if known_kind is None and not dynamic_toolbar and kind != "menu":
            menu["kind"] = kind
        decoded[section] = menu
        consumed.update(recognized)

    return decoded, consumed, diagnostics


def parse_reaper_kb(lines: list[str]) -> tuple[dict[str, list[Any]], list[str]]:
    """Decode supported reaper-kb.ini records into public action options."""

    scripts: dict[tuple[int, str], dict[str, Any]] = {}
    custom_actions: dict[tuple[int, str], dict[str, Any]] = {}
    key_bindings: list[dict[str, Any]] = []
    diagnostics: list[str] = []

    for line_number, line in enumerate(lines, 1):
        record, _, comment = line.partition("#")
        try:
            fields = shlex.split(record, comments=False, posix=True)
        except ValueError as error:
            diagnostics.append(f"# reaper-kb.ini:{line_number}: {error}")
            continue
        if not fields:
            continue

        try:
            if fields[0] == "SCR" and len(fields) >= 6:
                flags = int(fields[1])
                section = int(fields[2])
                command_id = fields[3]
                description = fields[4]
                path = " ".join(fields[5:])
                if Path(path).is_absolute():
                    location = "absolute"
                elif path.startswith("Scripts/"):
                    location = "scripts"
                    path = path.removeprefix("Scripts/")
                else:
                    location = "scripts"
                scripts[(section, command_id)] = {
                    "flags": flags,
                    "section": section,
                    "commandId": command_id,
                    "description": description,
                    "path": path,
                    "location": location,
                }
            elif fields[0] == "ACT" and len(fields) >= 6:
                flags = int(fields[1])
                section = int(fields[2])
                command_id = fields[3]
                description = fields[4]
                if flags & ~3:
                    diagnostics.append(
                        f"# reaper-kb.ini:{line_number}: unsupported ACT flags {flags}"
                    )
                    continue
                custom_actions[(section, command_id)] = {
                    "name": description.removeprefix("Custom: "),
                    "description": description,
                    "commandId": command_id,
                    "section": section,
                    "actions": [command_value(value) for value in fields[5:]],
                    "consolidateUndoPoints": bool(flags & 1),
                    "showInActionsMenu": bool(flags & 2),
                }
            elif fields[0] == "KEY" and len(fields) == 5:
                key_bindings.append(
                    {
                        "modifierFlags": int(fields[1]),
                        "keyCode": int(fields[2]),
                        "command": command_value(fields[3]),
                        "section": int(fields[4]),
                        "comment": comment.strip() or None,
                    }
                )
        except ValueError as error:
            diagnostics.append(f"# reaper-kb.ini:{line_number}: {error}")

    decoded: dict[str, list[Any]] = {}
    if scripts:
        decoded["scripts"] = list(scripts.values())
    if custom_actions:
        decoded["customActions"] = list(custom_actions.values())
    if key_bindings:
        decoded["keyBindings"] = key_bindings
    return decoded, diagnostics


def parse_reapack_ini(
    current_ini: configparser.ConfigParser,
) -> tuple[dict[str, Any], set[tuple[str, str]], list[str]]:
    """Decode ReaPack preferences and its ordered repository records."""

    decoded: dict[str, Any] = {}
    consumed: set[tuple[str, str]] = set()
    diagnostics: list[str] = []

    def raw(section: str, key: str) -> str | None:
        if current_ini.has_section(section) and current_ini.has_option(section, key):
            consumed.add((section, key))
            return current_ini.get(section, key)
        return None

    def boolean(section: str, key: str) -> bool | None:
        value = raw(section, key)
        if value is None:
            return None
        try:
            return int(value) != 0
        except ValueError:
            diagnostics.append(f"# Could not decode ReaPack boolean: [{section}] {key}={value}")
            return None

    def integer(section: str, key: str) -> int | None:
        value = raw(section, key)
        if value is None:
            return None
        try:
            return int(value)
        except ValueError:
            diagnostics.append(f"# Could not decode ReaPack integer: [{section}] {key}={value}")
            return None

    option_values: list[tuple[list[str], Any]] = []
    for section, key, path in [
        ("install", "autoinstall", ["installNewPackagesWhenSynchronizing"]),
        ("install", "prereleases", ["enablePrereleasesGlobally"]),
        ("install", "promptobsolete", ["promptToUninstallObsoletePackages"]),
        ("browser", "synonyms", ["browser", "expandSynonyms"]),
        ("network", "verifypeer", ["network", "verifyPeer"]),
    ]:
        value = boolean(section, key)
        if value is not None:
            option_values.append((path, value))

    proxy = raw("network", "proxy")
    if proxy is not None:
        option_values.append((["network", "proxy"], proxy))
    stale_threshold = integer("network", "stalethreshold")
    if stale_threshold is not None:
        option_values.append((["network", "refreshIndexCacheAfterSeconds"], stale_threshold))
    fallback_proxy = integer("network", "fallbackproxy")
    if fallback_proxy is not None:
        fallback_values = {0: "disable", 1: "enable", 2: "ask"}
        if fallback_proxy in fallback_values:
            option_values.append((["network", "fallbackProxy"], fallback_values[fallback_proxy]))
        else:
            diagnostics.append(
                f"# Unknown ReaPack fallback proxy value: [network] fallbackproxy={fallback_proxy}"
            )

    for path, value in option_values:
        set_path(decoded, path, value)

    if current_ini.has_section("remotes"):
        size = integer("remotes", "size")
        if size is not None:
            repositories: list[dict[str, Any]] = []
            auto_install_values = {0: "manual", 1: "always", 2: "global"}
            for index in range(size):
                key = f"remote{index}"
                value = raw("remotes", key)
                if value is None:
                    diagnostics.append(f"# Missing ReaPack repository record: [remotes] {key}")
                    continue
                fields = value.split("|")
                if len(fields) != 4:
                    diagnostics.append(f"# Malformed ReaPack repository record: [remotes] {key}={value}")
                    continue
                try:
                    enabled = int(fields[2]) != 0
                    auto_install = auto_install_values[int(fields[3])]
                except (KeyError, ValueError):
                    diagnostics.append(f"# Malformed ReaPack repository record: [remotes] {key}={value}")
                    continue
                repositories.append(
                    {
                        "name": fields[0],
                        "url": fields[1],
                        "enable": enabled,
                        "installNewPackages": auto_install,
                    }
                )
            decoded["addDefaultRepositories"] = False
            decoded["repositories"] = repositories

    return decoded, consumed, diagnostics


def parse_reapack_packages(
    resource_dir: Path, snapshot_path: Path, exact_versions: bool = False
) -> tuple[dict[str, Any], list[str]]:
    """Decode the stable snapshot exported by the patched ReaPack extension."""

    diagnostics: list[str] = []
    if not snapshot_path.is_file():
        if (resource_dir / "reapack.ini").is_file():
            diagnostics.append(
                "# ReaPack package snapshot is missing; start REAPER once before importing packages."
            )
        return {}, diagnostics

    try:
        snapshot = json.loads(snapshot_path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        return {}, [f"# Could not read ReaPack package snapshot: {error}"]

    if not isinstance(snapshot, dict) or snapshot.get("formatVersion") != 1:
        return {}, [
            f"# Unsupported ReaPack package snapshot version: {snapshot.get('formatVersion') if isinstance(snapshot, dict) else None!r}"
        ]

    snapshot_resource = snapshot.get("resourcePath")
    if isinstance(snapshot_resource, str):
        try:
            if Path(snapshot_resource).resolve() != resource_dir.resolve():
                diagnostics.append(
                    "# ReaPack package snapshot belongs to a different resource directory."
                )
        except OSError:
            pass

    registry_path = resource_dir / "ReaPack/registry.db"
    registry_modified = snapshot.get("registryModifiedAt")
    if registry_path.is_file() and isinstance(registry_modified, (int, float)):
        if registry_path.stat().st_mtime > registry_modified + 1:
            diagnostics.append(
                "# ReaPack package snapshot is older than registry.db; start REAPER to refresh it."
            )

    raw_packages = snapshot.get("packages")
    if not isinstance(raw_packages, list):
        return {}, [*diagnostics, "# ReaPack package snapshot has no valid packages list."]

    packages: list[dict[str, Any]] = []
    identities: set[tuple[str, str, str]] = set()
    for index, raw_package in enumerate(raw_packages):
        if not isinstance(raw_package, dict):
            diagnostics.append(f"# Invalid ReaPack package snapshot entry {index}.")
            continue
        repository = raw_package.get("repository")
        category = raw_package.get("category")
        name = raw_package.get("name")
        version = raw_package.get("version")
        flags = raw_package.get("flags")
        if not all(isinstance(value, str) for value in [repository, category, name, version]) or not isinstance(flags, int):
            diagnostics.append(f"# Invalid ReaPack package snapshot entry {index}.")
            continue
        identity = (repository, category, name)
        if identity == ("ReaPack", "Extensions", "ReaPack.ext"):
            continue
        if identity in identities:
            diagnostics.append(
                "# Duplicate ReaPack package snapshot identity: " + " / ".join(identity)
            )
            continue
        identities.add(identity)
        if flags & ~3:
            diagnostics.append(
                f"# Unknown ReaPack registry flags {flags & ~3} for " + " / ".join(identity)
            )
        pinned = bool(flags & 1)
        packages.append(
            {
                "repository": repository,
                "category": category,
                "name": name,
                "version": version if exact_versions or pinned else None,
                "pin": pinned,
                "enablePrereleases": bool(flags & 2),
            }
        )

    packages.sort(key=lambda package: (package["repository"], package["category"], package["name"]))
    return {"packages": packages}, diagnostics


def parse_reaper_layout(
    current_ini: configparser.ConfigParser,
) -> tuple[dict[str, Any], set[tuple[str, str]], list[str]]:
    """Decode the curated, declaratively representable parts of reaper.ini.

    Layout files contain both durable layout choices and transient UI state.
    This adapter intentionally consumes only keys represented by the public
    ``programs.reaper.layout`` options.
    """

    decoded: dict[str, Any] = {}
    consumed: set[tuple[str, str]] = set()
    diagnostics: list[str] = []

    def raw(section: str, key: str) -> str | None:
        if current_ini.has_section(section) and current_ini.has_option(section, key):
            consumed.add((section, key))
            return current_ini.get(section, key)
        return None

    def integer(section: str, key: str) -> int | None:
        value = raw(section, key)
        if value is None:
            return None
        try:
            return int(value)
        except ValueError:
            diagnostics.append(f"# Could not decode layout value: [{section}] {key}={value}")
            return None

    def boolean(section: str, key: str) -> bool | None:
        value = integer(section, key)
        return None if value is None else value != 0

    def window(
        section: str,
        *,
        x: str,
        y: str,
        width: str,
        height: str,
        visible: str | None = None,
        docked: str | None = None,
        maximized: str | None = None,
        state: str | None = None,
        dock_position: str | None = None,
    ) -> dict[str, Any]:
        result: dict[str, Any] = {}
        x_value, y_value = integer(section, x), integer(section, y)
        if x_value is not None and y_value is not None:
            result["position"] = {"x": x_value, "y": y_value}
        width_value, height_value = integer(section, width), integer(section, height)
        if width_value is not None and height_value is not None:
            result["size"] = {"width": width_value, "height": height_value}
        if visible is not None:
            value = boolean(section, visible)
            if value is not None:
                result["visible"] = value
        if docked is not None:
            value = boolean(section, docked)
            if value is not None:
                result["docked"] = value
        if maximized is not None:
            value = boolean(section, maximized)
            if value is not None:
                result["maximized"] = value
        if state is not None:
            value = integer(section, state)
            if value is not None:
                result["state"] = value
        if dock_position is not None:
            value = integer(section, dock_position)
            if value is not None:
                result["dockPosition"] = value
        return result

    fixed_windows = {
        "mainWindow": window(
            "reaper", x="wnd_x", y="wnd_y", width="wnd_w", height="wnd_h", state="wnd_state"
        ),
        "mixer": window(
            "reaper",
            x="mixwnd_x",
            y="mixwnd_y",
            width="mixwnd_w",
            height="mixwnd_h",
            visible="mixwnd_vis",
            docked="mixwnd_dock",
            maximized="mixwnd_max",
        ),
        "masterMixer": window(
            "mastermixer",
            x="wnd_left",
            y="wnd_top",
            width="wnd_width",
            height="wnd_height",
            visible="wnd_vis",
            docked="dock",
            maximized="wnd_max",
        ),
        "transport": window(
            "reaper",
            x="transport_x",
            y="transport_y",
            width="transport_w",
            height="transport_h",
            visible="transport_vis",
            docked="transport_dock",
            maximized="transport_max",
            dock_position="transport_dock_pos",
        ),
    }
    decoded.update({name: value for name, value in fixed_windows.items() if value})

    reaper_values = current_ini["reaper"] if current_ini.has_section("reaper") else {}
    dock_ids = sorted(
        {
            int(match.group(1))
            for key in reaper_values
            if (match := re.fullmatch(r"docker(?:mode|sel)([0-9]+)", key))
        }
    )
    modes: dict[int, int | None] = {
        dock_id: integer("reaper", f"dockermode{dock_id}") for dock_id in dock_ids
    }
    positions = {0: "bottom", 1: "left", 2: "top", 3: "right"}
    position_counts = {
        position: sum(1 for mode in modes.values() if positions.get(mode) == position)
        for position in positions.values()
    }
    size_keys = {
        "bottom": "dockheight",
        "left": "dockheight_l",
        "right": "dockheight_r",
        "top": "dockheight_t",
    }
    docks: dict[str, Any] = {}
    for dock_id in dock_ids:
        mode = modes[dock_id]
        position = positions.get(mode)
        name = position if position is not None and position_counts[position] == 1 else f"dock{dock_id}"
        dock: dict[str, Any] = {"id": dock_id}
        if position is not None:
            dock["position"] = position
        elif mode is not None:
            dock["mode"] = mode
        selected = raw("reaper", f"dockersel{dock_id}")
        if selected is not None:
            dock["selectedPanel"] = selected
        if position is not None:
            size = integer("reaper", size_keys[position])
            if size is not None and size > 0:
                dock["size"] = size
        docks[name] = dock
    if docks:
        decoded["docks"] = docks

    if current_ini.has_section("REAPERdockpref"):
        dock_preferences = {
            key: raw("REAPERdockpref", key)
            for key in current_ini["REAPERdockpref"]
        }
        decoded["dockPreferences"] = {
            key: value for key, value in dock_preferences.items() if value is not None
        }

    return decoded, consumed, diagnostics


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("ini", type=Path)
    parser.add_argument(
        "--schema",
        type=Path,
        help="Schema JSON to use instead of automatic discovery.",
    )
    parser.add_argument(
        "--all-keys",
        action="store_true",
        help=(
            "Also emit unmapped values from schema-declared INI sources. "
            "Files absent from the schema are never scanned."
        ),
    )
    parser.add_argument(
        "--show-unmapped",
        action="store_true",
        help="Report keys in supported INI files which have no schema mapping.",
    )
    parser.add_argument(
        "--reapack-exact-versions",
        action="store_true",
        help=(
            "Emit every installed ReaPack package version instead of only "
            "preserving versions for pinned packages."
        ),
    )
    parser.add_argument(
        "--options",
        action="append",
        default=[],
        metavar="OPTION_PATH",
        help=(
            "Emit only this option or subtree. Paths must start with "
            "programs.reaper; repeat the flag to select multiple subtrees."
        ),
    )
    args = parser.parse_args()

    try:
        option_filters = [
            normalize_option_filter(value) for value in args.options
        ]
    except ValueError as error:
        parser.error(str(error))

    input_is_directory = args.ini.is_dir()
    resource_dir = args.ini if input_is_directory else args.ini.parent
    if not input_is_directory and not args.ini.is_file():
        parser.error(f"INI file not found: {args.ini}")

    schema_path = args.schema
    if schema_path is None:
        candidates = [
            Path(os.environ["REAPER_FLAKE_SCHEMA"])
            for _ in [0]
            if os.environ.get("REAPER_FLAKE_SCHEMA")
        ]
        candidates += [
            resource_dir / ".nix-managed/reaper-flake-schema.json",
            resource_dir / "reaper-flake-schema.json",
        ]
        schema_path = next((path for path in candidates if path.is_file()), None)

    if schema_path is None:
        parser.error(
            "no schema found; run Home Manager activation first or pass "
            "--schema /path/to/reaper-flake-schema.json"
        )

    schema = json.loads(schema_path.read_text())
    sources = schema_sources(schema)
    selected_sources = (
        sources
        if input_is_directory
        else ({args.ini.name: sources[args.ini.name]} if args.ini.name in sources else {})
    )
    ini_source_names = [
        file_name
        for file_name, source in selected_sources.items()
        if source.get("format") == "ini" and "ini" in source_adapters(source)
    ]
    inis = ini_files(resource_dir, ini_source_names)

    emitted: list[tuple[str, Any]] = []
    bitfields: dict[tuple[str, str, str], int] = {}
    reported: set[tuple[str, str, str]] = set()

    def report(identity: tuple[str, str, str], message: str) -> None:
        if identity not in reported:
            print(message)
            reported.add(identity)

    for option in schema.get("options", []):
        file_name = option.get("file", "reaper.ini")
        current_ini = inis.get(file_name)
        if current_ini is None:
            continue
        section = option["section"]
        key = option["key"]
        if not current_ini.has_section(section) or not current_ini.has_option(section, key):
            continue
        raw = current_ini.get(section, key)
        identity = (file_name, section, key)

        if option["kind"] == "bitfield":
            bitfields.setdefault(identity, int(raw.split(":", 1)[0]))
            encoded = bitfields[identity]
            mask = option.get("mask", 0)
            masked = encoded & mask

            if option.get("valueType") == "bool":
                true_value = option.get("trueValue", mask)
                false_value = option.get("falseValue", 0)
                if masked == true_value:
                    emitted.append((option["path"], True))
                elif masked == false_value:
                    emitted.append((option["path"], False))
                else:
                    report(identity, f"# Unsupported boolean bitfield value {masked}: [{section}] {key}")
                continue

            if option.get("valueType") == "enum" and option.get("importValues"):
                if masked in option.get("ignoredValues", []):
                    continue
                name = next(
                    (name for name, value in option["importValues"].items() if int(value) == masked),
                    None,
                )
                if name is not None:
                    emitted.append((option["path"], name))
                else:
                    report(identity, f"# Unknown enum value {masked}: [{section}] {key}")
                continue

            if option.get("valueType") == "integer":
                emitted.append((option["path"], masked))
                continue

            if option.get("valueType") == "assignments":
                assignments = option.get("importAssignments", {}).get(str(masked))
                if assignments is not None:
                    emitted.extend(assignments.items())
                else:
                    report(identity, f"# Unknown composite value {masked}: [{section}] {key}")
                continue

            report(identity, f"# Unsupported bitfield: [{section}] {key}")
            continue

        try:
            value = decode(option.get("codec"), raw)
        except ValueError as error:
            report(identity, f"# Could not decode {option['path']}: {error}")
            continue
        emitted.append((option["path"], value))

    semantic_collections: dict[str, Any] = {}
    semantically_consumed: set[tuple[str, str, str]] = set()
    for file_name, source in sorted(selected_sources.items()):
        adapters = source_adapters(source)
        for adapter in adapters:
            if adapter == "ini":
                continue
            if adapter == "reaper-layout":
                current_ini = inis.get(file_name)
                if current_ini is None:
                    continue
                decoded, consumed, diagnostics = parse_reaper_layout(current_ini)
                for diagnostic in diagnostics:
                    print(diagnostic)
                if decoded:
                    merge_tree(semantic_collections, {"layout": decoded})
                semantically_consumed.update(
                    (file_name, section, key) for section, key in consumed
                )
            elif adapter == "reaper-kb":
                lines = line_file(resource_dir, file_name)
                if not lines:
                    continue
                decoded, diagnostics = parse_reaper_kb(lines)
                for diagnostic in diagnostics:
                    print(diagnostic)
                if decoded:
                    merge_tree(semantic_collections, {"actions": decoded})
            elif adapter == "reaper-menu":
                current_ini = inis.get(file_name)
                if current_ini is None:
                    continue
                decoded, consumed, diagnostics = parse_reaper_menu(
                    current_ini,
                    source.get("adapterConfig"),
                )
                for diagnostic in diagnostics:
                    print(diagnostic)
                if decoded:
                    merge_tree(semantic_collections, {"menus": decoded})
                semantically_consumed.update(
                    (file_name, section, key) for section, key in consumed
                )
            elif adapter == "reapack":
                current_ini = inis.get(file_name)
                if current_ini is None:
                    continue
                decoded, consumed, diagnostics = parse_reapack_ini(current_ini)
                for diagnostic in diagnostics:
                    print(diagnostic)
                if decoded:
                    merge_tree(
                        semantic_collections,
                        {"extensions": {"reapack": decoded}},
                    )
                semantically_consumed.update(
                    (file_name, section, key) for section, key in consumed
                )
            elif adapter == "reapack-packages":
                decoded, diagnostics = parse_reapack_packages(
                    resource_dir,
                    resource_dir / file_name,
                    exact_versions=args.reapack_exact_versions,
                )
                for diagnostic in diagnostics:
                    print(diagnostic)
                if decoded:
                    merge_tree(
                        semantic_collections,
                        {"extensions": {"reapack": decoded}},
                    )
            else:
                print(f"# Unsupported source adapter {adapter!r}: {file_name}")

    known = {
        (item.get("file", "reaper.ini"), item["section"], item["key"])
        for item in schema.get("options", [])
    } | semantically_consumed
    raw_declarations: list[tuple[list[str], str]] = []
    for file_name, current_ini in inis.items():
        for section in current_ini.sections():
            for key in current_ini[section]:
                identity = (file_name, section, key)
                if identity in known:
                    continue
                raw = current_ini[section][key]
                if args.all_keys:
                    if file_name == "reaper.ini":
                        target = ["ini", "sections", section, key]
                    else:
                        target = ["ini", "files", file_name, section, key]
                    raw_declarations.append((target, raw))
                elif args.show_unmapped:
                    report(
                        identity,
                        f"# Unmapped INI value: {file_name} [{section}] "
                        f"{key}={raw}",
                    )

    output: dict[str, Any] = {}
    for path, value in sorted(emitted, key=lambda entry: entry[0]):
        set_path(output, path.split("."), value)
    merge_tree(output, semantic_collections)
    for path, value in sorted(raw_declarations, key=lambda entry: entry[0]):
        set_path(output, path, value)

    if option_filters:
        output = select_option_subtrees(output, option_filters)

    if output:
        if raw_declarations and "ini" in output:
            print("# Raw INI imports are included; review runtime/state values before enabling them.")
        print("{")
        print(f"  programs.reaper = {nix(output, indent=1)};")
        print("}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
