rec {
  sections = {
    mainFile = "Main file";
    mainEdit = "Main edit";
    mainView = "Main view";
    mainInsert = "Main insert";
    mainItem = "Main item";
    mainTrack = "Main track";
    mainOptions = "Main options";
    mainActions = "Main actions";
    mainExtensions = "Main extensions";

    rulerArrangeContext = "Ruler/arrange context";
    trackControlPanelContext = "Track control panel context";
    emptyTcpContext = "Empty TCP context";
    mediaItemContext = "Media item context";
    envelopeContext = "Envelope context";
    envelopePointContext = "Envelope point context";
    mixerContext = "Mixer context";
    fxExtendedMixerContext = "FX extended mixer context";
    sendsExtendedMixerContext = "Sends extended mixer context";
    transportContext = "Transport context";
    automationItemContext = "Automation item context";

    midiMainFile = "MIDI main file";
    midiMainEdit = "MIDI main edit";
    midiMainNavigate = "MIDI main navigate";
    midiMainOptions = "MIDI main options";
    midiMainView = "MIDI main view";
    midiMainContents = "MIDI main contents";
    midiMainActions = "MIDI main actions";
    midiPianoRollContext = "MIDI piano roll context";
    midiCcLaneContext = "MIDI CC lane context";
    midiEventListContext = "MIDI event list context";
    midiInlineEditorContext = "MIDI inline editor context";
    midiMainMenuContext = "MIDI main menu context";

    mediaExplorerMain = "Media Explorer main";
    mediaExplorerShow = "Media Explorer show";
    mediaExplorerOptions = "Media Explorer options";
    mediaExplorerMainContext = "Media Explorer main context";
  };

  toolbars = {
    main = "Main toolbar";
    mediaExplorer = "Media Explorer toolbar";
    midiPianoRoll = "MIDI piano roll toolbar";
    midiEventList = "MIDI event list toolbar";
    floating = number:
      assert builtins.isInt number && number >= 1 && number <= 32; "Floating toolbar ${toString number}";
    floatingMidi = number:
      assert builtins.isInt number && number >= 1 && number <= 16; "Floating MIDI toolbar ${toString number}";
  };

  sectionKinds = {
    "Main file" = "menu";
    "Main edit" = "menu";
    "Main view" = "menu";
    "Main insert" = "menu";
    "Main item" = "menu";
    "Main track" = "menu";
    "Main options" = "menu";
    "Main actions" = "menu";
    "Main extensions" = "menu";
    "MIDI main file" = "menu";
    "MIDI main edit" = "menu";
    "MIDI main navigate" = "menu";
    "MIDI main options" = "menu";
    "MIDI main view" = "menu";
    "MIDI main contents" = "menu";
    "MIDI main actions" = "menu";
    "Media Explorer main" = "menu";
    "Media Explorer show" = "menu";
    "Media Explorer options" = "menu";

    "Ruler/arrange context" = "contextMenu";
    "Track control panel context" = "contextMenu";
    "Empty TCP context" = "contextMenu";
    "Media item context" = "contextMenu";
    "Envelope context" = "contextMenu";
    "Envelope point context" = "contextMenu";
    "Mixer context" = "contextMenu";
    "FX extended mixer context" = "contextMenu";
    "Sends extended mixer context" = "contextMenu";
    "Transport context" = "contextMenu";
    "Automation item context" = "contextMenu";
    "MIDI piano roll context" = "contextMenu";
    "MIDI CC lane context" = "contextMenu";
    "MIDI event list context" = "contextMenu";
    "MIDI inline editor context" = "contextMenu";
    "MIDI main menu context" = "contextMenu";
    "Media Explorer main context" = "contextMenu";

    "Main toolbar" = "toolbar";
    "Media Explorer toolbar" = "toolbar";
    "MIDI piano roll toolbar" = "toolbar";
    "MIDI event list toolbar" = "toolbar";
  };

  kindFor = name:
    if builtins.hasAttr name sectionKinds
    then sectionKinds.${name}
    else if builtins.match "Floating toolbar ([1-9]|[12][0-9]|3[0-2])" name != null || builtins.match "Floating MIDI toolbar ([1-9]|1[0-6])" name != null
    then "toolbar"
    else null;

  toolbarTextIcons = {
    normal = "text";
    wide = "text_wide";
    tooltip = "text_tt";
  };

  divider = {separator = true;};
  label = text: {
    disabled = true;
    label = text;
  };
  submenu = label: entries: {inherit label entries;};
  action = action: label: {inherit action label;};
}
