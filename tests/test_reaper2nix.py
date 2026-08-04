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

    def test_option_subtrees_preserve_their_full_paths(self):
        tree = {
            "preferences": {
                "general": {"undo": {"maximumUndoMemory": 512}},
                "project": {"fixedItemLanes": True},
            },
            "windows": {"mixer": {"showFolders": True}},
        }

        selected = REAPER2NIX.select_option_subtrees(
            tree,
            [
                REAPER2NIX.normalize_option_filter(
                    "programs.reaper.preferences.general.undo.maximumUndoMemory"
                )
            ],
        )

        self.assertEqual(
            selected,
            {
                "preferences": {
                    "general": {"undo": {"maximumUndoMemory": 512}}
                }
            },
        )

    def test_parent_filter_subsumes_repeated_child_filters(self):
        tree = {"preferences": {"general": {"undo": True}, "project": {}}}
        selected = REAPER2NIX.select_option_subtrees(
            tree,
            [
                ("preferences", "general"),
                ("preferences",),
                ("preferences", "general"),
            ],
        )

        self.assertEqual(selected, tree)

    def test_option_filter_requires_the_public_root(self):
        with self.assertRaisesRegex(ValueError, "must start with programs.reaper"):
            REAPER2NIX.normalize_option_filter("preferences.general")


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


