import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = Path(os.environ.get("REAPER2NIX_SCRIPT", ROOT / "scripts" / "reaper2nix.py"))
SPEC = importlib.util.spec_from_file_location("reaper2nix", SCRIPT)
REAPER2NIX = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(REAPER2NIX)


class NixSerializationTests(unittest.TestCase):
    def test_nested_values_are_valid_nix_expressions(self):
        self.assertEqual(
            REAPER2NIX.nix({"path": "a${b}\n", "enabled": True, "items": [1, None]}),
            '{\n  path = "a\\${b}\\n";\n  enabled = true;\n  items = [1 null];\n}',
        )

    def test_invalid_attribute_names_are_quoted(self):
        self.assertEqual(
            REAPER2NIX.nix({"reaper.ini": {"Main file": {"item_0": "value"}}}),
            '{\n  "reaper.ini" = {\n    "Main file" = {\n      item_0 = "value";\n    };\n  };\n}',
        )


class ReaperKbAdapterTests(unittest.TestCase):
    def test_records_are_decoded_to_public_action_options(self):
        decoded, diagnostics = REAPER2NIX.parse_reaper_kb(
            [
                'SCR 4 0 RSabc "Custom: lyrics.lua" Cockos/lyrics.lua',
                'ACT 3 32060 "custom_drums" "Custom: Drums" 40043 _RSabc',
                'KEY 13 73 40214 0 # Main : Ctrl+Shift+I',
            ]
        )

        self.assertEqual(diagnostics, [])
        self.assertEqual(decoded["scripts"][0]["location"], "scripts")
        self.assertEqual(decoded["scripts"][0]["path"], "Cockos/lyrics.lua")
        self.assertTrue(decoded["customActions"][0]["consolidateUndoPoints"])
        self.assertTrue(decoded["customActions"][0]["showInActionsMenu"])
        self.assertEqual(decoded["customActions"][0]["actions"], [40043, "_RSabc"])
        self.assertEqual(decoded["keyBindings"][0]["comment"], "Main : Ctrl+Shift+I")


