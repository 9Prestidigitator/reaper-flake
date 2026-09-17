import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = Path(os.environ.get("WRITE_CONFIG_SCRIPT", ROOT / "scripts/write_config.py"))


class WriterTestCase(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.target = self.directory / "reaper.ini"
        self.state = self.directory / "state.json"
        self.payload = self.directory / "payload.json"

    def tearDown(self):
        self.temporary_directory.cleanup()

    def run_writer(self, payload, *, remove_empty_state=False):
        self.payload.write_text(json.dumps(payload))
        command = [
            sys.executable,
            str(SCRIPT),
            str(self.target),
            str(self.state),
            str(self.payload),
        ]
        if remove_empty_state:
            command.append("--remove-empty-state")
        subprocess.run(command, check=True, capture_output=True, text=True)


class BitfieldOwnershipTests(WriterTestCase):
    def value(self, key="flags"):
        for line in self.target.read_text().splitlines():
            if line.startswith(f"{key}="):
                return int(line.split("=", 1)[1])
        self.fail(f"{key} was not written")

    @staticmethod
    def payload_for(mask=None, value=0, sections=None):
        bitfields = {}
        if mask is not None:
            bitfields = {"reaper": {"flags": {"mask": mask, "value": value}}}
        return {
            "sections": sections or {},
            "bitfields": bitfields,
            "removeSections": [],
        }

    def test_releasing_one_mask_clears_it_and_preserves_every_other_bit(self):
        self.target.write_text("[reaper]\nflags=8\n")
        self.run_writer(self.payload_for(mask=3, value=3))
        self.assertEqual(self.value(), 11)

        self.run_writer(self.payload_for(mask=2, value=2))

        self.assertEqual(self.value(), 10)
        state = json.loads(self.state.read_text())
        self.assertEqual(state["version"], 2)
        self.assertEqual(state["bitfields"]["reaper"]["flags"], {"mask": 2, "value": 2})

    def test_releasing_last_mask_clears_it_without_deleting_unmanaged_bits(self):
        self.target.write_text("[reaper]\nflags=8\n")
        self.run_writer(self.payload_for(mask=3, value=3))

        self.run_writer(self.payload_for(), remove_empty_state=True)

        self.assertEqual(self.value(), 8)
        self.assertFalse(self.state.exists())

    def test_never_managed_null_option_does_not_clear_existing_bits(self):
        self.target.write_text("[reaper]\nflags=9\n")

        self.run_writer(self.payload_for(), remove_empty_state=True)

        self.assertEqual(self.value(), 9)

    def test_releasing_an_already_absent_key_does_not_reinsert_zero(self):
        self.target.write_text("[reaper]\nflags=1\n")
        self.run_writer(self.payload_for(mask=1, value=1))
        self.target.write_text("[reaper]\n")

        self.run_writer(self.payload_for(), remove_empty_state=True)

        self.assertNotIn("flags=", self.target.read_text())
        self.assertFalse(self.state.exists())

    def test_current_mask_value_is_replaced_normally(self):
        self.target.write_text("[reaper]\nflags=9\n")
        self.run_writer(self.payload_for(mask=1, value=1))

        self.run_writer(self.payload_for(mask=1, value=0))

        self.assertEqual(self.value(), 8)

    def test_numeric_formats_preserve_unmanaged_bits(self):
        for raw_value, expected in (
            ("008", 9),
            ("8", 9),
            ("010", 11),
            ("0x8", 9),
            ("0X8", 9),
            ("0o10", 9),
            ("0b1000", 9),
            (" +008 ", 9),
            ("-8", -7),
            ("-008", -7),
            ("-0x8", -7),
        ):
            with self.subTest(raw_value=raw_value):
                self.target.write_text(f"[reaper]\nflags={raw_value}\n")
                self.run_writer(self.payload_for(mask=1, value=1))
                self.assertEqual(self.value(), expected)

    def test_missing_bitfield_still_starts_from_zero(self):
        self.run_writer(self.payload_for(mask=1, value=1))
        self.assertEqual(self.value(), 1)

    def test_invalid_bitfields_leave_target_and_state_unchanged(self):
        for raw_value in ("", " ", "invalid", "0xGG", "8.0", "--8"):
            for release in (False, True):
                with self.subTest(raw_value=raw_value, release=release):
                    self.target.write_text("[reaper]\nflags=8\n")
                    self.run_writer(self.payload_for(mask=1, value=1))
                    self.target.write_text(f"[reaper]\nflags={raw_value}\n")
                    before = self.target.read_bytes(), self.state.read_bytes()
                    payload = (
                        self.payload_for()
                        if release
                        else self.payload_for(mask=1, value=0)
                    )
                    with self.assertRaises(subprocess.CalledProcessError) as failure:
                        self.run_writer(payload, remove_empty_state=release)
                    self.assertIn(
                        f"Invalid bitfield value for [reaper].flags: {raw_value!r}",
                        failure.exception.stderr,
                    )
                    self.assertEqual(
                        (self.target.read_bytes(), self.state.read_bytes()), before
                    )

    def test_direct_state_is_not_mixed_with_bitfield_ownership(self):
        self.target.write_text("[reaper]\nordinary=old\nflags=8\n")
        self.run_writer(
            self.payload_for(
                mask=1,
                value=1,
                sections={"reaper": {"ordinary": "managed"}},
            )
        )

        state = json.loads(self.state.read_text())

        self.assertEqual(state["sections"], {"reaper": {"ordinary": "managed"}})
        self.assertNotIn("flags", state["sections"]["reaper"])
        self.assertEqual(state["bitfields"]["reaper"]["flags"]["mask"], 1)

    def test_version_one_state_migrates_without_guessing_historical_masks(self):
        self.target.write_text("[reaper]\nflags=3\n")
        self.state.write_text(
            json.dumps({"version": 1, "sections": {"reaper": {"flags": "3"}}})
        )

        self.run_writer(self.payload_for(mask=2, value=2))

        self.assertEqual(self.value(), 3)
        state = json.loads(self.state.read_text())
        self.assertEqual(state["version"], 2)
        self.assertEqual(state["sections"], {})
        self.assertEqual(state["bitfields"]["reaper"]["flags"]["mask"], 2)


class SectionReplacementTests(WriterTestCase):
    @staticmethod
    def menu_payload(entries=None):
        return {
            "sections": {"Main toolbar": entries or {}},
            "replaceSections": ["Main toolbar"],
        }

    def test_adoption_replaces_all_occurrences_and_preserves_other_sections(self):
        self.target.write_text(
            "; preamble\n[Main toolbar]\nitem_0=40023 Old\n"
            "icon_0=old.png\nitem_1=40025 Extra\ntitle=Old title\n"
            "tbf_0=1\ndefault=hash\nunknown=metadata\n; old comment\n"
            "[Main file]\nitem_0=40026 Keep\n"
            "[Main toolbar]\nitem_2=40027 Duplicate section\n"
        )
        payload = self.menu_payload({"item_0": "40023 New"})
        self.run_writer(payload)
        expected = (
            "; preamble\n[Main file]\nitem_0=40026 Keep\n\n"
            "[Main toolbar]\nitem_0=40023 New\n"
        )
        self.assertEqual(self.target.read_text(), expected)
        self.run_writer(payload)
        self.assertEqual(self.target.read_text(), expected)
        self.assertEqual(
            json.loads(self.state.read_text())["sections"], payload["sections"]
        )

    def test_shortening_replaces_gui_edits_and_omitted_metadata(self):
        self.run_writer(
            self.menu_payload(
                {
                    "item_0": "40023 Old",
                    "item_1": "40025 Extra",
                    "icon_0": "old.png",
                    "tbf_0": "1",
                    "title": "Old",
                }
            )
        )
        self.target.write_text(self.target.read_text().replace("Extra", "GUI edit"))
        self.run_writer(self.menu_payload({"item_0": "40023 New"}))
        self.assertEqual(self.target.read_text(), "[Main toolbar]\nitem_0=40023 New\n")

    def test_empty_replacement_keeps_header_and_null_reset_removes_it(self):
        self.target.write_text("[Main toolbar]\nitem_0=40023 Old\n")
        self.run_writer(self.menu_payload())
        self.assertEqual(self.target.read_text(), "[Main toolbar]\n")
        self.run_writer({"removeSections": ["Main toolbar"]})
        self.assertEqual(self.target.read_text(), "")

    def test_removal_wins_over_replacement_and_values(self):
        self.target.write_text("[Main toolbar]\nold=1\n[Main toolbar]\nold=2\n")
        payload = self.menu_payload({"item_0": "40023 New"})
        payload["removeSections"] = ["Main toolbar"]
        self.run_writer(payload)
        self.assertEqual(self.target.read_text(), "")

    def test_removal_alone_removes_duplicate_sections(self):
        self.target.write_text("[Main toolbar]\nold=1\n[Main toolbar]\nold=2\n")
        self.run_writer({"removeSections": ["Main toolbar"]})
        self.assertEqual(self.target.read_text(), "")

    def test_omitting_menu_retains_existing_key_cleanup_semantics(self):
        self.run_writer(
            self.menu_payload({"item_0": "40023 Old", "item_1": "40025 Extra"})
        )
        self.target.write_text(self.target.read_text().replace("Extra", "GUI edit"))
        self.run_writer({}, remove_empty_state=True)
        self.assertEqual(
            self.target.read_text(), "[Main toolbar]\nitem_1=40025 GUI edit\n"
        )
        self.assertFalse(self.state.exists())

    def test_bitfield_conflicts_fail_without_modifying_files(self):
        bitfields = {"Main toolbar": {"flags": {"mask": 1, "value": 1}}}
        for previous in (False, True):
            with self.subTest(previous=previous):
                self.target.write_text("[Main toolbar]\nflags=9\n")
                self.state.write_text(
                    json.dumps(
                        {
                            "version": 2,
                            "sections": {},
                            "bitfields": bitfields if previous else {},
                        }
                    )
                )
                before = self.target.read_bytes(), self.state.read_bytes()
                payload = self.menu_payload()
                if not previous:
                    payload["bitfields"] = bitfields
                with self.assertRaises(subprocess.CalledProcessError) as failure:
                    self.run_writer(payload)
                self.assertIn("bitfield ownership", failure.exception.stderr)
                self.assertEqual(
                    (self.target.read_bytes(), self.state.read_bytes()), before
                )

    def test_unrelated_bitfields_still_preserve_unmanaged_bits(self):
        self.target.write_text("[reaper]\nflags=8\n[Main toolbar]\nold=1\n")
        payload = self.menu_payload({"item_0": "40023 New"})
        payload["bitfields"] = {"reaper": {"flags": {"mask": 1, "value": 1}}}
        self.run_writer(payload)
        self.assertIn("flags=9\n", self.target.read_text())
        self.assertNotIn("old=", self.target.read_text())


if __name__ == "__main__":
    unittest.main()
