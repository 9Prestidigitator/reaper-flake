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
    ``programs.reaper.ini`` declarations when ``--all-files`` is requested.
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
        "--all-files",
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
    args = parser.parse_args()

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
                    semantic_collections["layout"] = decoded
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
                    semantic_collections["actions"] = decoded
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
                if args.all_files:
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
    for collection, value in sorted(semantic_collections.items()):
        set_path(output, [collection], value)
    for path, value in sorted(raw_declarations, key=lambda entry: entry[0]):
        set_path(output, path, value)

    if output:
        if raw_declarations:
            print("# Raw INI imports are included; review runtime/state values before enabling them.")
        print("{")
        print(f"  programs.reaper = {nix(output, indent=1)};")
        print("}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
