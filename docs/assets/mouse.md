# REAPER Mouse Modifier Preferences

This module writes `reaper-mouse.ini`.

Use `programs.reaper.preferences.editingBehavior.mouseModifiers.importedContexts` to mark REAPER mouse contexts as imported, and `programs.reaper.preferences.editingBehavior.mouseModifiers.contexts` to bind modifiers inside those contexts.

## Basic Shape

```nix
{ reaperMouse, ... }: {
  programs.reaper.preferences.editingBehavior.mouseModifiers = {
    importedContexts = [
      reaperMouse.contexts.arrange.middleDrag
    ];

    contexts = reaperMouse.context reaperMouse.contexts.arrange.middleDrag {
      ${reaperMouse.modifiers.none} = reaperMouse.mouse 9;
    };
  };
}
```

This writes:

```ini
[hasimported]
MM_CTX_ARRANGE_MMOUSE=1

[MM_CTX_ARRANGE_MMOUSE]
mm_0=9 m
```

Read that as:

| Part                      | Meaning                                        |
| ------------------------- | ---------------------------------------------- |
| `[MM_CTX_ARRANGE_MMOUSE]` | Arrange view, middle-button drag context       |
| `mm_0`                    | No keyboard modifiers                          |
| `9`                       | REAPER's numeric action id for this context    |
| `m`                       | Mouse-modifier action, not a normal command id |

So `mm_0=9 m` means: when middle-dragging in the arrange view with no keyboard modifiers, run REAPER mouse-modifier action `9`. For this context, that is the zoom/pan middle-drag behavior.

## Options

`importedContexts`

List of raw REAPER mouse context names. The library values under `reaperMouse.contexts` are preferred.

```nix
importedContexts = [
  reaperMouse.contexts.arrange.middleDrag
  reaperMouse.contexts.mediaItem.leftClick
];
```

`contexts`

Attribute set of context names to modifier bindings.

```nix
contexts.MM_CTX_ARRANGE_MMOUSE.mm_0 = "9 m";
```

Binding values can be either a raw string:

```nix
"9 m"
```

or a structured value:

```nix
{
  action = 9;
  mode = "m";
}
```

## Actions

Use these helpers to format action values:

| Helper                      | Output      | Use                                |
| --------------------------- | ----------- | ---------------------------------- |
| `reaperMouse.mouse 9`       | `"9 m"`     | REAPER mouse modifier action       |
| `reaperMouse.command 40044` | `"40044 c"` | REAPER command/action id           |
| `reaperMouse.text "9 m"`    | `"9 m"`     | Pass a literal string              |
| `reaperMouse.raw "9 m"`     | `"9 m"`     | Pass a literal string              |

The suffix matters:

| Suffix | Meaning                                                                   |
| ------ | ------------------------------------------------------------------------- |
| `m`    | Mouse-modifier action id. These are REAPER's per-context mouse behaviors. |
| `c`    | Command/action id. These are normal REAPER actions from the Action List.  |

The numeric part of an `m` action is not self-describing in `reaper-mouse.ini`, and it is not necessarily universal across every mouse context. The context decides what the number means.

Once a value is known, prefer adding a named helper or enum to the library so future configs do not need raw numbers.

## Modifiers

Use `reaperMouse.modifiers.*` for common modifier keys.

| Name                                     | REAPER key |
| ---------------------------------------- | ---------- |
| `none`                                   | `mm_0`     |
| `shift`                                  | `mm_1`     |
| `ctrl`, `control`                        | `mm_2`     |
| `shiftCtrl`, `shiftControl`              | `mm_3`     |
| `alt`, `option`                          | `mm_4`     |
| `shiftAlt`, `shiftOption`                | `mm_5`     |
| `ctrlAlt`, `controlOption`               | `mm_6`     |
| `shiftCtrlAlt`, `shiftControlOption`     | `mm_7`     |
| `win`, `super`, `meta`, `cmd`, `command` | `mm_8`     |

For combinations not listed above, use `reaperMouse.modifier`.

```nix
${reaperMouse.modifier ["ctrl" "alt"]} = reaperMouse.command 40044;
```

Accepted modifier names are `shift`, `ctrl`, `control`, `alt`, `option`, `win`, `super`, `meta`, `cmd`, and `command`.

## Context Helpers

`reaperMouse.set`

Set one binding.

```nix
reaperMouse.set
  reaperMouse.contexts.arrange.middleDrag
  reaperMouse.modifiers.none
  (reaperMouse.mouse 9)
```

`reaperMouse.context`

Set several bindings in one context.

```nix
reaperMouse.context reaperMouse.contexts.mediaItem.leftClick {
  ${reaperMouse.modifiers.none} = reaperMouse.mouse 1;
  ${reaperMouse.modifiers.alt} = reaperMouse.mouse 2;
}
```

