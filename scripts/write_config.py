#!/usr/bin/env python3
import re
import argparse
import json
import os
import tempfile

from dataclasses import dataclass
from pathlib import Path
from typing import Any


HEADER_RE = re.compile(r"^\[([^\]]+)\]$")


@dataclass
class Line:
    text: str
    section: str | None = None
    key: str | None = None


def is_entry_line(text: str) -> bool:
    stripped = text.lstrip()
    return "=" in text and not stripped.startswith(("#", ";", "["))


def key_name(text: str) -> str:
    return text.split("=", 1)[0].strip()


def value_part(text: str) -> str:
    return text.split("=", 1)[1]


def write_atomic(path: Path, content: str) -> None:
    # Write beside the destination and rename into place. This prevents partial
    # files if activation is interrupted while writing.
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
        os.chmod(tmp_name, 0o644)
        os.replace(tmp_name, path)
    except Exception:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass
        raise


def save_target(path: Path, lines: list[Line]) -> None:
    content = "\n".join(line.text for line in lines)
    if lines:
        content += "\n"
    write_atomic(path, content)


def save_state(path: Path, sections: dict[str, dict[str, str]]) -> None:
    content = json.dumps({"version": 1, "sections": sections}, sort_keys=True, indent=4)
    content += "\n"
    write_atomic(path, content)


def section_ranges(lines: list[Line]) -> dict[str, tuple[int, int]]:
    ranges: dict[str, tuple[int, int]] = {}
    headers: list[tuple[str, int]] = [
        (line.section or "", index)
        for index, line in enumerate(lines)
        if HEADER_RE.match(line.text)
    ]

    for offset, (section, start) in enumerate(headers):
        end = headers[offset + 1][1] if offset + 1 < len(headers) else len(lines)
        ranges[section] = (start, end)
    if lines and (not headers or headers[0][1] != 0):
        first_header = headers[0][1] if headers else len(lines)
        ranges.setdefault("", (0, first_header))

    return ranges


def apply_managed_values(
    lines: list[Line], managed: dict[str, dict[str, str]]
) -> list[Line]:
    result = list(lines)
    positions: dict[tuple[str, str], list[int]] = {}
    for index, line in enumerate(lines):
        if line.key is not None:
            positions.setdefault((line.section or "", line.key), []).append(index)
    missing: set[tuple[str, str]] = set()
    for section, entries in managed.items():
        for key, value in entries.items():
            identity = (section, key)
            replacement = Line(text=f"{key}={value}", section=section, key=key)
            if identity in positions:
                result[positions[identity][-1]] = replacement
            else:
                missing.add(identity)

    # Insert missing keys

    if not missing:
        return result

    result = list(result)
    ranges = section_ranges(result)

    for section, entries in managed.items():
        section_missing = [
            (key, entries[key]) for key in entries if (section, key) in missing
        ]
        if not section_missing:
            continue
        new_lines = [
            Line(text=f"{key}={value}", section=section, key=key)
            for key, value in section_missing
        ]
        if section in ranges:
            _, end = ranges[section]
            result[end:end] = new_lines
        else:
            if result:
                result.append(Line(text=""))
            if section:
                result.append(Line(text=f"[{section}]", section=section))
            result.extend(new_lines)

        ranges = section_ranges(result)

    return result


def parse_lines(raw_lines: list[str]) -> list[Line]:
    parsed: list[Line] = []
    section = ""
    for text in raw_lines:
        header = HEADER_RE.match(text)
        if header:
            section = header.group(1)
            parsed.append(Line(text=text, section=section))
        elif is_entry_line(text):
            parsed.append(Line(text=text, section=section, key=key_name(text)))
        else:
            parsed.append(Line(text=text, section=section))
    return parsed


def parse_legacy_state(text: str) -> dict[str, dict[str, str]]:
    state: dict[str, dict[str, str]] = {}
    section = ""
    for line in text.split():
        header = HEADER_RE.match(line)
        if header:
            section = header.group(1)
        elif is_entry_line(line):
            state.setdefault(section, {})[key_name(line)] = value_part(line)
    return state


def has_managed_values(sections: dict[str, dict[str, str]]) -> bool:
    return any(entries for entries in sections.values())


# Only remove stale keys if it contains the exact old value
def remove_stale(
    lines: list[Line],
    previous: dict[str, dict[str, str]],
    current_managed: set[tuple[str, str]],
) -> list[Line]:
    if not previous:
        return lines
    kept: list[Line] = []
    for line in lines:
        if line.key is None:
            kept.append(line)
            continue
        section = line.section or ""
        identity = (section, line.key)
        previous_value = previous.get(section, {}).get(line.key)
        if (
            previous_value is not None
            and identity not in current_managed
            and value_part(line.text) == previous_value
        ):
            continue
        kept.append(line)
    return kept


