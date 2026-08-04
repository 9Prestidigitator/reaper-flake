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
            set(self.schema["sources"]),
            {
                "ReaPack/reaper-flake-state.json",
                "reaper.ini",
                "reapack.ini",
                "reaper-kb.ini",
                "reaper-menu.ini",
            },
        )
        self.assertEqual(
            self.schema["sources"]["reaper-menu.ini"]["adapters"],
            ["reaper-menu"],
        )
        self.assertEqual(
            self.schema["sources"]["reaper-menu.ini"]["adapterConfig"][
                "toolbarTextIcons"
            ],
            {"normal": "text", "tooltip": "text_tt", "wide": "text_wide"},
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
