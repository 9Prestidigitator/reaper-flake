{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) concatMap filterAttrs foldl' imap0 literalExpression mapAttrs mkOption optionalAttrs optionalString optionals types;

  cfg = config.programs.reaper.menus;
  commandIdType = types.either types.int types.str;
  menuKinds = ["menu" "contextMenu" "toolbar"];
  kindFor = name: let
    kind = reaperLib.reaperMenus.kindFor name;
  in
    if kind == null
    then "menu"
    else kind;

  menuEntryType = types.submodule {
    options = {
      action = mkOption {
        type = types.nullOr commandIdType;
        default = null;
        example = 40023;
        description = ''
          REAPER action command ID. Built-in commands use their numeric command
          ID; custom actions and ReaScripts use their underscore-prefixed action
          ID, such as `_RS…`.
        '';
      };

      label = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "&New project";
        description = ''
          Text displayed for this entry. `&` marks the keyboard mnemonic used
          while the menu is open; use `&&` for a literal ampersand.
        '';
      };

      separator = mkOption {
        type = types.bool;
        default = false;
        description = "Render a menu separator, or an empty toolbar spacer.";
      };

      disabled = mkOption {
        type = types.bool;
        default = false;
        description = "Render a non-clickable, grey menu label.";
      };

      entries = mkOption {
        type = types.nullOr (types.listOf menuEntryType);
        default = null;
        description = "Entries in a nested submenu.";
      };

      icon = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "toolbar_save.png";
        description = ''
          Toolbar icon filename in `Data/toolbar_icons`. Only valid for toolbar
          sections.
        '';
      };

      textIcon = mkOption {
        type = types.nullOr (types.enum ["normal" "wide"]);
        default = null;
        description = ''
          Replace the toolbar image with the entry label as either a normal or
          double-width text icon. Only valid for toolbar sections.
        '';
      };

      useTextAsTooltip = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Store REAPER's `text_tt` icon mode, which uses the entry label as the
          toolbar-button tooltip. Only valid for toolbar sections.
        '';
      };

      toolbarFlags = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 1;
        description = ''
          Raw REAPER `tbf_N` toolbar-button flag value. REAPER controls its
          animation and armed-state presentation with this value.
        '';
      };
    };
  };

  menuType = types.submodule ({name, ...}: {
    options = {
      kind = mkOption {
        type = types.enum menuKinds;
        default = kindFor name;
        defaultText = literalExpression "reaperMenus.kindFor section name";
        description = ''
          REAPER section representation. Standard REAPER section names infer
          this automatically. Unrecognized section names default to a menu;
          select the representation explicitly when necessary.
        '';
      };

      entries = mkOption {
        type = types.listOf menuEntryType;
        description = "Top-level entries in this REAPER menu, context menu, or toolbar.";
      };

      title = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional `title` stored by REAPER. It retitles menu-bar menus and is
          visible for toolbars and context menus in REAPER's Customize
          menus/toolbars editor; context-menu titles are not shown in the popup.
        '';
      };
    };
  });

  menuValueType = types.nullOr (types.either (types.listOf menuEntryType) menuType);

  flattenEntries = entries:
    concatMap
    (entry:
      if entry.separator
      then [(entry // {action = -1;})]
      else if entry.disabled
      then [(entry // {action = -4;})]
      else if entry.entries != null
      then
        [(entry // {action = -2;})]
        ++ flattenEntries entry.entries
        ++ [
          {
            action = -3;
            label = null;
            icon = null;
            textIcon = null;
            useTextAsTooltip = false;
            toolbarFlags = null;
          }
        ]
      else [entry])
    entries;

  formatItem = entry: "${toString entry.action}${optionalString (entry.label != null) " ${entry.label}"}";

  toolbarIcon = entry: let
    textIcon = entry.textIcon or null;
    useTextAsTooltip = entry.useTextAsTooltip or false;
  in
    if textIcon == "normal"
    then reaperLib.reaperMenus.toolbarTextIcons.normal
    else if textIcon == "wide"
    then reaperLib.reaperMenus.toolbarTextIcons.wide
    else if useTextAsTooltip
    then reaperLib.reaperMenus.toolbarTextIcons.tooltip
    else entry.icon or null;

  menuAttrs = menu: let
    entries = flattenEntries menu.entries;
    title = menu.title or null;
    entryAttrs =
      foldl'
      (attrs: indexedEntry: let
        index = indexedEntry.index;
        entry = indexedEntry.value;
      in
        attrs
        // {"item_${toString index}" = formatItem entry;}
        // optionalAttrs (toolbarIcon entry != null) {"icon_${toString index}" = toolbarIcon entry;}
        // optionalAttrs (entry.toolbarFlags != null) {"tbf_${toString index}" = entry.toolbarFlags;})
      {}
      (imap0 (index: value: {inherit index value;}) entries);
  in
    entryAttrs
    // optionalAttrs (title != null) {inherit title;};

  configuredMenus =
    mapAttrs
    (name: menu:
      if builtins.isList menu
      then {
        kind = kindFor name;
        entries = menu;
      }
      else menu)
    (filterAttrs (_: menu: menu != null) cfg);
  resetMenus = builtins.attrNames (filterAttrs (_: menu: menu == null) cfg);
in {
  options.programs.reaper.menus = mkOption {
    type = types.attrsOf menuValueType;
    default = {};
    example = literalExpression ''
      {
        "Main file" = [
          {action = 40023; label = "&New project";}
          reaperMenus.divider
          (reaperMenus.submenu "Project &templates" [
            {action = 40394; label = "Save project as template...";}
          ])
        ];

        "Main toolbar" = {
          entries = [
            {action = 40023; label = "New project...";}
            {action = 40025; label = "Open project...";}
            reaperMenus.divider
            {action = 40041; label = "Enable auto-crossfade"; toolbarFlags = 1;}
          ];
        };
      }
    '';
    description = ''
      Declarative contents of `reaper-menu.ini`. Attribute names are REAPER's
      exact section names, such as `"Main file"` and `"Main toolbar"`. Set a
      menu to `null` to remove its customization section and use REAPER's
      built-in default again.
    '';
  };

  config = {
    assertions =
      concatMap
      (menuName: let
        menu = configuredMenus.${menuName};
        isToolbar = menu.kind == "toolbar";
        knownKind = reaperLib.reaperMenus.kindFor menuName;
        invalidFloatingToolbar = lib.hasPrefix "Floating toolbar " menuName && knownKind == null;
        invalidFloatingMidiToolbar = lib.hasPrefix "Floating MIDI toolbar " menuName && knownKind == null;
        entryAssertions = entries:
          concatMap
          (entry:
            [
              {
                assertion = entry.separator || entry.disabled || entry.entries != null || entry.action != null;
                message = "REAPER menu `${menuName}` has an entry without action, separator, disabled, or entries.";
              }
              {
                assertion = !entry.separator || (entry.action == null && entry.entries == null && !entry.disabled);
                message = "A separator in REAPER menu `${menuName}` cannot also be an action, submenu, or disabled label.";
              }
              {
                assertion = !entry.disabled || (entry.action == null && entry.entries == null && entry.label != null);
                message = "A disabled label in REAPER menu `${menuName}` requires label and cannot also be an action or submenu.";
              }
              {
                assertion = entry.entries == null || (entry.action == null && !entry.separator && !entry.disabled && entry.label != null);
                message = "A submenu in REAPER menu `${menuName}` requires label and cannot also be an action, separator, or disabled label.";
              }
              {
                assertion = !(builtins.isString entry.action) || lib.hasPrefix "_" entry.action;
                message = "String action command IDs in REAPER menu `${menuName}` must begin with an underscore.";
              }
              {
                assertion = isToolbar || (entry.icon == null && entry.textIcon == null && !entry.useTextAsTooltip && entry.toolbarFlags == null);
                message = "REAPER ${menu.kind} `${menuName}` is not a toolbar, so its entries cannot set icon, textIcon, useTextAsTooltip, or toolbarFlags.";
              }
              {
                assertion = !entry.useTextAsTooltip || (entry.icon == null && entry.textIcon == null);
                message = "REAPER toolbar `${menuName}` cannot combine useTextAsTooltip with icon or textIcon.";
              }
              {
                assertion = entry.textIcon == null || entry.icon == null;
                message = "REAPER toolbar `${menuName}` cannot combine textIcon with icon.";
              }
              {
                assertion = !isToolbar || entry.entries == null;
                message = "REAPER toolbar `${menuName}` cannot contain nested submenus.";
              }
            ]
            ++ optionals (entry.entries != null) (entryAssertions entry.entries))
          entries;
      in
        [
          {
            assertion = knownKind == null || menu.kind == knownKind;
            message = "REAPER section `${menuName}` is a ${knownKind}; it cannot be configured as ${menu.kind}.";
          }
          {
            assertion = !invalidFloatingToolbar;
            message = "REAPER floating toolbar numbers must be between 1 and 32; `${menuName}` is invalid.";
          }
          {
            assertion = !invalidFloatingMidiToolbar;
            message = "REAPER floating MIDI toolbar numbers must be between 1 and 16; `${menuName}` is invalid.";
          }
        ]
        ++ entryAssertions menu.entries)
      (builtins.attrNames configuredMenus);

    programs.reaper.ini.files."reaper-menu.ini" = mapAttrs (_: menu: menuAttrs menu) configuredMenus;
    programs.reaper.ini.removeSections."reaper-menu.ini" = resetMenus;
  };
}
