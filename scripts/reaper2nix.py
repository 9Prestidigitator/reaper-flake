#!/usr/bin/env python3
"""Convert supported REAPER INI values into reaper-flake declarations."""

import argparse
import configparser
import json
import math
import os
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


def nix(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(value)


def ini_files(resource_dir: Path, include_all: bool) -> dict[str, configparser.ConfigParser]:
    """Read the INI files in a REAPER resource directory.

    REAPER has a few line-oriented files which are deliberately not parsed
    here.  The files that are valid INI files can still be imported as raw
    ``programs.reaper.ini`` declarations when ``--all-files`` is requested.
    """

    paths = [resource_dir / "reaper.ini"]
    if include_all:
        paths = sorted(
            path
            for path in resource_dir.glob("*.ini")
            if path.name not in {"reaper-kb.ini", "reaper-jsfx.ini"}
        )

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
            "Scan every parseable INI file in the resource directory and "
            "emit unmapped keys as raw programs.reaper.ini declarations."
        ),
    )
    args = parser.parse_args()

    resource_dir = args.ini if args.ini.is_dir() else args.ini.parent
    if args.ini.is_dir():
        args.ini = args.ini / "reaper.ini"
    if not args.ini.is_file():
        parser.error(f"INI file not found: {args.ini}")

    schema_path = args.schema
    if schema_path is None:
        candidates = [
            Path(os.environ["REAPER_FLAKE_SCHEMA"])
            for _ in [0]
            if os.environ.get("REAPER_FLAKE_SCHEMA")
        ]
        candidates += [
            args.ini.parent / ".nix-managed/reaper-flake-schema.json",
            args.ini.parent / "reaper-flake-schema.json",
        ]
        schema_path = next((path for path in candidates if path.is_file()), None)

    if schema_path is None:
        parser.error(
            "no schema found; run Home Manager activation first or pass "
            "--schema /path/to/reaper-flake-schema.json"
        )

    schema = json.loads(schema_path.read_text())
    inis = ini_files(resource_dir, args.all_files)
    ini = inis.get("reaper.ini")
    if ini is None:
        parser.error(f"could not read reaper.ini from {resource_dir}")

    emitted: list[tuple[str, str]] = []
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
                    emitted.append((option["path"], f"  {option['path']} = true;"))
                elif masked == false_value:
                    emitted.append((option["path"], f"  {option['path']} = false;"))
                else:
                    report(identity, f"# Unsupported boolean bitfield value {masked}: [{section}] {key}")
                continue

            if option.get("valueType") == "enum" and option.get("importValues"):
                name = next(
                    (name for name, value in option["importValues"].items() if int(value) == masked),
                    None,
                )
                if name is not None:
                    emitted.append((option["path"], f"  {option['path']} = {nix(name)};"))
                else:
                    report(identity, f"# Unknown enum value {masked}: [{section}] {key}")
                continue

            if option.get("valueType") == "integer":
                emitted.append((option["path"], f"  {option['path']} = {nix(masked)};"))
                continue

            report(identity, f"# Unsupported bitfield: [{section}] {key}")
            continue

        try:
            value = decode(option.get("codec"), raw)
        except ValueError as error:
            emitted.append((option["path"], f"  # {option['path']}: {error}"))
            continue
        emitted.append((option["path"], f"  {option['path']} = {nix(value)};"))

    known = {
        (item.get("file", "reaper.ini"), item["section"], item["key"])
        for item in schema.get("options", [])
    }
    raw_declarations: list[str] = []
    for file_name, current_ini in inis.items():
        for section in current_ini.sections():
            for key in current_ini[section]:
                identity = (file_name, section, key)
                if identity in known:
                    continue
                raw = current_ini[section][key]
                if args.all_files:
                    if file_name == "reaper.ini":
                        target = (
                            f"sections.{nix(section)}."
                            f"{nix(key)}"
                        )
                    else:
                        target = (
                            f"files.{nix(file_name)}."
                            f"{nix(section)}.{nix(key)}"
                        )
                    raw_declarations.append(f"    {target} = {nix(raw)};")
                else:
                    report(
                        identity,
                        f"# Unmapped INI value: {file_name} [{section}] "
                        f"{key}={raw}",
                    )

    raw_line_files: dict[str, list[str]] = {}
    if args.all_files:
        for file_name in ("reaper-kb.ini", "reaper-jsfx.ini"):
            lines = line_file(resource_dir, file_name)
            if lines:
                raw_line_files[file_name] = lines

    if raw_declarations or raw_line_files:
        print("# Raw INI imports (review runtime/state values before enabling them).")
        print("programs.reaper = {")
        if raw_declarations:
            print("  ini = {")
            print("\n".join(sorted(raw_declarations)))
            print("  };")
        if raw_line_files:
            print("  lineFiles.files = {")
            for file_name, lines in sorted(raw_line_files.items()):
                print(f"    {nix(file_name)} = [")
                for line in lines:
                    print(f"      {nix(line)}")
                print("    ];")
            print("  };")
        print("};")

    declarations: dict[str, set[str]] = {}
    for path, line in set(emitted):
        if path.startswith("preferences."):
            scope = "preferences"
            relative_path = path.removeprefix("preferences.")
        elif path.startswith("windows."):
            scope = "windows"
            relative_path = path.removeprefix("windows.")
        else:
            scope = "reaper"
            relative_path = path
        declarations.setdefault(scope, set()).add(
            line.replace(f"  {path} =", f"  {relative_path} =", 1)
        )

    for scope in sorted(declarations):
        prefix = "programs.reaper" if scope == "reaper" else f"programs.reaper.{scope}"
        print(f"{prefix} = {{")
        print("\n".join(sorted(declarations[scope])))
        print("};")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
