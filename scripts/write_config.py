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


@dataclass
class ManagedState:
    sections: dict[str, dict[str, str]]
    bitfields: dict[str, dict[str, dict[str, int]]]
    legacy: bool = False


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


def save_state(
    path: Path,
    sections: dict[str, dict[str, str]],
    bitfields: dict[str, dict[str, dict[str, int]]],
) -> None:
    content = json.dumps(
        {"version": 2, "sections": sections, "bitfields": bitfields},
        sort_keys=True,
        indent=4,
    )
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


def has_managed_bitfields(
    bitfields: dict[str, dict[str, dict[str, int]]],
) -> bool:
    return any(entries for entries in bitfields.values())


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


def current_values(lines: list[Line]) -> dict[tuple[str, str], str]:
    values: dict[tuple[str, str], str] = {}
    for line in lines:
        if line.key is not None:
            values[(line.section or "", line.key)] = value_part(line.text)
    return values


def resolve_bitfield_updates(
    current: dict[str, dict[str, dict[str, int]]],
    previous: dict[str, dict[str, dict[str, int]]],
    lines: list[Line],
) -> dict[str, dict[str, str]]:
    """Apply current masks and clear masks released since the prior generation."""

    existing = current_values(lines)
    updates: dict[str, dict[str, str]] = {}
    identities = {
        (section, key)
        for bitfields in (current, previous)
        for section, entries in bitfields.items()
        for key in entries
    }

    for section, key in sorted(identities):
        previous_entry = previous.get(section, {}).get(key, {})
        current_entry = current.get(section, {}).get(key, {})
        previous_mask = int(previous_entry.get("mask", 0))
        mask = int(current_entry.get("mask", 0))
        value = int(current_entry.get("value", 0))
        released_mask = previous_mask & ~mask
        touched_mask = released_mask | mask
        if touched_mask == 0:
            continue
        if mask == 0 and (section, key) not in existing:
            # The key already uses REAPER's all-zero default implicitly.
            continue

        old_value = intish(existing.get((section, key), "0"))
        new_value = (old_value & ~touched_mask) | (value & mask)
        updates.setdefault(section, {})[key] = str(new_value)

    return updates


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


def normalize_bitfields(
    value: Any,
) -> dict[str, dict[str, dict[str, int]]]:
    bitfields: dict[str, dict[str, dict[str, int]]] = {}
    if not isinstance(value, dict):
        return bitfields

    for section, entries in value.items():
        if not isinstance(entries, dict):
            continue
        for key, entry in entries.items():
            if not isinstance(entry, dict):
                continue
            mask = int(entry.get("mask", 0))
            if mask == 0:
                continue
            bitfields.setdefault(str(section), {})[str(key)] = {
                "mask": mask,
                "value": int(entry.get("value", 0)) & mask,
            }

    return bitfields


def load_payload(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: payload must be JSON")
    payload.setdefault("sections", {})
    payload.setdefault("bitfields", {})
    return payload


def load_previous_state(path: Path) -> ManagedState:
    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ManagedState({}, {})
    if not text.strip():
        return ManagedState({}, {})

    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        return ManagedState(parse_legacy_state(text), {}, legacy=True)

    if not isinstance(decoded, dict):
        return ManagedState({}, {})
    if decoded.get("version") == 2:
        return ManagedState(
            normalize_sections(decoded.get("sections", {})),
            normalize_bitfields(decoded.get("bitfields", {})),
        )
    if decoded.get("version") == 1:
        return ManagedState(
            normalize_sections(decoded.get("sections", {})), {}, legacy=True
        )

    return ManagedState(normalize_sections(decoded), {}, legacy=True)


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

    current_sections = normalize_sections(payload.get("sections", {}))
    current_bitfields = normalize_bitfields(payload.get("bitfields", {}))
    current_direct_identities = {
        (section, key)
        for section, entries in current_sections.items()
        for key in entries
    }
    current_bitfield_identities = {
        (section, key)
        for section, entries in current_bitfields.items()
        for key in entries
    }
    # Version 1 did not distinguish direct keys from resolved bitfield keys.
    # Preserve its old key-level transition behavior for this one migration.
    stale_blockers = current_direct_identities | (
        current_bitfield_identities if previous.legacy else set()
    )
    lines = remove_stale(lines, previous.sections, stale_blockers)

    bitfield_updates = resolve_bitfield_updates(
        current_bitfields, previous.bitfields, lines
    )
    lines = apply_managed_values(lines, bitfield_updates)
    lines = apply_managed_values(lines, current_sections)
    remove_sections_value = payload.get("removeSections", [])
    remove_sections_set = (
        {str(section) for section in remove_sections_value}
        if isinstance(remove_sections_value, list)
        else set()
    )
    lines = remove_sections(lines, remove_sections_set)

    save_target(args.target, lines)

    if (
        args.remove_empty_state
        and not has_managed_values(current_sections)
        and not has_managed_bitfields(current_bitfields)
    ):
        try:
            args.state.unlink()
        except FileNotFoundError:
            pass
    else:
        save_state(args.state, current_sections, current_bitfields)


if __name__ == "__main__":
    main()
