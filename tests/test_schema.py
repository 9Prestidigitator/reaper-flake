import json
import os
import unittest
from pathlib import Path


SCHEMA_PATH = os.environ.get("REAPER_SCHEMA_PATH")


@unittest.skipUnless(SCHEMA_PATH, "REAPER_SCHEMA_PATH is only set by the Nix check")
class StaticSchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema = json.loads(Path(SCHEMA_PATH).read_text())

    def test_schema_declares_only_supported_sources(self):
        self.assertEqual(
            self.schema["sources"],
            {
                "ReaPack/reaper-flake-state.json": {
                    "adapter": "reapack-packages",
                    "adapters": [],
                    "format": "json",
                },
                "reaper.ini": {
                    "adapter": "ini",
                    "adapters": ["reaper-layout"],
                    "format": "ini",
                },
                "reapack.ini": {
                    "adapter": "ini",
                    "adapters": ["reapack"],
                    "format": "ini",
                },
                "reaper-kb.ini": {
                    "adapter": "reaper-kb",
                    "adapters": [],
                    "format": "line",
                },
            },
        )

    def test_unset_options_remain_in_the_schema(self):
        paths = {option["path"] for option in self.schema["options"]}
        self.assertIn("preferences.general.undo.maximumUndoMemory", paths)
        self.assertIn("preferences.appearance.trackControlPanels.showFxInserts", paths)

    def test_every_bitfield_has_reverse_decoding_metadata(self):
        incomplete = [
            option["path"]
            for option in self.schema["options"]
            if option["kind"] == "bitfield" and option["valueType"] is None
        ]
        self.assertEqual(incomplete, [])


if __name__ == "__main__":
    unittest.main()
