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
                "reaper-mouse.ini",
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
        self.assertEqual(
            self.schema["sources"]["reaper-mouse.ini"]["adapters"],
            ["reaper-mouse"],
        )
        self.assertEqual(
            self.schema["sources"]["reaper.ini"]["adapters"],
            ["reaper-layout"],
        )

    def test_unset_options_remain_in_the_schema(self):
        paths = {option["path"] for option in self.schema["options"]}
        self.assertIn("preferences.general.undo.maximumUndoMemory", paths)
        self.assertIn("preferences.appearance.trackControlPanels.showFxInserts", paths)

    def test_plugin_search_paths_use_list_codecs(self):
        options = {option["path"]: option for option in self.schema["options"]}
        expected = {
            "preferences.plugIns.vst.searchPaths": "vstpath",
            "preferences.plugIns.lv2.searchPaths": "lv2path_linux",
            "preferences.plugIns.clap.searchPaths": "clap_path_linux-x86_64",
        }

        for path, key in expected.items():
            with self.subTest(path=path):
                self.assertEqual(options[path]["kind"], "value")
                self.assertEqual(options[path]["key"], key)
                self.assertEqual(options[path]["codec"], "list")

    def test_open_project_on_startup_is_mapped(self):
        options = {option["path"]: option for option in self.schema["options"]}
        option = options[
            "preferences.general.startupSettings.openProjectOnStartup"
        ]

        self.assertEqual(option["kind"], "value")
        self.assertEqual(option["file"], "reaper.ini")
        self.assertEqual(option["section"], "reaper")
        self.assertEqual(option["key"], "loadlastproj")
        self.assertEqual(option["codec"], "integer")

    def test_every_bitfield_has_reverse_decoding_metadata(self):
        incomplete = [
            option["path"]
            for option in self.schema["options"]
            if option["kind"] == "bitfield" and option["valueType"] is None
        ]
        self.assertEqual(incomplete, [])


if __name__ == "__main__":
    unittest.main()
