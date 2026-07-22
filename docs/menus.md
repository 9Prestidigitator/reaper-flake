# Menus and Toolbars

`programs.reaper.menus` declaratively manages sections in REAPER's
`reaper-menu.ini`. A section replaces the corresponding REAPER menu or toolbar.
Set a section to `null` to remove its customization and return to REAPER's
built-in version.

```nix
{reaperMenus, ...}: {
  programs.reaper.menus = {
    "${reaperMenus.sections.mainFile}" = [
      {action = 40023; label = "&New project";}
      reaperMenus.divider
      {action = 40004; label = "&Quit";}
    ];
  };
}
```

The `&` in a menu label defines the menu mnemonic. On Linux and Windows,
`&New project` displays an underlined `N` while the menu is open.

## Section Helpers

Use the helpers instead of spelling section names where practical.

| Helper | REAPER section |
| --- | --- |
| `reaperMenus.sections.mainFile` | Main file |
| `reaperMenus.sections.mainEdit` | Main edit |
| `reaperMenus.sections.mainView` | Main view |
| `reaperMenus.sections.mainInsert` | Main insert |
| `reaperMenus.sections.mainItem` | Main item |
| `reaperMenus.sections.mainTrack` | Main track |
| `reaperMenus.sections.mainOptions` | Main options |
| `reaperMenus.sections.mainActions` | Main actions |
| `reaperMenus.sections.mainExtensions` | Main extensions |
| `reaperMenus.sections.rulerArrangeContext` | Ruler/arrange context |
| `reaperMenus.sections.trackControlPanelContext` | Track control panel context |
| `reaperMenus.sections.mediaItemContext` | Media item context |
| `reaperMenus.sections.mixerContext` | Mixer context |
| `reaperMenus.toolbars.main` | Main toolbar |
| `reaperMenus.toolbars.mediaExplorer` | Media Explorer toolbar |
| `reaperMenus.toolbars.midiPianoRoll` | MIDI piano roll toolbar |
| `reaperMenus.toolbars.midiEventList` | MIDI event list toolbar |

`reaperMenus.sections` also includes the remaining supported main, MIDI,
Media Explorer, and context-menu sections. The library identifies whether each
known section is a menu, context menu, or toolbar. Known sections cannot be
configured as a different kind.

## Menu and Context-Menu Entries

Menus and context menus have the same entry syntax. They can contain actions,
separators, disabled labels, and nested submenus.

```nix
"${reaperMenus.sections.mainFile}" = {
  # Changes the menu-bar caption from File to Project.
  title = "&Project";

  entries = [
    {action = 40023; label = "&New project";}
    reaperMenus.divider
    (reaperMenus.submenu "Project &templates" [
      {action = 40394; label = "Save project as template...";}
      {action = 48000; label = "(project template list)";}
    ])
    (reaperMenus.label "Project utilities")
    {action = 40004; label = "&Quit";}
  ];
};
```

The shorthand list form is equivalent when no section title is needed:

```nix
"${reaperMenus.sections.mainEdit}" = [
  {action = 40029; label = "&Undo";}
  {action = 40030; label = "&Redo";}
];
```

`label` is the visible action name, so it is also how an individual action is
retitled. `title` is the title of the entire section: it changes a main
menu-bar caption, while context-menu titles are only visible in REAPER's
Customize menus/toolbars editor and not in the popup itself.

An `action` is either a numeric REAPER command ID or an underscore-prefixed
custom action, script, or extension command ID:

```nix
{action = 40044; label = "Play/stop";}
{action = "_SWS_SAVEVIEW"; label = "SWS: Save view";}
{action = "_RS0123456789abcdef"; label = "My script";}
```

## Toolbars

Toolbar entries use the same `action` and `label` fields, but have a different
REAPER representation. They support icon and feedback fields, and cannot
contain submenus.

```nix
"${reaperMenus.toolbars.main}" = {
  title = "Main tools";
  entries = [
    {
      action = 40023;
      label = "New project";
      icon = "toolbar_new.png";
    }
    {
      action = 40145;
      label = "Grid";
      textIcon = "normal";
    }
    {
      action = 1162;
      label = "Toggle ripple editing";
      toolbarFlags = 1;
    }
    reaperMenus.divider
  ];
};
```

Toolbar-specific fields are:

| Field | Meaning |
| --- | --- |
| `icon` | Filename from REAPER's `Data/toolbar_icons` directory. |
| `textIcon = "normal"` | Renders the label as a text button. |
| `textIcon = "wide"` | Renders the label as a double-width text button. |
| `useTextAsTooltip = true` | Uses REAPER's `text_tt` icon mode. |
| `toolbarFlags` | Raw `tbf_N` feedback/animation bitfield. |

`toolbarFlags` does not change an action's state. It configures REAPER's
visual feedback for actions that report a toggle state. REAPER does not publish
the full bit layout, so it remains an unsigned integer option.

## Floating Toolbars

General floating toolbars are numbered 1 through 32. MIDI floating toolbars
are numbered 1 through 16. The helpers enforce these bounds.

```nix
"${reaperMenus.toolbars.floating 1}" = {
  title = "Editing";
  entries = [
    {action = 40041; label = "Auto-crossfade";}
    {action = 1157; label = "Snap";}
  ];
};

"${reaperMenus.toolbars.floatingMidi 1}" = {
  title = "MIDI tools";
  entries = [
    {action = 40001; label = "Insert note";}
  ];
};
```

The helpers write `[Floating toolbar N]` and `[Floating MIDI toolbar N]` and
are recognized as toolbar sections automatically.

### Docking a Floating Toolbar

Floating toolbars are hosted by REAPER's dedicated Toolbar Docker. Use a
regular `layout.docks` entry with ID `15` to place that docker, then mark the
toolbar visible and docked in its `toolbar:N` section:

```nix
{
  reaperMenus,
  ...
}: {
  programs.reaper = {
    menus."${reaperMenus.toolbars.floating 1}" = {
      title = "Editing";
      entries = [
        {action = 40041; label = "Auto-crossfade";}
        {action = 1157; label = "Snap";}
      ];
    };

    layout = {
      docks.toolbar = {
        id = 15;
        position = "top";
      };

      # Toolbar state is not a normal REAPER panel and uses its own section.
      rawSections."toolbar:1" = {
        dock = 1;
        wnd_vis = 1;
      };
    };
  };
}
```

This writes `[reaper].dockermode15=2`, which attaches the Toolbar Docker to
the top of the main window, and makes Floating toolbar 1 visible in that
docker.

## Resetting a Section

Set a managed section to `null` to remove that section from `reaper-menu.ini`:

```nix
programs.reaper.menus."${reaperMenus.toolbars.main}" = null;
```

REAPER then uses its built-in default toolbar or menu. The module intentionally
does not generate REAPER's `default=<hash>` metadata; existing metadata is
preserved when a section remains managed.
