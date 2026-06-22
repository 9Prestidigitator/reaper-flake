{lib}: let
  inherit (lib) mapAttrs recursiveUpdate toLower;

  modifierValues = {
    shift = 1;
    ctrl = 2;
    control = 2;
    alt = 4;
    option = 4;
    win = 8;
    super = 8;
    meta = 8;
    cmd = 8;
    command = 8;
  };

  normalize = value: toLower (builtins.replaceStrings ["-" "_" " "] ["" "" ""] value);

  modifierValueFor = modifier: let
    normalized = normalize modifier;
  in
    if builtins.hasAttr normalized modifierValues
    then builtins.getAttr normalized modifierValues
    else throw "Unsupported REAPER mouse modifier `${modifier}`.";

  modifierFlagFor = modifiers:
    builtins.foldl' (total: modifier: total + modifierValueFor modifier) 0 modifiers;
in {
  contexts = {
    areaSelection = {
      leftDrag = "MM_CTX_AREASEL";
      leftClick = "MM_CTX_AREASEL_CLK";
      edgeLeftDrag = "MM_CTX_AREASEL_EDGE";
    };
    areaSelectionEnvelope.leftDrag = "MM_CTX_AREASEL_ENV";
    arrange = {
      altA = "MM_CTX_ARRANGE_A";
      altB = "MM_CTX_ARRANGE_B";
      altC = "MM_CTX_ARRANGE_C";
      altD = "MM_CTX_ARRANGE_D";
      middleDrag = "MM_CTX_ARRANGE_MMOUSE";
      middleClick = "MM_CTX_ARRANGE_MMOUSE_CLK";
      rightDrag = "MM_CTX_ARRANGE_RMOUSE";
    };
    crossfade = {
      leftDrag = "MM_CTX_CROSSFADE";
      leftClick = "MM_CTX_CROSSFADE_CLK";
      doubleClick = "MM_CTX_CROSSFADE_DBLCLK";
    };
    editCursorHandle.leftDrag = "MM_CTX_CURSORHANDLE";
    envelopeControlPanel.doubleClick = "MM_CTX_ENVCP_DBLCLK";
    envelopeLane = {
      leftDrag = "MM_CTX_ENVLANE";
      doubleClick = "MM_CTX_ENVLANE_DBLCLK";
    };
    envelopePoint = {
      leftDrag = "MM_CTX_ENVPT";
      doubleClick = "MM_CTX_ENVPT_DBLCLK";
    };
    envelopeSegment = {
      leftDrag = "MM_CTX_ENVSEG";
      doubleClick = "MM_CTX_ENVSEG_DBLCLK";
    };
    fader.mouseWheel = "MM_CTX_FADER_MOUSEWHEEL";
    fixedLaneTab = {
      leftClick = "MM_CTX_FIXEDLANETAB_CLK";
      doubleClick = "MM_CTX_FIXEDLANETAB_DBLCLK";
    };
    mediaItem = {
      leftDrag = "MM_CTX_ITEM";
      leftClick = "MM_CTX_ITEM_CLK";
      doubleClick = "MM_CTX_ITEM_DBLCLK";
    };
    mediaItemEdge = {
      leftDrag = "MM_CTX_ITEMEDGE";
      doubleClick = "MM_CTX_ITEMEDGE_DBLCLK";
    };
    mediaItemFade = {
      leftDrag = "MM_CTX_ITEMFADE";
      leftClick = "MM_CTX_ITEMFADE_CLK";
      doubleClick = "MM_CTX_ITEMFADE_DBLCLK";
    };
    mediaItemLowerHalf = {
      leftDrag = "MM_CTX_ITEMLOWER";
      leftClick = "MM_CTX_ITEMLOWER_CLK";
      doubleClick = "MM_CTX_ITEMLOWER_DBLCLK";
    };
    mediaItemStretchMarker = {
      leftDrag = "MM_CTX_ITEMSTRETCHMARKER";
      doubleClick = "MM_CTX_ITEMSTRETCHMARKER_DBLCLK";
    };
    mediaItemStretchMarkerRate.leftDrag = "MM_CTX_ITEMSTRETCHMARKERRATE";
    mediaItemTakeMarker = {
      leftDrag = "MM_CTX_ITEMTAKEMARKER";
      leftClick = "MM_CTX_ITEMTAKEMARKER_CLK";
      doubleClick = "MM_CTX_ITEMTAKEMARKER_DBLCLK";
    };
    linkedLane = {
      leftDrag = "MM_CTX_LINKEDLANE";
      leftClick = "MM_CTX_LINKEDLANE_CLK";
      doubleClick = "MM_CTX_LINKEDLANE_DBLCLK";
    };
    marker.leftDrag = "MM_CTX_MARKER";
    markerLane.leftDrag = "MM_CTX_MARKERLANES";
    markerRegionEdge.leftDrag = "MM_CTX_MARKER_REGIONEDGE";
    mixerControlPanel = {
      doubleClick = "MM_CTX_MCP_DBLCLK";
      faderMouseWheel = "MM_CTX_MCP_FADER_MOUSEWHEEL";
      horizontalMouseWheel = "MM_CTX_MCP_MOUSEHWHEEL";
      mouseWheel = "MM_CTX_MCP_MOUSEWHEEL";
    };
    midiCcEvent = {
      leftDrag = "MM_CTX_MIDI_CCEVT";
      doubleClick = "MM_CTX_MIDI_CCEVT_DBLCLK";
    };
    midiCcLane = {
      leftDrag = "MM_CTX_MIDI_CCLANE";
      doubleClick = "MM_CTX_MIDI_CCLANE_DBLCLK";
    };
    midiCcSegment = {
      leftDrag = "MM_CTX_MIDI_CCSEG";
      doubleClick = "MM_CTX_MIDI_CCSEG_DBLCLK";
    };
    midiEndPointer.leftDrag = "MM_CTX_MIDI_ENDPTR";
    midiMarkerLane.leftDrag = "MM_CTX_MIDI_MARKERLANES";
    midiNote = {
      leftDrag = "MM_CTX_MIDI_NOTE";
      leftClick = "MM_CTX_MIDI_NOTE_CLK";
      doubleClick = "MM_CTX_MIDI_NOTE_DBLCLK";
    };
    midiNoteEdge.leftDrag = "MM_CTX_MIDI_NOTEEDGE";
    midiPianoRoll = {
      leftDrag = "MM_CTX_MIDI_PIANOROLL";
      leftClick = "MM_CTX_MIDI_PIANOROLL_CLK";
      doubleClick = "MM_CTX_MIDI_PIANOROLL_DBLCLK";
      rightDrag = "MM_CTX_MIDI_RMOUSE";
    };
    midiRuler = {
      leftDrag = "MM_CTX_MIDI_RULER";
      leftClick = "MM_CTX_MIDI_RULER_CLK";
      doubleClick = "MM_CTX_MIDI_RULER_DBLCLK";
    };
    pooledAutomationItem = {
      leftDrag = "MM_CTX_POOLEDENV";
      doubleClick = "MM_CTX_POOLEDENV_DBLCLK";
    };
    pooledAutomationItemEdge.leftDrag = "MM_CTX_POOLEDENVEDGE";
    region.leftDrag = "MM_CTX_REGION";
    regionMarker = {
      leftClick = "MM_CTX_REGION_MARKER_CLK";
      doubleClick = "MM_CTX_REGION_MARKER_DBLCLK";
    };
    ruler = {
      leftDrag = "MM_CTX_RULER";
      leftClick = "MM_CTX_RULER_CLK";
      doubleClick = "MM_CTX_RULER_DBLCLK";
    };
    rulerLaneHeader.doubleClick = "MM_CTX_RULERLANE_HDR_DBLCLK";
    sampleEdit.leftDrag = "MM_CTX_SAMPLEEDIT";
    tempoMarker.leftDrag = "MM_CTX_TEMPOMARKER";
    track = {
      leftDrag = "MM_CTX_TRACK";
      leftClick = "MM_CTX_TRACK_CLK";
      doubleClick = "MM_CTX_TRACK_DBLCLK";
    };
    trackControlPanel = {
      doubleClick = "MM_CTX_TCP_DBLCLK";
      faderMouseWheel = "MM_CTX_TCP_FADER_MOUSEWHEEL";
      horizontalMouseWheel = "MM_CTX_TCP_MOUSEHWHEEL";
      mouseWheel = "MM_CTX_TCP_MOUSEWHEEL";
    };
  };

  modifiers = rec {
    none = "mm_0";
    shift = "mm_1";
    ctrl = "mm_2";
    control = ctrl;
    shiftCtrl = "mm_3";
    shiftControl = shiftCtrl;
    alt = "mm_4";
    option = alt;
    shiftAlt = "mm_5";
    shiftOption = shiftAlt;
    ctrlAlt = "mm_6";
    controlOption = ctrlAlt;
    shiftCtrlAlt = "mm_7";
    shiftControlOption = shiftCtrlAlt;
    win = "mm_8";
    super = win;
    meta = win;
    cmd = win;
    command = win;
  };

  modifier = values: "mm_${toString (modifierFlagFor values)}";

  mouse = id: "${toString id} m";
  command = id: "${toString id} c";
  text = value: value;
  raw = value: value;

  set = context: modifierName: action: {
    ${context}.${modifierName} = action;
  };

  context = contextName: bindings: {
    ${contextName} = mapAttrs (_: action: action) bindings;
  };

  merge = builtins.foldl' recursiveUpdate {};
}