def remove_sections(lines: list[Line], sections: set[str]) -> list[Line]:
    if not sections:
        return lines

    ranges = section_ranges(lines)
    remove_indexes: set[int] = set()
    for section in sections:
        section_range = ranges.get(section)
        if section_range is None:
            continue
        start, end = section_range
        remove_indexes.update(range(start, end))

    return [line for index, line in enumerate(lines) if index not in remove_indexes]


def intish(value: str) -> int:
    # `int(..., 0)` accepts decimal as well as prefixed forms like `0x10`.
    try:
        return int(value, 0)
    except ValueError:
        return 0


def resolve_current(
    payload: dict[str, Any], lines: list[Line]
) -> dict[str, dict[str, str]]:
    direct = normalize_sections(payload.get("sections", {}))
    bitfields = payload.get("bitfields", {})
    current_values: dict[tuple[str, str], str] = {}
    for line in lines:
        if line.key is not None:
            current_values[(line.section or "", line.key)] = value_part(line.text)
    resolved: dict[str, dict[str, str]] = {}

    if isinstance(bitfields, dict):
        for section, entries in bitfields.items():
            if not isinstance(entries, dict):
                continue
            section_name = str(section)
            for key, entry in entries.items():
                if not isinstance(entry, dict):
                    continue
                key_name = str(key)
                mask = int(entry.get("mask", 0))
                value = int(entry.get("value", 0))
                old_value = intish(current_values.get((section_name, key_name), "0"))
                new_value = (old_value & ~mask) | (value & mask)
                resolved.setdefault(section_name, {})[key_name] = str(new_value)

    for section, entries in direct.items():
        resolved.setdefault(section, {}).update(entries)

    return resolved


# Convert everything that looks like a section map into INI string values
def normalize_sections(value: Any) -> dict[str, dict[str, str]]:
    sections: dict[str, dict[str, str]] = {}
    if not isinstance(value, dict):
        return sections

    for section, entries in value.items():
        if not isinstance(entries, dict):
            continue
        normalized_entries: dict[str, str] = {}
        for key, entry_value in entries.items():
            normalized_entries[str(key)] = str(entry_value)
        if normalized_entries:
            sections[str(section)] = normalized_entries

    return sections


def load_payload(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: payload must be JSON")
    payload.setdefault("sections", {})
    payload.setdefault("bitfields", {})
    return payload


def load_previous_state(path: Path) -> dict[str, dict[str, str]]:
    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {}
    if not text.strip():
        return {}

    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        return parse_legacy_state(text)

    if not isinstance(decoded, dict):
        return {}
    if decoded.get("version") == 1:
        return normalize_sections(decoded.get("sections", {}))

    return normalize_sections(decoded)


def read_target(path: Path) -> list[Line]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return parse_lines(handle.read().splitlines())
    except FileNotFoundError:
        return []


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("target", type=Path)
    parser.add_argument("state", type=Path)
    parser.add_argument("payload", type=Path)
    parser.add_argument("--remove-empty-state", action="store_true")

    args = parser.parse_args()

    payload = load_payload(args.payload)
    previous = load_previous_state(args.state)
    lines = read_target(args.target)

    payload_identities = {
        (section, key)
        for section, entries in normalize_sections(payload.get("sections", {})).items()
        for key in entries
    }
    bitfield_identities: set[tuple[str, str]] = set()
    if isinstance(payload.get("bitfields"), dict):
        for section, entries in payload["bitfields"].items():
            if isinstance(entries, dict):
                for key in entries:
                    bitfield_identities.add((str(section), str(key)))

    current_identities = payload_identities | bitfield_identities
    lines = remove_stale(lines, previous, current_identities)
    current = resolve_current(payload, lines)
    lines = apply_managed_values(lines, current)
    remove_sections_value = payload.get("removeSections", [])
    remove_sections_set = (
        {str(section) for section in remove_sections_value}
        if isinstance(remove_sections_value, list)
        else set()
    )
    lines = remove_sections(lines, remove_sections_set)

    save_target(args.target, lines)

    if args.remove_empty_state and not has_managed_values(current):
        try:
            args.state.unlink()
        except FileNotFoundError:
            pass
    else:
        save_state(args.state, current)


if __name__ == "__main__":
    main()
