# REAPER Actions

This module writes managed lines to `reaper-kb.ini`.

Use `programs.reaper.actions.keyBindings` for keyboard shortcuts, `programs.reaper.actions.scripts` for ReaScript action registrations, `programs.reaper.actions.customActions` for sequential custom actions, and `programs.reaper.actions.rawLines` for advanced `reaper-kb.ini` lines.

## Basic Shape

```nix
{reaperActions, ...}: {
  programs.reaper.actions.keyBindings = with reaperActions; bindings [
    (shortcut {
      shortcut = "Ctrl+Space";
      command = commands.transport.play;
      actionName = "Transport: Play";
    })
  ];
}
```

This writes a managed `KEY` line to `reaper-kb.ini`.

## Overrides and Conflicts

REAPER's factory-default shortcuts are built in and normally do not appear in `reaper-kb.ini`. Declaring a binding for the same shortcut in the same action section overrides the factory default. There is no separate conflict prompt during Home Manager activation: REAPER resolves the `KEY` record when it next loads `reaper-kb.ini`.

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  # Overrides REAPER's default Main-section Space binding.
  (shortcut {
    shortcut = "Space";
    command = 1016;
    actionName = "Transport: Stop";
  })
];
```

A binding is unique within its action section by its modifier flags and key code. The same shortcut in different sections, such as Main and MIDI editor, does not conflict.

If two `KEY` lines define the same shortcut in the same section, REAPER uses the last one. This module preserves the order of `keyBindings`, so the later declaration wins. Avoid duplicates: the module does not currently reject them, and a manually managed `KEY` line for the same shortcut can make the resulting file harder to reason about.

To explicitly disable a factory-default shortcut, bind it to command `0`:

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  (shortcut {
    shortcut = "Space";
    command = 0;
    actionName = "Unbind factory-default Space shortcut";
  })
];
```

Removing the managed override restores REAPER's factory default only when no other custom `KEY` record for that same shortcut and section remains. Restart REAPER after activation so it reloads `reaper-kb.ini`.

## Options

`keyBindings`

Keyboard shortcuts for REAPER actions.

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  (shortcut {
    shortcut = "Ctrl+Alt+S";
    command = commands.transport.stop;
    actionName = "Transport: Stop";
  })
];
```

`scripts`

Script actions registered in REAPER's action list.

```nix
programs.reaper.actions.scripts = [
  {
    path = "User/toggle-click.lua";
    source = ./scripts/toggle-click.lua;
    description = "Custom: toggle click";
  }
];
```

`rawLines`

Advanced raw `reaper-kb.ini` lines. Use this for features that do not have a typed option yet.

```nix
programs.reaper.actions.rawLines = [
  # Paste the exact custom action line from REAPER's reaper-kb.ini.
  ''ACT ...''
];
```

Prefer copying raw custom action lines from a REAPER-created `reaper-kb.ini` until this flake has typed custom action helpers.

## Helpers

`reaperActions.shortcut`

Creates one key binding.

```nix
reaperActions.shortcut {
  shortcut = "Ctrl+Shift+P";
  command = 1007;
  section = reaperActions.sections.main;
  actionName = "Transport: Play";
}
```

`shortcut` accepts:

| Field        | Meaning                                           |
| ------------ | ------------------------------------------------- |
| `shortcut`   | Key combination, such as `Ctrl+S` or `Shift+F4`   |
| `command`    | REAPER command id, custom action id, or script id |
| `section`    | Action section, defaults to main                  |
| `actionName` | Human-readable comment                            |
| `comment`    | Full custom comment                               |

`reaperActions.globalShortcut`

Creates the normal shortcut and the extra global-scope line.

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  (globalShortcut {
    shortcut = "Ctrl+Alt+Space";
    command = commands.transport.play;
    scope = "global";
    actionName = "Transport: Play";
  })
];
```

Scopes:

| Scope              | Meaning                               |
| ------------------ | ------------------------------------- |
| `global`           | Works globally                        |
| `globalTextFields` | Works globally, including text fields |

Global shortcuts are supported for the main and main alternate recording sections.

`reaperActions.bindings`

Flattens a list of shortcuts and global shortcuts.

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  (shortcut {
    shortcut = "Space";
    command = commands.transport.play;
  })

  (globalShortcut {
    shortcut = "Ctrl+Alt+Space";
    command = commands.transport.stop;
  })
];
```

## Sections

Use `reaperActions.sections.*` when binding outside the main action list.

| Helper                                    | REAPER section     |
| ----------------------------------------- | ------------------ |
| `reaperActions.sections.main`             | Main               |
| `reaperActions.sections.mainAltRecording` | Main alt recording |
| `reaperActions.sections.midiEditor`       | MIDI editor        |
| `reaperActions.sections.midiEventList`    | MIDI event list    |
| `reaperActions.sections.midiInlineEditor` | MIDI inline editor |
| `reaperActions.sections.mediaExplorer`    | Media explorer     |

Example:

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  (shortcut {
    shortcut = "Ctrl+Enter";
    section = sections.midiEditor;
    command = 40003;
    actionName = "MIDI editor action";
  })
];
```

## Commands

The library only contains a small starter set of named commands.

```nix
reaperActions.commands.transport.play
reaperActions.commands.transport.stop
reaperActions.commands.transport.tapTempo
```

