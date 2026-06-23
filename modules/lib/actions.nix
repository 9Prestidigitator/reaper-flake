{lib}: let
  inherit (lib) concatLists hasPrefix init last splitString toLower;

  sectionIds = {
    main = 0;
    mainAltRecording = 100;
    midiEditor = 32060;
    midiEventList = 32061;
    midiInlineEditor = 32062;
    mediaExplorer = 32063;
  };

  sectionNamesById = {
    "0" = "main";
    "100" = "mainAltRecording";
    "32060" = "midiEditor";
    "32061" = "midiEventList";
    "32062" = "midiInlineEditor";
    "32063" = "mediaExplorer";
  };

  globalScopeCommands = {
    global = 1;
    globalTextFields = 101;
  };

  keyCodes = {
    "0" = 48;
    "1" = 49;
    "2" = 50;
    "3" = 51;
    "4" = 52;
    "5" = 53;
    "6" = 54;
    "7" = 55;
    "8" = 56;
    "9" = 57;
    a = 65;
    b = 66;
    c = 67;
    d = 68;
    e = 69;
    f = 70;
    g = 71;
    h = 72;
    i = 73;
    j = 74;
    k = 75;
    l = 76;
    m = 77;
    n = 78;
    o = 79;
    p = 80;
    q = 81;
    r = 82;
    s = 83;
    t = 84;
    u = 85;
    v = 86;
    w = 87;
    x = 88;
    y = 89;
    z = 90;
    f1 = 112;
    f2 = 113;
    f3 = 114;
    f4 = 115;
    f5 = 116;
    f6 = 117;
    f7 = 118;
    f8 = 119;
    f9 = 120;
    f10 = 121;
    f11 = 122;
    f12 = 123;
    f13 = 124;
    f14 = 125;
    f15 = 126;
    f16 = 127;
    f17 = 128;
    f18 = 129;
    f19 = 130;
    f20 = 131;
    f21 = 132;
    f22 = 133;
    f23 = 134;
    f24 = 135;
    num0 = 96;
    num1 = 97;
    num2 = 98;
    num3 = 99;
    num4 = 100;
    num5 = 101;
    num6 = 102;
    num7 = 103;
    num8 = 104;
    num9 = 105;
    numpad0 = 96;
    numpad1 = 97;
    numpad2 = 98;
    numpad3 = 99;
    numpad4 = 100;
    numpad5 = 101;
    numpad6 = 102;
    numpad7 = 103;
    numpad8 = 104;
    numpad9 = 105;
    numpadmultiply = 106;
    numpadadd = 107;
    numpadseparator = 108;
    numpadsubtract = 109;
    numpaddecimal = 110;
    numpaddivide = 111;
    backspace = 8;
    tab = 9;
    clear = 12;
    enter = 13;
    return = 13;
    pause = 19;
    capslock = 20;
    escape = 27;
    esc = 27;
    space = 32;
    printscreen = 44;
    pageup = 33;
    pagedown = 34;
    end = 35;
    home = 36;
    left = 37;
    up = 38;
    right = 39;
    down = 40;
    insert = 45;
    delete = 46;
    scrolllock = 145;
    numlock = 144;
    plus = 187;
    equals = 187;
    comma = 188;
    minus = 189;
    period = 190;
    slash = 191;
    semicolon = 186;
    quote = 222;
    backtick = 192;
    leftbracket = 219;
    rightbracket = 221;
    backslash = 220;
    mousewheel = 2040;
  };

  modifierValues = {
    shift = 4;
    ctrl = 8;
    control = 8;
    alt = 16;
    option = 16;
    win = 32;
    super = 32;
    meta = 32;
    cmd = 32;
    command = 32;
  };

  normalize = value: toLower (builtins.replaceStrings ["-" "_" " "] ["" "" ""] value);

  keyCodeFor = key: let
    normalized = normalize key;
  in
    if builtins.hasAttr normalized keyCodes
    then builtins.getAttr normalized keyCodes
    else throw "Unsupported REAPER shortcut key `${key}`. Use raw `programs.reaper.actions.keyBindings` for uncommon key codes.";

  modifierValueFor = modifier: let
    normalized = normalize modifier;
  in
    if builtins.hasAttr normalized modifierValues
    then builtins.getAttr normalized modifierValues
    else throw "Unsupported REAPER shortcut modifier `${modifier}`.";

  parseShortcut = shortcut: let
    parts = splitString "+" shortcut;
    key = last parts;
    modifierParts = init parts;
  in {
    modifierFlags = 1 + builtins.foldl' (total: modifier: total + modifierValueFor modifier) 0 modifierParts;
    keyCode = keyCodeFor key;
  };

  sectionIdFor = section:
    if builtins.isInt section
    then section
    else if builtins.hasAttr section sectionIds
    then builtins.getAttr section sectionIds
    else throw "Unsupported REAPER action section `${section}`.";

  sectionNameFor = section: let
    sectionId = sectionIdFor section;
    key = toString sectionId;
  in
    if builtins.hasAttr key sectionNamesById
    then builtins.getAttr key sectionNamesById
    else key;

  globalSectionIdFor = section: let
    sectionId = sectionIdFor section;
  in
    if sectionId == sectionIds.main
    then 102
    else if sectionId == sectionIds.mainAltRecording
    then 103
    else throw "Global REAPER shortcuts require the main or main-alt-recording section.";

  formatComment = {
    section,
    shortcut,
    actionName ? null,
    comment ? null,
  }:
    if comment != null
    then comment
    else if actionName == null
    then "${sectionNameFor section} : ${shortcut}"
    else "${sectionNameFor section} : ${shortcut} : ${actionName}";