class LayoutAdapterTests(unittest.TestCase):
    def test_fixed_windows_docks_and_preferences_are_decoded(self):
        parser = REAPER2NIX.configparser.ConfigParser(
            interpolation=None, delimiters=("=",), strict=False
        )
        parser.optionxform = str
        parser.read_string(
            """
[reaper]
wnd_x=1536
wnd_y=40
wnd_w=1920
wnd_h=1012
wnd_state=0
mixwnd_vis=0
mixwnd_dock=1
transport_vis=1
transport_dock_pos=3
dockermode2=1
dockersel2=explorer
dockheight_l=395

[mastermixer]
wnd_vis=1
dock=1
wnd_left=0
wnd_top=0
wnd_width=680
wnd_height=264

[REAPERdockpref]
explorer=0.500000 2
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reaper_layout(parser)

        self.assertEqual(diagnostics, [])
        self.assertEqual(decoded["mainWindow"]["position"], {"x": 1536, "y": 40})
        self.assertTrue(decoded["masterMixer"]["docked"])
        self.assertEqual(decoded["transport"]["dockPosition"], 3)
        self.assertEqual(
            decoded["docks"]["left"],
            {
                "id": 2,
                "position": "left",
                "selectedPanel": "explorer",
                "size": 395,
            },
        )
        self.assertEqual(decoded["dockPreferences"]["explorer"], "0.500000 2")
        self.assertIn(("reaper", "dockermode2"), consumed)
        self.assertIn(("REAPERdockpref", "explorer"), consumed)


class SourceAllowlistTests(unittest.TestCase):
    def test_all_files_only_reads_schema_declared_ini_sources(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema = {
                "version": 2,
                "sources": {
                    "reaper.ini": {"format": "ini", "adapter": "ini"},
                },
                "options": [
                    {
                        "path": "preferences.general.undo.maximumUndoMemory",
                        "kind": "value",
                        "file": "reaper.ini",
                        "section": "reaper",
                        "key": "undomaxmem",
                        "codec": "integer",
                    }
                ],
            }
            schema_path = resource_dir / "schema.json"
            schema_path.write_text(json.dumps(schema))
            (resource_dir / "reaper.ini").write_text(
                "[reaper]\nundomaxmem=512\nunmapped=kept\n"
            )
            (resource_dir / "reaper-state.ini").write_text(
                "[state]\nunsupported_file_sentinel=must-not-appear\n"
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir),
                    "--schema",
                    str(schema_path),
                    "--all-files",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("maximumUndoMemory = 512;", result.stdout)
        self.assertIn('unmapped = "kept";', result.stdout)
        self.assertIn("preferences = {", result.stdout)
        self.assertIn("general = {", result.stdout)
        self.assertNotIn("preferences.general", result.stdout)
        self.assertTrue(result.stdout.rstrip().endswith("}"))
        self.assertNotIn("unsupported_file_sentinel", result.stdout)
        self.assertNotIn("reaper-state.ini", result.stdout)

    def test_unmapped_keys_are_silent_unless_requested(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema_path = resource_dir / "schema.json"
            schema_path.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "sources": {
                            "reaper.ini": {"format": "ini", "adapter": "ini"}
                        },
                        "options": [],
                    }
                )
            )
            ini_path = resource_dir / "reaper.ini"
            ini_path.write_text("[state]\nwindow_x=100\n")

            base_command = [
                sys.executable,
                str(SCRIPT),
                str(ini_path),
                "--schema",
                str(schema_path),
            ]
            quiet = subprocess.run(
                base_command, check=True, capture_output=True, text=True
            )
            verbose = subprocess.run(
                [*base_command, "--show-unmapped"],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertEqual(quiet.stdout, "")
        self.assertIn("Unmapped INI value", verbose.stdout)

    def test_composite_and_ignored_bitfield_values(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema_path = resource_dir / "schema.json"
            common = {
                "kind": "bitfield",
                "file": "reaper.ini",
                "section": "reaper",
                "key": "newtflag",
                "codec": "identity",
            }
            schema_path.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "sources": {
                            "reaper.ini": {"format": "ini", "adapter": "ini"}
                        },
                        "options": [
                            {
                                **common,
                                "path": "preferences.project.freeItemPositioning",
                                "mask": 12,
                                "valueType": "assignments",
                                "importAssignments": {
                                    "8": {
                                        "preferences.project.freeItemPositioning": False,
                                        "preferences.project.fixedItemLanes": True,
                                    }
                                },
                            },
                            {
                                **common,
                                "path": "preferences.project.newRecordingBehavior",
                                "mask": 16,
                                "valueType": "enum",
                                "importValues": {"override": 16},
                                "ignoredValues": [0],
                            },
                        ],
                    }
                )
            )
            ini_path = resource_dir / "reaper.ini"
            ini_path.write_text("[reaper]\nnewtflag=8\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(ini_path),
                    "--schema",
                    str(schema_path),
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("fixedItemLanes = true;", result.stdout)
        self.assertIn("freeItemPositioning = false;", result.stdout)
        self.assertNotIn("Unknown enum", result.stdout)

    def test_single_file_input_does_not_import_supported_siblings(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema = {
                "version": 2,
                "sources": {
                    "reaper.ini": {"format": "ini", "adapter": "ini"},
                    "other.ini": {"format": "ini", "adapter": "ini"},
                },
                "options": [],
            }
            schema_path = resource_dir / "schema.json"
            schema_path.write_text(json.dumps(schema))
            (resource_dir / "reaper.ini").write_text("[reaper]\nselected=yes\n")
            (resource_dir / "other.ini").write_text("[other]\nsibling=must-not-appear\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir / "reaper.ini"),
                    "--schema",
                    str(schema_path),
                    "--all-files",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn('selected = "yes";', result.stdout)
        self.assertNotIn("sibling", result.stdout)


if __name__ == "__main__":
    unittest.main()