class ReaperMenuAdapterTests(unittest.TestCase):
    @staticmethod
    def parser(text):
        parser = REAPER2NIX.configparser.ConfigParser(
            interpolation=None, delimiters=("=",), strict=False
        )
        parser.optionxform = str
        parser.read_string(text)
        return parser

    def test_nested_menus_are_decoded_to_public_entries(self):
        parser = self.parser(
            """
[Main file]
title=&Project
item_0=40023 &New project
item_1=-1
item_2=-2 Project &templates
item_3=_RSabc Save as template
item_4=-4 Utilities
item_5=-3
default=generated-fingerprint
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reaper_menu(
            parser,
            {"sectionKinds": {"Main file": "menu"}},
        )

        self.assertEqual(diagnostics, [])
        self.assertEqual(
            decoded["Main file"],
            {
                "entries": [
                    {"action": 40023, "label": "&New project"},
                    {"separator": True},
                    {
                        "label": "Project &templates",
                        "entries": [
                            {"action": "_RSabc", "label": "Save as template"},
                            {"disabled": True, "label": "Utilities"},
                        ],
                    },
                ],
                "title": "&Project",
            },
        )
        self.assertIn(("Main file", "default"), consumed)
        self.assertIn(("Main file", "item_5"), consumed)

    def test_toolbar_metadata_and_numeric_item_order_are_decoded(self):
        parser = self.parser(
            """
[Custom toolbar]
item_2=40003 Stop
icon_2=text_tt
tbf_2=1
item_0=40044 Play
icon_0=text
item_1=_RSabc Render
icon_1=toolbar_render.png
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reaper_menu(
            parser,
            {
                "toolbarTextIcons": {
                    "normal": "text",
                    "wide": "text_wide",
                    "tooltip": "text_tt",
                }
            },
        )

        self.assertEqual(diagnostics, [])
        self.assertEqual(decoded["Custom toolbar"]["kind"], "toolbar")
        self.assertEqual(
            decoded["Custom toolbar"]["entries"],
            [
                {"action": 40044, "label": "Play", "textIcon": "normal"},
                {
                    "action": "_RSabc",
                    "label": "Render",
                    "icon": "toolbar_render.png",
                },
                {
                    "action": 40003,
                    "label": "Stop",
                    "useTextAsTooltip": True,
                    "toolbarFlags": 1,
                },
            ],
        )
        self.assertIn(("Custom toolbar", "icon_1"), consumed)
        self.assertIn(("Custom toolbar", "tbf_2"), consumed)

    def test_malformed_submenu_does_not_emit_an_invalid_option(self):
        parser = self.parser(
            """
[Main file]
item_0=-2 Unclosed submenu
item_1=40023 New project
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reaper_menu(parser)

        self.assertEqual(decoded, {})
        self.assertEqual(consumed, set())
        self.assertIn("submenu(s) are not closed", diagnostics[0])


class ReaperMouseAdapterTests(unittest.TestCase):
    @staticmethod
    def parser(text):
        parser = REAPER2NIX.configparser.ConfigParser(
            interpolation=None, delimiters=("=",), strict=False
        )
        parser.optionxform = str
        parser.read_string(text)
        return parser

    def test_imported_contexts_and_bindings_are_decoded(self):
        parser = self.parser(
            """
[hasimported]
MM_CTX_MIDI_NOTE_CLK=1
MM_CTX_ARRANGE_MMOUSE=1
MM_CTX_UNUSED=0

[MM_CTX_ARRANGE_MMOUSE]
mm_0=9 m
mm_1=_RSabc command mode

[unrelated]
mm_0=7 m
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reaper_mouse(parser)

        self.assertEqual(diagnostics, [])
        self.assertEqual(
            decoded["importedContexts"],
            ["MM_CTX_ARRANGE_MMOUSE", "MM_CTX_MIDI_NOTE_CLK"],
        )
        self.assertEqual(
            decoded["contexts"]["MM_CTX_ARRANGE_MMOUSE"],
            {
                "mm_0": {"action": 9, "mode": "m"},
                "mm_1": {"action": "_RSabc", "mode": "command mode"},
            },
        )
        self.assertIn(("hasimported", "MM_CTX_UNUSED"), consumed)
        self.assertIn(("MM_CTX_ARRANGE_MMOUSE", "mm_0"), consumed)
        self.assertNotIn(("unrelated", "mm_0"), consumed)

    def test_invalid_values_remain_unconsumed(self):
        parser = self.parser(
            """
[hasimported]
MM_CTX_BAD=not-a-number

[MM_CTX_ARRANGE_MMOUSE]
mm_0=
unknown=preserve-me
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reaper_mouse(parser)

        self.assertEqual(decoded, {})
        self.assertEqual(consumed, set())
        self.assertEqual(len(diagnostics), 2)


class PluginPathImportTests(unittest.TestCase):
    def test_effective_plugin_paths_are_imported_as_authoritative_lists(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema_path = resource_dir / "schema.json"
            paths = [
                (
                    "preferences.plugIns.vst.searchPaths",
                    "vstpath",
                ),
                (
                    "preferences.plugIns.lv2.searchPaths",
                    "lv2path_linux",
                ),
                (
                    "preferences.plugIns.clap.searchPaths",
                    "clap_path_linux-x86_64",
                ),
            ]
            schema_path.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "sources": {
                            "reaper.ini": {"format": "ini", "adapter": "ini"}
                        },
                        "options": [
                            {
                                "path": path,
                                "kind": "value",
                                "file": "reaper.ini",
                                "section": "reaper",
                                "key": key,
                                "codec": "list",
                            }
                            for path, key in paths
                        ],
                    }
                )
            )
            (resource_dir / "reaper.ini").write_text(
                "[reaper]\n"
                "vstpath=/exact/vst;/exact/vst3\n"
                "lv2path_linux=/exact/lv2\n"
                "clap_path_linux-x86_64=/exact/clap;~/.clap\n"
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir),
                    "--schema",
                    str(schema_path),
                    "--options",
                    "programs.reaper.preferences.plugIns",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn('vst = {\n          searchPaths = ["/exact/vst" "/exact/vst3"]', result.stdout)
        self.assertIn('lv2 = {\n          searchPaths = ["/exact/lv2"]', result.stdout)
        self.assertIn('clap = {\n          searchPaths = ["/exact/clap" "~/.clap"]', result.stdout)
        self.assertNotIn("enableNixPaths", result.stdout)
        self.assertNotIn("enableUserPaths", result.stdout)


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


class ReaPackAdapterTests(unittest.TestCase):
    def test_missing_snapshot_is_reported_only_for_reapack_resources(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            missing = resource_dir / "ReaPack/reaper-flake-state.json"
            decoded, diagnostics = REAPER2NIX.parse_reapack_packages(
                resource_dir, missing
            )
            self.assertEqual(decoded, {})
            self.assertEqual(diagnostics, [])

            (resource_dir / "reapack.ini").write_text("[general]\nversion=4\n")
            _, diagnostics = REAPER2NIX.parse_reapack_packages(resource_dir, missing)

        self.assertIn("snapshot is missing", diagnostics[0])

    def test_preferences_and_ordered_repositories_are_decoded(self):
        parser = REAPER2NIX.configparser.ConfigParser(
            interpolation=None, delimiters=("=",), strict=False
        )
        parser.optionxform = str
        parser.read_string(
            """
[install]
autoinstall=0
prereleases=1
promptobsolete=1
[browser]
synonyms=1
[network]
proxy=
verifypeer=1
stalethreshold=604800
fallbackproxy=2
[remotes]
remote0=ReaPack|https://reapack.com/index.xml|1|2
remote1=Custom|https://example.org/index.xml|0|1
size=2
"""
        )

        decoded, consumed, diagnostics = REAPER2NIX.parse_reapack_ini(parser)

        self.assertEqual(diagnostics, [])
        self.assertNotIn("addDefaultRepositories", decoded)
        self.assertFalse(decoded["installNewPackagesWhenSynchronizing"])
        self.assertTrue(decoded["enablePrereleasesGlobally"])
        self.assertEqual(decoded["network"]["fallbackProxy"], "ask")
        self.assertEqual(
            decoded["repositories"][1],
            {
                "name": "Custom",
                "url": "https://example.org/index.xml",
                "enable": False,
                "installNewPackages": "always",
            },
        )
        self.assertIn(("remotes", "remote1"), consumed)

    def test_snapshot_filters_reapack_and_preserves_pinned_versions(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            snapshot_path = resource_dir / "ReaPack/reaper-flake-state.json"
            snapshot_path.parent.mkdir()
            snapshot_path.write_text(
                json.dumps(
                    {
                        "formatVersion": 1,
                        "resourcePath": str(resource_dir),
                        "registryModifiedAt": 10,
                        "packages": [
                            {
                                "repository": "ReaPack",
                                "category": "Extensions",
                                "name": "ReaPack.ext",
                                "version": "1.2.6",
                                "flags": 0,
                            },
                            {
                                "repository": "Repo",
                                "category": "Scripts",
                                "name": "Latest.lua",
                                "version": "2.0",
                                "flags": 0,
                            },
                            {
                                "repository": "Repo",
                                "category": "Scripts",
                                "name": "Pinned.lua",
                                "version": "1.0",
                                "flags": 3,
                            },
                        ],
                    }
                )
            )

            decoded, diagnostics = REAPER2NIX.parse_reapack_packages(
                resource_dir, snapshot_path
            )

            exact, _ = REAPER2NIX.parse_reapack_packages(
                resource_dir, snapshot_path, exact_versions=True
            )

        self.assertEqual(diagnostics, [])
        self.assertEqual(len(decoded["packages"]), 2)
        self.assertIsNone(decoded["packages"][0]["version"])
        self.assertEqual(decoded["packages"][1]["version"], "1.0")
        self.assertTrue(decoded["packages"][1]["pin"])
        self.assertTrue(decoded["packages"][1]["enablePrereleases"])
        self.assertEqual(exact["packages"][0]["version"], "2.0")

    def test_directory_import_merges_repositories_and_packages(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema_path = resource_dir / "schema.json"
            schema_path.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "sources": {
                            "reapack.ini": {
                                "format": "ini",
                                "adapter": "ini",
                                "adapters": ["reapack"],
                            },
                            "ReaPack/reaper-flake-state.json": {
                                "format": "json",
                                "adapter": "reapack-packages",
                            },
                        },
                        "options": [],
                    }
                )
            )
            (resource_dir / "reapack.ini").write_text(
                "[remotes]\nremote0=Repo|https://example.org/index.xml|1|0\nsize=1\n"
            )
            state_dir = resource_dir / "ReaPack"
            state_dir.mkdir()
            (state_dir / "reaper-flake-state.json").write_text(
                json.dumps(
                    {
                        "formatVersion": 1,
                        "resourcePath": str(resource_dir),
                        "registryModifiedAt": 0,
                        "packages": [
                            {
                                "repository": "Repo",
                                "category": "Scripts",
                                "name": "Tool.lua",
                                "version": "1.0",
                                "flags": 0,
                            }
                        ],
                    }
                )
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir),
                    "--schema",
                    str(schema_path),
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("extensions = {", result.stdout)
        self.assertIn("reapack = {", result.stdout)
        self.assertNotIn("addDefaultRepositories", result.stdout)
        self.assertIn('name = "Tool.lua";', result.stdout)


class SourceAllowlistTests(unittest.TestCase):
    def test_mouse_source_uses_semantic_options_and_preserves_unknown_keys(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema_path = resource_dir / "schema.json"
            schema_path.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "sources": {
                            "reaper-mouse.ini": {
                                "format": "ini",
                                "adapter": "ini",
                                "adapters": ["reaper-mouse"],
                            }
                        },
                        "options": [],
                    }
                )
            )
            (resource_dir / "reaper-mouse.ini").write_text(
                "[hasimported]\n"
                "MM_CTX_ARRANGE_MMOUSE=1\n"
                "[MM_CTX_ARRANGE_MMOUSE]\n"
                "mm_0=9 m\n"
                "unknown=preserve-me\n"
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir),
                    "--schema",
                    str(schema_path),
                    "--all-keys",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

            filtered = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir),
                    "--schema",
                    str(schema_path),
                    "--options",
                    "programs.reaper.preferences.editingBehavior.mouseModifiers",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("mouseModifiers = {", result.stdout)
        self.assertIn('action = 9;', result.stdout)
        self.assertIn('mode = "m";', result.stdout)
        self.assertIn('unknown = "preserve-me";', result.stdout)
        self.assertEqual(result.stdout.count("mm_0 ="), 1)
        self.assertIn("mouseModifiers = {", filtered.stdout)
        self.assertNotIn("preserve-me", filtered.stdout)

    def test_menu_source_is_imported_through_its_semantic_adapter(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            resource_dir = Path(temporary_directory)
            schema_path = resource_dir / "schema.json"
            schema_path.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "sources": {
                            "reaper-menu.ini": {
                                "format": "ini",
                                "adapter": "ini",
                                "adapters": ["reaper-menu"],
                                "adapterConfig": {
                                    "sectionKinds": {"Main toolbar": "toolbar"},
                                    "toolbarTextIcons": {
                                        "normal": "text",
                                        "wide": "text_wide",
                                        "tooltip": "text_tt",
                                    },
                                },
                            }
                        },
                        "options": [],
                    }
                )
            )
            (resource_dir / "reaper-menu.ini").write_text(
                "[Main toolbar]\n"
                "item_0=40044 Play\n"
                "icon_0=text_wide\n"
                "tbf_0=1\n"
                "default=generated-state\n"
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(resource_dir),
                    "--schema",
                    str(schema_path),
                    "--all-keys",
                    "--options",
                    "programs.reaper.menus",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("menus = {", result.stdout)
        self.assertIn('"Main toolbar" = {', result.stdout)
        self.assertIn('textIcon = "wide";', result.stdout)
        self.assertIn("toolbarFlags = 1;", result.stdout)
        self.assertNotIn("generated-state", result.stdout)
        self.assertNotIn("reaper-menu.ini", result.stdout)

    def test_options_flag_filters_generated_output(self):
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
                        "options": [
                            {
                                "path": "preferences.general.undo.maximumUndoMemory",
                                "kind": "value",
                                "file": "reaper.ini",
                                "section": "reaper",
                                "key": "undomaxmem",
                                "codec": "integer",
                            },
                            {
                                "path": "windows.mixer.showFolders",
                                "kind": "value",
                                "file": "reaper.ini",
                                "section": "reaper",
                                "key": "showfolders",
                                "codec": "bool",
                            },
                        ],
                    }
                )
            )
            ini_path = resource_dir / "reaper.ini"
            ini_path.write_text("[reaper]\nundomaxmem=512\nshowfolders=1\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(ini_path),
                    "--schema",
                    str(schema_path),
                    "--options",
                    "programs.reaper.preferences",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("programs.reaper = {", result.stdout)
        self.assertIn("maximumUndoMemory = 512;", result.stdout)
        self.assertNotIn("windows", result.stdout)
        self.assertNotIn("showFolders", result.stdout)

    def test_all_keys_only_reads_schema_declared_ini_sources(self):
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
                    "--all-keys",
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
                    "--all-keys",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn('selected = "yes";', result.stdout)
        self.assertNotIn("sibling", result.stdout)


if __name__ == "__main__":
    unittest.main()
