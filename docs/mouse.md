# REAPER Mouse Preferences

This module writes `reaper-mouse.ini`.

Use `programs.reaper.preferences.mouse.importedContexts` to mark REAPER mouse contexts as imported, and `programs.reaper.preferences.mouse.contexts` to bind modifiers inside those contexts.

## Basic Shape

```nix
{ reaperMouse, ... }:

let
  mouse = reaperMouse;
in {
  programs.reaper.preferences.mouse = {
    importedContexts = [
      mouse.contexts.arrange.middleDrag
    ];

    contexts = mouse.context mouse.contexts.arrange.middleDrag {
      ${mouse.modifiers.none} = mouse.mouse 9;
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

| Helper                | Output      | Use                          |
| --------------------- | ----------- | ---------------------------- |
| `mouse.mouse 9`       | `"9 m"`     | REAPER mouse modifier action |
| `mouse.command 40044` | `"40044 c"` | REAPER command/action id     |
| `mouse.text "9 m"`    | `"9 m"`     | Pass a literal string        |
| `mouse.raw "9 m"`     | `"9 m"`     | Pass a literal string        |

The suffix matters:

| Suffix | Meaning                                                                   |
| ------ | ------------------------------------------------------------------------- |
| `m`    | Mouse-modifier action id. These are REAPER's per-context mouse behaviors. |
| `c`    | Command/action id. These are normal REAPER actions from the Action List.  |

The numeric part of an `m` action is not self-describing in `reaper-mouse.ini`, and it is not necessarily universal across every mouse context. The context decides what the number means.

Once a value is known, prefer adding a named helper or enum to the library so future configs do not need raw numbers.

## Modifiers

Use `mouse.modifiers.*` for common modifier keys.

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

For combinations not listed above, use `mouse.modifier`.

```nix
${mouse.modifier ["ctrl" "alt"]} = mouse.command 40044;
```

Accepted modifier names are `shift`, `ctrl`, `control`, `alt`, `option`, `win`, `super`, `meta`, `cmd`, and `command`.

## Context Helpers

`mouse.set`

Set one binding.

```nix
mouse.set
  mouse.contexts.arrange.middleDrag
  mouse.modifiers.none
  (mouse.mouse 9)
```

`mouse.context`

Set several bindings in one context.

```nix
mouse.context mouse.contexts.mediaItem.leftClick {
  ${mouse.modifiers.none} = mouse.mouse 1;
  ${mouse.modifiers.alt} = mouse.mouse 2;
}
```

`mouse.merge`

Merge several `mouse.set` or `mouse.context` blocks.

```nix
contexts = mouse.merge [
  (mouse.set mouse.contexts.arrange.middleDrag mouse.modifiers.none (mouse.mouse 9))
  (mouse.context mouse.contexts.mediaItem.leftClick {
    ${mouse.modifiers.none} = mouse.mouse 1;
  })
];
```

## Examples

Middle-click drag in the arrange view to zoom and pan:

```nix
{ reaperMouse, ... }:

let
  mouse = reaperMouse;
in {
  programs.reaper.preferences.mouse = {
    importedContexts = [
      mouse.contexts.arrange.middleDrag
    ];

    contexts = mouse.set
      mouse.contexts.arrange.middleDrag
      mouse.modifiers.none
      (mouse.mouse 9);
  };
}
```

Several arrange bindings:

```nix
{ reaperMouse, ... }:

let
  mouse = reaperMouse;