`reaperMouse.merge`

Merge several `reaperMouse.set` or `reaperMouse.context` blocks.

```nix
contexts = with reaperMouse; merge [
  (set contexts.arrange.middleDrag modifiers.none (mouse 9))
  (context contexts.mediaItem.leftClick {${modifiers.none} = mouse 1;})
];
```

## Examples

Middle-click drag in the arrange view to zoom and pan:

```nix
{ reaperMouse, ... }: {
  programs.reaper.preferences.editingBehavior.mouseModifiers = {
    importedContexts = [
      reaperMouse.contexts.arrange.middleDrag
    ];

    contexts = reaperMouse.set reaperMouse.contexts.arrange.middleDrag reaperMouse.modifiers.none (reaperMouse.mouse 9);
  };
}
```

Several arrange bindings:

```nix
{ reaperMouse, ... }: {
  programs.reaper.preferences.editingBehavior.mouseModifiers = {
    importedContexts = with reaperMouse; [
      contexts.arrange.middleDrag
      contexts.arrange.middleClick
      contexts.arrange.rightDrag
    ];

    contexts = with reaperMouse; merge [
      (set contexts.arrange.middleDrag modifiers.none (mouse 9))

      (context contexts.arrange.middleClick {
        ${modifiers.none} = mouse 1;
        ${modifiers.shift} = mouse 2;
      })

      (context contexts.arrange.rightDrag {
        ${modifiers.none} = raw "3 m";
        ${modifier ["ctrl" "alt"]} = command 40044;
      })
    ];
  };
}
```

Raw configuration without helpers:

```nix
{
  programs.reaper.preferences.editingBehavior.mouseModifiers = {
    importedContexts = ["MM_CTX_ARRANGE_MMOUSE"];

    contexts.MM_CTX_ARRANGE_MMOUSE = {
      mm_0 = "9 m";
      mm_1 = {
        action = 2;
        mode = "m";
      };
    };
  };
}
```

## All Contexts