Use numeric REAPER command ids for normal actions:

```nix
command = 40044;
```

Use string ids for custom actions, scripts, and extension actions:

```nix
command = "_SWS_SAVEVIEW";
command = "_RS1ee9bb229dabffe151848d7efa3c10f748e1a1cf";
```

The formatter keeps a leading `_` when present and adds one when needed for string command ids.

## Keys

Shortcut strings use `+` between modifiers and the final key.

```nix
"Ctrl+S"
"Ctrl+Shift+F4"
"Alt+Enter"
"Space"
```

Supported modifiers:

| Name                                     |
| ---------------------------------------- |
| `Shift`                                  |
| `Ctrl`, `Control`                        |
| `Alt`, `Option`                          |
| `Win`, `Super`, `Meta`, `Cmd`, `Command` |

Supported keys include letters, numbers, function keys, keypad keys, arrows, and common control keys:

```nix
"A"
"1"
"F12"
"Numpad0"
"Left"
"Right"
"Up"
"Down"
"Enter"
"Escape"
"Delete"
"Space"
```

For uncommon keys, use a raw binding:

```nix
programs.reaper.actions.keyBindings = [
  {
    modifierFlags = 29;
    keyCode = 79;
    command = 1016;
    section = 0;
    comment = "Main : Ctrl+Alt+Shift+O : Transport: Stop";
  }
];
```

## Scripts

Register a script that already exists under REAPER's `Scripts` directory:

```nix
programs.reaper.actions.scripts = [
  {
    path = "User/my-script.lua";
    description = "Custom: my script";
  }
];
```

Install a Nix-owned script into the REAPER resource directory and register it:

```nix
programs.reaper.actions.scripts = [
  {
    path = "User/my-script.lua";
    source = ./scripts/my-script.lua;
    description = "Custom: my script";
  }
];
```

Register a script outside the resource directory:

```nix
programs.reaper.actions.scripts = [
  {
    location = "absolute";
    path = "/home/me/reaper-scripts/my-script.lua";
    description = "Custom: external script";
  }
];
```

Script fields:

| Field         | Meaning                                           |
| ------------- | ------------------------------------------------- |
| `path`        | Script path                                       |
| `source`      | Optional Nix-owned script file to link            |
| `location`    | `scripts`, `resource`, or `absolute`              |
| `section`     | Action section, defaults to main                  |
| `commandId`   | Stable `RS...` command id                         |
| `flags`       | REAPER script registration flags, defaults to `4` |
| `description` | Text stored in the script registration line       |

When `commandId` is unset, the module generates a deterministic `RS...` id from the section and resolved script path.

## Keybind A Script

Use an explicit `commandId` when you want to bind the script in the same config.

```nix
{
  reaperActions,
  ...
}: {
  programs.reaper.actions = {
    scripts = [
      {
        path = "User/toggle-click.lua";
        source = ./scripts/toggle-click.lua;
        commandId = "RS_toggle_click";
        description = "Custom: toggle click";
      }
    ];

    keyBindings = with reaperActions; bindings [
      (shortcut {
        shortcut = "Ctrl+Alt+C";
        command = "RS_toggle_click";
        actionName = "Custom: toggle click";
      })
    ];
  };
}
```

## Custom Actions

`customActions` creates REAPER custom actions: ordered sequences of built-in, extension, ReaScript, or other custom actions. REAPER executes the entries in `actions` from left to right.

```nix
programs.reaper.actions.customActions = [
  {
    name = "Prepare recording";
    commandId = "prepare_recording";
    description = "Custom: Prepare recording";
    consolidateUndoPoints = true;
    showInActionsMenu = true;
    actions = [40001 40044 "RS_toggle_click"];
  }
];
```

`commandId` is optional. When omitted, the module derives a stable `CA...` id from the action's section and name. Set it explicitly if you may rename the action while preserving existing key bindings, toolbar entries, or external references. String action ids can include their leading underscore, but do not need to.

Bind the custom action by its command id:

```nix
programs.reaper.actions.keyBindings = with reaperActions; bindings [
  (shortcut {
    shortcut = "Ctrl+Alt+R";
    command = "_prepare_recording";
    actionName = "Custom: prepare recording";
  })
];
```

Each custom action must contain at least one entry. `rawLines` remains available for importing an existing `ACT` line or using an uncommon REAPER custom-action flag that does not yet have a typed option.

## Full Example

```nix
{
  reaperActions,
  ...
}: {
  programs.reaper.actions = {
    scripts = [
      {
        path = "User/toggle-click.lua";
        source = ./scripts/toggle-click.lua;
        commandId = "RS_toggle_click";
        description = "Custom: toggle click";
      }
    ];

    keyBindings = with reaperActions; bindings [
      (shortcut {
        shortcut = "Space";
        command = commands.transport.play;
        actionName = "Transport: Play";
      })

      (shortcut {
        shortcut = "Ctrl+Alt+C";
        command = "RS_toggle_click";
        actionName = "Custom: toggle click";
      })

      (globalShortcut {
        shortcut = "Ctrl+Alt+Space";
        command = commands.transport.stop;
        scope = "global";
        actionName = "Transport: Stop";
      })
    ];

    rawLines = [
      # Paste the exact custom action line from REAPER's reaper-kb.ini.
      ''ACT ...''
    ];
  };
}
```
