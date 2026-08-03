import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = Path(os.environ.get("WRITE_CONFIG_SCRIPT", ROOT / "scripts/write_config.py"))


class BitfieldOwnershipTests(unittest.TestCase):
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
        self.assertEqual(
            state["bitfields"]["reaper"]["flags"], {"mask": 2, "value": 2}
        )

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


if __name__ == "__main__":
    unittest.main()
