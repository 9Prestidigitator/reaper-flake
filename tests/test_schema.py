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

    def test_item_fade_defaults_have_forward_and_reverse_metadata(self):
        options = {option["path"]: option for option in self.schema["options"]}
        prefix = "preferences.project.itemFadeDefaults"

        lengths = {
            f"{prefix}.defaultFadeInFadeOutLength": "deffadelen",
            f"{prefix}.defaultCrossfadeLength": "defsplitxfadelen",
            f"{prefix}.defaultStretchMarkerFadeSizeForNewItem": "stretchmarkerfade",
        }
        for path, key in lengths.items():
            with self.subTest(path=path):
                self.assertEqual(options[path]["kind"], "value")
                self.assertEqual(options[path]["key"], key)
                self.assertEqual(options[path]["codec"], "float")

        pixels = options[f"{prefix}.limitSplitCreatedFadeCrossfadeTo.pixels"]
        self.assertEqual(pixels["kind"], "value")
        self.assertEqual(pixels["key"], "splitmaxpix")
        self.assertEqual(pixels["codec"], "integer")

        booleans = {
            f"{prefix}.importedMediaItems.fadeInFadeOut": (65568, 65536, 32),
            f"{prefix}.recordedMediaItems.fadeInFadeOut": (16384, 0, 16384),
            f"{prefix}.splitMediaItems.fadeInFadeOut": (8, 0, 8),
            f"{prefix}.fixedLaneCompAreas": (128, 0, 128),
            f"{prefix}.limitSplitCreatedFadeCrossfadeTo.enable": (256, 256, 0),
            f"{prefix}.rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade": (
                16,
                16,
                0,
            ),
            f"{prefix}.applyFadeInFadeOutCrossfadePreferencesToMidiItems": (
                2,
                2,
                0,
            ),
        }
        for path, (mask, true_value, false_value) in booleans.items():
            with self.subTest(path=path):
                self.assertEqual(options[path]["kind"], "bitfield")
                self.assertEqual(options[path]["key"], "splitautoxfade")
                self.assertEqual(options[path]["mask"], mask)
                self.assertEqual(options[path]["valueType"], "bool")
                self.assertEqual(options[path]["trueValue"], true_value)
                self.assertEqual(options[path]["falseValue"], false_value)

        enums = {
            f"{prefix}.recordedMediaItems.overlap": (
                3072,
                {
                    "noCrossfade": 0,
                    "overlapAndCrossfade": 1024,
                    "respectToolbarAutoCrossfadeButton": 2048,
                },
            ),
            f"{prefix}.splitMediaItems.overlap": (
                513,
                {
                    "noCrossfade": 0,
                    "overlapAndCrossfade": 1,
                    "respectToolbarAutoCrossfadeButton": 512,
                },
            ),
            f"{prefix}.splitMediaItems.overlapCrossfadePosition": (
                393216,
                {"left": 131072, "center": 262144, "right": 0},
            ),
            f"{prefix}.trimContentBehindMediaEditsEnabled": (
                12288,
                {
                    "noCrossfade": 8192,
                    "overlapAndCrossfade": 4096,
                    "respectToolbarAutoCrossfadeButton": 0,
                },
            ),
            f"{prefix}.trimContentBehindRazorEditsEnabled": (
                32832,
                {
                    "noCrossfade": 0,
                    "overlapAndCrossfade": 64,
                    "respectToolbarAutoCrossfadeButton": 32768,
                },
            ),
        }
        for path, (mask, import_values) in enums.items():
            with self.subTest(path=path):
                option = options[path]
                self.assertEqual(option["mask"], mask)
                self.assertEqual(option["valueType"], "enum")
                self.assertEqual(option["importValues"], import_values)

    def test_audio_and_appearance_page_options_are_in_reverse_schema(self):
        options = {option["path"]: option for option in self.schema["options"]}
        expected_paths = {
            "preferences.appearance.tooltips.uiElements",
            "preferences.appearance.tooltips.itemsEnvelopes",
            "preferences.appearance.tooltips.envsOnHover",
            "preferences.appearance.tooltips.peakAndLoudnessValueWhenMouseIsOverMediaItems",
            "preferences.appearance.tooltips.delay",
            "preferences.appearance.fasterTextRendering",
            "preferences.appearance.drawVerticalTextBottomUp",
            "preferences.appearance.framelessFloatingToolbarWindows",
            "preferences.appearance.dontScaleToolbarButtonsBelow1to1",
            "preferences.appearance.dontScaleToolbarButtonsAbove1to1",
            "preferences.appearance.dontAnimateArmedActionToolbarButtons",
            "preferences.appearance.dontAnimateAnyToolbarButtons",
            "preferences.appearance.verticalSpaceAtBottomOfTrackNumber",
            "preferences.appearance.visualTrackSpacerSize",
            "preferences.appearance.limitTcpSpacerHeightToLaneSize",
            "preferences.appearance.antialiasedFadesAndEnvelopes",
            "preferences.appearance.horizontalGridLinesInAutomationLanes",
            "preferences.appearance.filledAutomationEnvelopes",
            "preferences.appearance.filledEnvelopesWhenDrawnOverMedia",
            "preferences.appearance.envelopePointSizeScaling",
            "preferences.appearance.scaleNonSelectedPoint",
            "preferences.appearance.hightlightEditCursorOverLastSelectedTrack",
            "preferences.appearance.showGuideLinesWhenEditing",
            "preferences.appearance.solidEdgeOnTimeSelectionHighlight",
            "preferences.appearance.solidEdgeOnLoopSelection",
            "preferences.appearance.displayVerticalLineAtMousePosition.enable",
            "preferences.appearance.displayVerticalLineAtMousePosition.snap",
            "preferences.appearance.playCursorWidth",
            "preferences.appearance.hideDockerTabsWhenSingleWindowAndSmallerThanPixels",
            "preferences.audio.closeAudioDeviceWhenStoppedAndApplicationIsInactive",
            "preferences.audio.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed",
            "preferences.audio.closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened",
            "preferences.audio.closeAudioDeviceWhenStoppedAndActive",
            "preferences.audio.warnWhenUnableToOpenAudioDevices",
            "preferences.audio.warnWhenUnableToOpenMidiDevices",
            "preferences.audio.warnWhenEnabledMidiDevicesAreNotPresent",
            "preferences.audio.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.enable",
            "preferences.audio.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.ms",
            "preferences.audio.onlyBypassWhileActuallyRecording",
            "preferences.audio.temporarilyBypassOversamplingOnRecordArmAffectedTrack",
            "preferences.audio.autoBypassFxEvenWhenFxConfigurationOpen",
            "preferences.audio.stopProcessingAudioWhileWarningOfFailedDiskWrites",
            "preferences.audio.virtualLoopbackAudioHardwareChannel",
            "preferences.audio.channelNamingMapping.inputChannelNameAliasingRemapping.enable",
            "preferences.audio.channelNamingMapping.outputChannelNameAliasingRemapping.enable",
            "preferences.audio.channelNamingMapping.showNonStandardStereoChannelPairs",
            "preferences.audio.channelNamingMapping.defaultMetronomeOutput",
        }
        self.assertEqual(expected_paths - set(options), set())

        snap = options[
            "preferences.appearance.displayVerticalLineAtMousePosition.snap"
        ]
        self.assertEqual(snap["key"], "guidelines2")
        self.assertEqual(snap["mask"], 224)
        self.assertEqual(
            snap["importValues"],
            {
                "doNotSnapIndicatorLine": 0,
                "respectToolbarSnapButton": 32,
                "ignoreSnapIfShiftKeyHeld": 96,
                "ignoreSnapIfControlKeyHeld": 160,
                "ignoreSnapIfShiftOrControlKeyHeld": 224,
            },
        )

        pdc = options[
            "preferences.audio.autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds.ms"
        ]
        self.assertEqual(pdc["key"], "pdcautobypassms")
        self.assertEqual(pdc["codec"], "float")

    def test_migrated_preferences_are_in_the_reverse_schema(self):
        paths = {option["path"] for option in self.schema["options"]}
        assignment_paths = {
            path
            for option in self.schema["options"]
            for assignments in (option.get("importAssignments") or {}).values()
            for path in assignments
        }
        managed = paths | assignment_paths

        expected = {
            "preferences.appearance.trackControlPanels.groupFxParametersWithInserts",
            "preferences.appearance.trackControlPanels.panFaderUnitDisplay",
            "preferences.appearance.trackControlPanels.volumeFaderRange.minimum",
            "preferences.appearance.zoomScrollOffset.verticalZoomCenter",
            "preferences.appearance.zoomScrollOffset.verticalScrollStep.trackHeight",
            "preferences.controlOscWeb.closeControlSurfaceDevicesWhenRendering",
            "preferences.controlOscWeb.controlSurfaceDisplayUpdateFrequency",
            "preferences.general.advancedUiSystemTweaks.cpuAffinity.cpuIndexes",
            "preferences.general.advancedUiSystemTweaks.uiScale",
            "preferences.general.keyboardMultitouch.multitouch.swipe.gearing",
            "preferences.general.languagePack",
            "preferences.general.paths.defaultProjectSavePath",
            "preferences.general.preventOsScreensaverWhenAudioActiveOrRendering",
            "preferences.general.startupSettings.skipAnimation",
            "preferences.project.backups.autoSave.autoSaveInterval.mode",
            "preferences.project.backups.whenSaving.preservePreviousVersionAsRppBak",
            "preferences.project.defaultProjectTemplate",
            "preferences.project.itemFadeDefaults.defaultCrossfadeLength",
            "preferences.project.itemFadeDefaults.defaultCrossfadeShape",
            "preferences.project.itemFadeDefaults.defaultFadeInFadeOutLength",
            "preferences.project.itemFadeDefaults.defaultFadeInFadeOutShape",
            "preferences.project.itemFadeDefaults.defaultStretchMarkerFadeSizeForNewItem",
            "preferences.project.itemFadeDefaults.applyFadeInFadeOutCrossfadePreferencesToMidiItems",
            "preferences.project.itemFadeDefaults.fixedLaneCompAreas",
            "preferences.project.itemFadeDefaults.importedMediaItems.fadeInFadeOut",
            "preferences.project.itemFadeDefaults.limitSplitCreatedFadeCrossfadeTo.enable",
            "preferences.project.itemFadeDefaults.limitSplitCreatedFadeCrossfadeTo.pixels",
            "preferences.project.itemFadeDefaults.recordedMediaItems.fadeInFadeOut",
            "preferences.project.itemFadeDefaults.recordedMediaItems.overlap",
            "preferences.project.itemFadeDefaults.rightClickOnCrossfadeSetsFadeShapeForOnlyOneSideOfTheCrossfade",
            "preferences.project.itemFadeDefaults.splitMediaItems.fadeInFadeOut",
            "preferences.project.itemFadeDefaults.splitMediaItems.overlap",
            "preferences.project.itemFadeDefaults.splitMediaItems.overlapCrossfadePosition",
            "preferences.project.itemFadeDefaults.trimContentBehindMediaEditsEnabled",
            "preferences.project.itemFadeDefaults.trimContentBehindRazorEditsEnabled",
            "preferences.project.itemLoopDefaults.loopSourceFor.gluedItems",
            "preferences.project.itemLoopDefaults.loopSourceFor.importedItems",
            "preferences.project.itemLoopDefaults.loopSourceFor.midiItems",
            "preferences.project.itemLoopDefaults.loopSourceFor.recordedItems",
            "preferences.project.itemLoopDefaults.timeSelectionAutoPunchAudioRecordingCreatesLoopableSelection",
            "preferences.project.projectLoading.promptWhenFilesAreNotFound",
            "preferences.project.projectSaving.saveNewVersionSuffix",
            "preferences.project.trackSendDefaults.fixedItemLanes",
        }

        self.assertEqual(expected - managed, set())
        self.assertNotIn("preferences.controlOscWeb.controlSurfaces", managed)

    def test_every_bitfield_has_reverse_decoding_metadata(self):
        incomplete = [
            option["path"]
            for option in self.schema["options"]
            if option["kind"] == "bitfield" and option["valueType"] is None
        ]
        self.assertEqual(incomplete, [])


if __name__ == "__main__":
    unittest.main()