in {
  programs.reaper.preferences.mouse = {
    importedContexts = [
      mouse.contexts.arrange.middleDrag
      mouse.contexts.arrange.middleClick
      mouse.contexts.arrange.rightDrag
    ];

    contexts = mouse.merge [
      (mouse.set mouse.contexts.arrange.middleDrag mouse.modifiers.none (mouse.mouse 9))

      (mouse.context mouse.contexts.arrange.middleClick {
        ${mouse.modifiers.none} = mouse.mouse 1;
        ${mouse.modifiers.shift} = mouse.mouse 2;
      })

      (mouse.context mouse.contexts.arrange.rightDrag {
        ${mouse.modifiers.none} = mouse.raw "3 m";
        ${mouse.modifier ["ctrl" "alt"]} = mouse.command 40044;
      })
    ];
  };
}
```

Raw configuration without helpers:

```nix
{
  programs.reaper.preferences.mouse = {
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
| `mouse.contexts.areaSelection.leftDrag`                 | `MM_CTX_AREASEL`                  |
| `mouse.contexts.areaSelection.leftClick`                | `MM_CTX_AREASEL_CLK`              |
| `mouse.contexts.areaSelection.edgeLeftDrag`             | `MM_CTX_AREASEL_EDGE`             |
| `mouse.contexts.areaSelectionEnvelope.leftDrag`         | `MM_CTX_AREASEL_ENV`              |
| `mouse.contexts.arrange.altA`                           | `MM_CTX_ARRANGE_A`                |
| `mouse.contexts.arrange.altB`                           | `MM_CTX_ARRANGE_B`                |
| `mouse.contexts.arrange.altC`                           | `MM_CTX_ARRANGE_C`                |
| `mouse.contexts.arrange.altD`                           | `MM_CTX_ARRANGE_D`                |
| `mouse.contexts.arrange.middleDrag`                     | `MM_CTX_ARRANGE_MMOUSE`           |
| `mouse.contexts.arrange.middleClick`                    | `MM_CTX_ARRANGE_MMOUSE_CLK`       |
| `mouse.contexts.arrange.rightDrag`                      | `MM_CTX_ARRANGE_RMOUSE`           |
| `mouse.contexts.crossfade.leftDrag`                     | `MM_CTX_CROSSFADE`                |
| `mouse.contexts.crossfade.leftClick`                    | `MM_CTX_CROSSFADE_CLK`            |
| `mouse.contexts.crossfade.doubleClick`                  | `MM_CTX_CROSSFADE_DBLCLK`         |
| `mouse.contexts.editCursorHandle.leftDrag`              | `MM_CTX_CURSORHANDLE`             |
| `mouse.contexts.envelopeControlPanel.doubleClick`       | `MM_CTX_ENVCP_DBLCLK`             |
| `mouse.contexts.envelopeLane.leftDrag`                  | `MM_CTX_ENVLANE`                  |
| `mouse.contexts.envelopeLane.doubleClick`               | `MM_CTX_ENVLANE_DBLCLK`           |
| `mouse.contexts.envelopePoint.leftDrag`                 | `MM_CTX_ENVPT`                    |
| `mouse.contexts.envelopePoint.doubleClick`              | `MM_CTX_ENVPT_DBLCLK`             |
| `mouse.contexts.envelopeSegment.leftDrag`               | `MM_CTX_ENVSEG`                   |
| `mouse.contexts.envelopeSegment.doubleClick`            | `MM_CTX_ENVSEG_DBLCLK`            |
| `mouse.contexts.fader.mouseWheel`                       | `MM_CTX_FADER_MOUSEWHEEL`         |
| `mouse.contexts.fixedLaneTab.leftClick`                 | `MM_CTX_FIXEDLANETAB_CLK`         |
| `mouse.contexts.fixedLaneTab.doubleClick`               | `MM_CTX_FIXEDLANETAB_DBLCLK`      |
| `mouse.contexts.mediaItem.leftDrag`                     | `MM_CTX_ITEM`                     |
| `mouse.contexts.mediaItem.leftClick`                    | `MM_CTX_ITEM_CLK`                 |
| `mouse.contexts.mediaItem.doubleClick`                  | `MM_CTX_ITEM_DBLCLK`              |
| `mouse.contexts.mediaItemEdge.leftDrag`                 | `MM_CTX_ITEMEDGE`                 |
| `mouse.contexts.mediaItemEdge.doubleClick`              | `MM_CTX_ITEMEDGE_DBLCLK`          |
| `mouse.contexts.mediaItemFade.leftDrag`                 | `MM_CTX_ITEMFADE`                 |
| `mouse.contexts.mediaItemFade.leftClick`                | `MM_CTX_ITEMFADE_CLK`             |
| `mouse.contexts.mediaItemFade.doubleClick`              | `MM_CTX_ITEMFADE_DBLCLK`          |
| `mouse.contexts.mediaItemLowerHalf.leftDrag`            | `MM_CTX_ITEMLOWER`                |
| `mouse.contexts.mediaItemLowerHalf.leftClick`           | `MM_CTX_ITEMLOWER_CLK`            |
| `mouse.contexts.mediaItemLowerHalf.doubleClick`         | `MM_CTX_ITEMLOWER_DBLCLK`         |
| `mouse.contexts.mediaItemStretchMarker.leftDrag`        | `MM_CTX_ITEMSTRETCHMARKER`        |
| `mouse.contexts.mediaItemStretchMarker.doubleClick`     | `MM_CTX_ITEMSTRETCHMARKER_DBLCLK` |
| `mouse.contexts.mediaItemStretchMarkerRate.leftDrag`    | `MM_CTX_ITEMSTRETCHMARKERRATE`    |
| `mouse.contexts.mediaItemTakeMarker.leftDrag`           | `MM_CTX_ITEMTAKEMARKER`           |
| `mouse.contexts.mediaItemTakeMarker.leftClick`          | `MM_CTX_ITEMTAKEMARKER_CLK`       |
| `mouse.contexts.mediaItemTakeMarker.doubleClick`        | `MM_CTX_ITEMTAKEMARKER_DBLCLK`    |
| `mouse.contexts.linkedLane.leftDrag`                    | `MM_CTX_LINKEDLANE`               |
| `mouse.contexts.linkedLane.leftClick`                   | `MM_CTX_LINKEDLANE_CLK`           |
| `mouse.contexts.linkedLane.doubleClick`                 | `MM_CTX_LINKEDLANE_DBLCLK`        |
| `mouse.contexts.marker.leftDrag`                        | `MM_CTX_MARKER`                   |
| `mouse.contexts.markerLane.leftDrag`                    | `MM_CTX_MARKERLANES`              |
| `mouse.contexts.markerRegionEdge.leftDrag`              | `MM_CTX_MARKER_REGIONEDGE`        |
| `mouse.contexts.mixerControlPanel.doubleClick`          | `MM_CTX_MCP_DBLCLK`               |
| `mouse.contexts.mixerControlPanel.faderMouseWheel`      | `MM_CTX_MCP_FADER_MOUSEWHEEL`     |
| `mouse.contexts.mixerControlPanel.horizontalMouseWheel` | `MM_CTX_MCP_MOUSEHWHEEL`          |
| `mouse.contexts.mixerControlPanel.mouseWheel`           | `MM_CTX_MCP_MOUSEWHEEL`           |
| `mouse.contexts.midiCcEvent.leftDrag`                   | `MM_CTX_MIDI_CCEVT`               |
| `mouse.contexts.midiCcEvent.doubleClick`                | `MM_CTX_MIDI_CCEVT_DBLCLK`        |
| `mouse.contexts.midiCcLane.leftDrag`                    | `MM_CTX_MIDI_CCLANE`              |
| `mouse.contexts.midiCcLane.doubleClick`                 | `MM_CTX_MIDI_CCLANE_DBLCLK`       |
| `mouse.contexts.midiCcSegment.leftDrag`                 | `MM_CTX_MIDI_CCSEG`               |
| `mouse.contexts.midiCcSegment.doubleClick`              | `MM_CTX_MIDI_CCSEG_DBLCLK`        |
| `mouse.contexts.midiEndPointer.leftDrag`                | `MM_CTX_MIDI_ENDPTR`              |
| `mouse.contexts.midiMarkerLane.leftDrag`                | `MM_CTX_MIDI_MARKERLANES`         |
| `mouse.contexts.midiNote.leftDrag`                      | `MM_CTX_MIDI_NOTE`                |
| `mouse.contexts.midiNote.leftClick`                     | `MM_CTX_MIDI_NOTE_CLK`            |
| `mouse.contexts.midiNote.doubleClick`                   | `MM_CTX_MIDI_NOTE_DBLCLK`         |
| `mouse.contexts.midiNoteEdge.leftDrag`                  | `MM_CTX_MIDI_NOTEEDGE`            |
| `mouse.contexts.midiPianoRoll.leftDrag`                 | `MM_CTX_MIDI_PIANOROLL`           |
| `mouse.contexts.midiPianoRoll.leftClick`                | `MM_CTX_MIDI_PIANOROLL_CLK`       |
| `mouse.contexts.midiPianoRoll.doubleClick`              | `MM_CTX_MIDI_PIANOROLL_DBLCLK`    |
| `mouse.contexts.midiPianoRoll.rightDrag`                | `MM_CTX_MIDI_RMOUSE`              |
| `mouse.contexts.midiRuler.leftDrag`                     | `MM_CTX_MIDI_RULER`               |
| `mouse.contexts.midiRuler.leftClick`                    | `MM_CTX_MIDI_RULER_CLK`           |
| `mouse.contexts.midiRuler.doubleClick`                  | `MM_CTX_MIDI_RULER_DBLCLK`        |
| `mouse.contexts.pooledAutomationItem.leftDrag`          | `MM_CTX_POOLEDENV`                |
| `mouse.contexts.pooledAutomationItem.doubleClick`       | `MM_CTX_POOLEDENV_DBLCLK`         |
| `mouse.contexts.pooledAutomationItemEdge.leftDrag`      | `MM_CTX_POOLEDENVEDGE`            |
| `mouse.contexts.region.leftDrag`                        | `MM_CTX_REGION`                   |
| `mouse.contexts.regionMarker.leftClick`                 | `MM_CTX_REGION_MARKER_CLK`        |
| `mouse.contexts.regionMarker.doubleClick`               | `MM_CTX_REGION_MARKER_DBLCLK`     |
| `mouse.contexts.ruler.leftDrag`                         | `MM_CTX_RULER`                    |
| `mouse.contexts.ruler.leftClick`                        | `MM_CTX_RULER_CLK`                |
| `mouse.contexts.ruler.doubleClick`                      | `MM_CTX_RULER_DBLCLK`             |
| `mouse.contexts.rulerLaneHeader.doubleClick`            | `MM_CTX_RULERLANE_HDR_DBLCLK`     |
| `mouse.contexts.sampleEdit.leftDrag`                    | `MM_CTX_SAMPLEEDIT`               |
| `mouse.contexts.tempoMarker.leftDrag`                   | `MM_CTX_TEMPOMARKER`              |
| `mouse.contexts.track.leftDrag`                         | `MM_CTX_TRACK`                    |
| `mouse.contexts.track.leftClick`                        | `MM_CTX_TRACK_CLK`                |
| `mouse.contexts.track.doubleClick`                      | `MM_CTX_TRACK_DBLCLK`             |
| `mouse.contexts.trackControlPanel.doubleClick`          | `MM_CTX_TCP_DBLCLK`               |
| `mouse.contexts.trackControlPanel.faderMouseWheel`      | `MM_CTX_TCP_FADER_MOUSEWHEEL`     |
| `mouse.contexts.trackControlPanel.horizontalMouseWheel` | `MM_CTX_TCP_MOUSEHWHEEL`          |
| `mouse.contexts.trackControlPanel.mouseWheel`           | `MM_CTX_TCP_MOUSEWHEEL`           |