| Library path                                            | REAPER context                    |
| ------------------------------------------------------- | --------------------------------- |
| `reaperMouse.contexts.areaSelection.leftDrag`                 | `MM_CTX_AREASEL`                  |
| `reaperMouse.contexts.areaSelection.leftClick`                | `MM_CTX_AREASEL_CLK`              |
| `reaperMouse.contexts.areaSelection.edgeLeftDrag`             | `MM_CTX_AREASEL_EDGE`             |
| `reaperMouse.contexts.areaSelectionEnvelope.leftDrag`         | `MM_CTX_AREASEL_ENV`              |
| `reaperMouse.contexts.arrange.altA`                           | `MM_CTX_ARRANGE_A`                |
| `reaperMouse.contexts.arrange.altB`                           | `MM_CTX_ARRANGE_B`                |
| `reaperMouse.contexts.arrange.altC`                           | `MM_CTX_ARRANGE_C`                |
| `reaperMouse.contexts.arrange.altD`                           | `MM_CTX_ARRANGE_D`                |
| `reaperMouse.contexts.arrange.middleDrag`                     | `MM_CTX_ARRANGE_MMOUSE`           |
| `reaperMouse.contexts.arrange.middleClick`                    | `MM_CTX_ARRANGE_MMOUSE_CLK`       |
| `reaperMouse.contexts.arrange.rightDrag`                      | `MM_CTX_ARRANGE_RMOUSE`           |
| `reaperMouse.contexts.crossfade.leftDrag`                     | `MM_CTX_CROSSFADE`                |
| `reaperMouse.contexts.crossfade.leftClick`                    | `MM_CTX_CROSSFADE_CLK`            |
| `reaperMouse.contexts.crossfade.doubleClick`                  | `MM_CTX_CROSSFADE_DBLCLK`         |
| `reaperMouse.contexts.editCursorHandle.leftDrag`              | `MM_CTX_CURSORHANDLE`             |
| `reaperMouse.contexts.envelopeControlPanel.doubleClick`       | `MM_CTX_ENVCP_DBLCLK`             |
| `reaperMouse.contexts.envelopeLane.leftDrag`                  | `MM_CTX_ENVLANE`                  |
| `reaperMouse.contexts.envelopeLane.doubleClick`               | `MM_CTX_ENVLANE_DBLCLK`           |
| `reaperMouse.contexts.envelopePoint.leftDrag`                 | `MM_CTX_ENVPT`                    |
| `reaperMouse.contexts.envelopePoint.doubleClick`              | `MM_CTX_ENVPT_DBLCLK`             |
| `reaperMouse.contexts.envelopeSegment.leftDrag`               | `MM_CTX_ENVSEG`                   |
| `reaperMouse.contexts.envelopeSegment.doubleClick`            | `MM_CTX_ENVSEG_DBLCLK`            |
| `reaperMouse.contexts.fader.mouseWheel`                       | `MM_CTX_FADER_MOUSEWHEEL`         |
| `reaperMouse.contexts.fixedLaneTab.leftClick`                 | `MM_CTX_FIXEDLANETAB_CLK`         |
| `reaperMouse.contexts.fixedLaneTab.doubleClick`               | `MM_CTX_FIXEDLANETAB_DBLCLK`      |
| `reaperMouse.contexts.mediaItem.leftDrag`                     | `MM_CTX_ITEM`                     |
| `reaperMouse.contexts.mediaItem.leftClick`                    | `MM_CTX_ITEM_CLK`                 |
| `reaperMouse.contexts.mediaItem.doubleClick`                  | `MM_CTX_ITEM_DBLCLK`              |
| `reaperMouse.contexts.mediaItemEdge.leftDrag`                 | `MM_CTX_ITEMEDGE`                 |
| `reaperMouse.contexts.mediaItemEdge.doubleClick`              | `MM_CTX_ITEMEDGE_DBLCLK`          |
| `reaperMouse.contexts.mediaItemFade.leftDrag`                 | `MM_CTX_ITEMFADE`                 |
| `reaperMouse.contexts.mediaItemFade.leftClick`                | `MM_CTX_ITEMFADE_CLK`             |
| `reaperMouse.contexts.mediaItemFade.doubleClick`              | `MM_CTX_ITEMFADE_DBLCLK`          |
| `reaperMouse.contexts.mediaItemLowerHalf.leftDrag`            | `MM_CTX_ITEMLOWER`                |
| `reaperMouse.contexts.mediaItemLowerHalf.leftClick`           | `MM_CTX_ITEMLOWER_CLK`            |
| `reaperMouse.contexts.mediaItemLowerHalf.doubleClick`         | `MM_CTX_ITEMLOWER_DBLCLK`         |
| `reaperMouse.contexts.mediaItemStretchMarker.leftDrag`        | `MM_CTX_ITEMSTRETCHMARKER`        |
| `reaperMouse.contexts.mediaItemStretchMarker.doubleClick`     | `MM_CTX_ITEMSTRETCHMARKER_DBLCLK` |
| `reaperMouse.contexts.mediaItemStretchMarkerRate.leftDrag`    | `MM_CTX_ITEMSTRETCHMARKERRATE`    |
| `reaperMouse.contexts.mediaItemTakeMarker.leftDrag`           | `MM_CTX_ITEMTAKEMARKER`           |
| `reaperMouse.contexts.mediaItemTakeMarker.leftClick`          | `MM_CTX_ITEMTAKEMARKER_CLK`       |
| `reaperMouse.contexts.mediaItemTakeMarker.doubleClick`        | `MM_CTX_ITEMTAKEMARKER_DBLCLK`    |
| `reaperMouse.contexts.linkedLane.leftDrag`                    | `MM_CTX_LINKEDLANE`               |
| `reaperMouse.contexts.linkedLane.leftClick`                   | `MM_CTX_LINKEDLANE_CLK`           |
| `reaperMouse.contexts.linkedLane.doubleClick`                 | `MM_CTX_LINKEDLANE_DBLCLK`        |
| `reaperMouse.contexts.marker.leftDrag`                        | `MM_CTX_MARKER`                   |
| `reaperMouse.contexts.markerLane.leftDrag`                    | `MM_CTX_MARKERLANES`              |
| `reaperMouse.contexts.markerRegionEdge.leftDrag`              | `MM_CTX_MARKER_REGIONEDGE`        |
| `reaperMouse.contexts.mixerControlPanel.doubleClick`          | `MM_CTX_MCP_DBLCLK`               |
| `reaperMouse.contexts.mixerControlPanel.faderMouseWheel`      | `MM_CTX_MCP_FADER_MOUSEWHEEL`     |
| `reaperMouse.contexts.mixerControlPanel.horizontalMouseWheel` | `MM_CTX_MCP_MOUSEHWHEEL`          |
| `reaperMouse.contexts.mixerControlPanel.mouseWheel`           | `MM_CTX_MCP_MOUSEWHEEL`           |
| `reaperMouse.contexts.midiCcEvent.leftDrag`                   | `MM_CTX_MIDI_CCEVT`               |
| `reaperMouse.contexts.midiCcEvent.doubleClick`                | `MM_CTX_MIDI_CCEVT_DBLCLK`        |
| `reaperMouse.contexts.midiCcLane.leftDrag`                    | `MM_CTX_MIDI_CCLANE`              |
| `reaperMouse.contexts.midiCcLane.doubleClick`                 | `MM_CTX_MIDI_CCLANE_DBLCLK`       |
| `reaperMouse.contexts.midiCcSegment.leftDrag`                 | `MM_CTX_MIDI_CCSEG`               |
| `reaperMouse.contexts.midiCcSegment.doubleClick`              | `MM_CTX_MIDI_CCSEG_DBLCLK`        |
| `reaperMouse.contexts.midiEndPointer.leftDrag`                | `MM_CTX_MIDI_ENDPTR`              |
| `reaperMouse.contexts.midiMarkerLane.leftDrag`                | `MM_CTX_MIDI_MARKERLANES`         |
| `reaperMouse.contexts.midiNote.leftDrag`                      | `MM_CTX_MIDI_NOTE`                |
| `reaperMouse.contexts.midiNote.leftClick`                     | `MM_CTX_MIDI_NOTE_CLK`            |
| `reaperMouse.contexts.midiNote.doubleClick`                   | `MM_CTX_MIDI_NOTE_DBLCLK`         |
| `reaperMouse.contexts.midiNoteEdge.leftDrag`                  | `MM_CTX_MIDI_NOTEEDGE`            |
| `reaperMouse.contexts.midiPianoRoll.leftDrag`                 | `MM_CTX_MIDI_PIANOROLL`           |
| `reaperMouse.contexts.midiPianoRoll.leftClick`                | `MM_CTX_MIDI_PIANOROLL_CLK`       |
| `reaperMouse.contexts.midiPianoRoll.doubleClick`              | `MM_CTX_MIDI_PIANOROLL_DBLCLK`    |
| `reaperMouse.contexts.midiPianoRoll.rightDrag`                | `MM_CTX_MIDI_RMOUSE`              |
| `reaperMouse.contexts.midiRuler.leftDrag`                     | `MM_CTX_MIDI_RULER`               |
| `reaperMouse.contexts.midiRuler.leftClick`                    | `MM_CTX_MIDI_RULER_CLK`           |
| `reaperMouse.contexts.midiRuler.doubleClick`                  | `MM_CTX_MIDI_RULER_DBLCLK`        |
| `reaperMouse.contexts.pooledAutomationItem.leftDrag`          | `MM_CTX_POOLEDENV`                |
| `reaperMouse.contexts.pooledAutomationItem.doubleClick`       | `MM_CTX_POOLEDENV_DBLCLK`         |
| `reaperMouse.contexts.pooledAutomationItemEdge.leftDrag`      | `MM_CTX_POOLEDENVEDGE`            |
| `reaperMouse.contexts.region.leftDrag`                        | `MM_CTX_REGION`                   |
| `reaperMouse.contexts.regionMarker.leftClick`                 | `MM_CTX_REGION_MARKER_CLK`        |
| `reaperMouse.contexts.regionMarker.doubleClick`               | `MM_CTX_REGION_MARKER_DBLCLK`     |
| `reaperMouse.contexts.ruler.leftDrag`                         | `MM_CTX_RULER`                    |
| `reaperMouse.contexts.ruler.leftClick`                        | `MM_CTX_RULER_CLK`                |
| `reaperMouse.contexts.ruler.doubleClick`                      | `MM_CTX_RULER_DBLCLK`             |
| `reaperMouse.contexts.rulerLaneHeader.doubleClick`            | `MM_CTX_RULERLANE_HDR_DBLCLK`     |
| `reaperMouse.contexts.sampleEdit.leftDrag`                    | `MM_CTX_SAMPLEEDIT`               |
| `reaperMouse.contexts.tempoMarker.leftDrag`                   | `MM_CTX_TEMPOMARKER`              |
| `reaperMouse.contexts.track.leftDrag`                         | `MM_CTX_TRACK`                    |
| `reaperMouse.contexts.track.leftClick`                        | `MM_CTX_TRACK_CLK`                |
| `reaperMouse.contexts.track.doubleClick`                      | `MM_CTX_TRACK_DBLCLK`             |
| `reaperMouse.contexts.trackControlPanel.doubleClick`          | `MM_CTX_TCP_DBLCLK`               |
| `reaperMouse.contexts.trackControlPanel.faderMouseWheel`      | `MM_CTX_TCP_FADER_MOUSEWHEEL`     |
| `reaperMouse.contexts.trackControlPanel.horizontalMouseWheel` | `MM_CTX_TCP_MOUSEHWHEEL`          |
| `reaperMouse.contexts.trackControlPanel.mouseWheel`           | `MM_CTX_TCP_MOUSEWHEEL`           |