in rec {
  sections = sectionIds;

  commands = {
    transport = {
      play = 1007;
      stop = 1016;
      tapTempo = 1134;
    };
  };

  shortcut = {
    shortcut,
    command,
    section ? sections.main,
    actionName ? null,
    comment ? null,
  }:
    (parseShortcut shortcut)
    // {
      inherit command;
      section = sectionIdFor section;
      comment = formatComment {inherit section shortcut actionName comment;};
    };

  globalShortcut = {
    shortcut,
    command,
    section ? sections.main,
    scope ? "global",
    actionName ? null,
    comment ? null,
  }: let
    parsedShortcut = parseShortcut shortcut;
    globalScopeCommand =
      if builtins.hasAttr scope globalScopeCommands
      then builtins.getAttr scope globalScopeCommands
      else throw "Unsupported REAPER global shortcut scope `${scope}`.";
  in [
    (parsedShortcut
      // {
        inherit command;
        section = sectionIdFor section;
        comment = formatComment {inherit section shortcut actionName comment;};
      })
    (parsedShortcut
      // {
        command = globalScopeCommand;
        section = globalSectionIdFor section;
        comment = "${sectionNameFor section} : ${shortcut} : ${scope}";
      })
  ];

  bindings = entries:
    concatLists (map (entry:
      if builtins.isList entry
      then entry
      else [entry])
    entries);

  formatCommand = command:
    if builtins.isString command
    then
      if hasPrefix "_" command
      then command
      else "_${command}"
    else toString command;

  formatKeyBinding = binding: let
    comment =
      if binding.comment == null
      then ""
      else "\t\t # ${binding.comment}";
  in "KEY ${toString binding.modifierFlags} ${toString binding.keyCode} ${formatCommand binding.command} ${toString binding.section}${comment}";

  formatScript = script: let
    description = builtins.replaceStrings ["\""] ["\\\""] script.description;
    commandId =
      if hasPrefix "_" script.commandId
      then builtins.substring 1 ((builtins.stringLength script.commandId) - 1) script.commandId
      else script.commandId;
  in "SCR ${toString script.flags} ${toString script.section} ${commandId} \"${description}\" ${script.path}";
}
