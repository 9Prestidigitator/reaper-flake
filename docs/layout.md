# Layout

`programs.reaper.layout` controls REAPER window placement and docking state. The layout layer now separates two REAPER concepts:

- `layout.docks.*` describes docker containers: their numeric ID, screen edge, selected tab, and edge size.
- `layout.panels.*` describes dockable panels: their REAPER panel ID, optional INI section, visibility/window keys, target dock, and tab order.

REAPER stores the relationship between these concepts in two places. `[reaper].dockermodeN` describes where docker container `N` is attached, and `[REAPERdockpref]` assigns a panel ID to a docker ID. The first number in a `[REAPERdockpref]` value is the panel's relative tab order inside that dock.

## Basic Example

```nix
{
  reaperLayout,
  reaperWindows,
  ...
}: {
  programs.reaper.layout = {
    mainWindow = {
      position = {
        x = 0;
        y = 0;
      };
      size = {
        width = 1600;
        height = 900;
      };
      state = reaperLayout.windowState.normal;
    };

    docks = {
      bottom = {
        id = 3;
        position = "bottom";
        size = 471;
        selectedPanel = "mixer";
      };

      left = {
        id = 2;
        position = "left";
        size = 395;
        selectedPanel = "explorer";
      };
    };

    mixer = {
      visible = true;
      docked = true;
      dock = "bottom";
      tabOrder = 0.0;
    };

    transport = {
      visible = true;
      docked = true;
      dock = "bottom";
      tabOrder = 1.0;
      dockPosition = reaperWindows.transport.topOfMainWindow;
    };

    panels.explorer = {
      id = "explorer";
      section = "reaper_sexplorer";
      keyStyle = "window";
      visible = true;
      docked = true;
      dock = "left";
      tabOrder = 0.5;
      raw = {
        peak_height = 80;
        volume = 4096;
      };
    };
  };
}
```

This writes the equivalent of:

```ini
[reaper]
dockermode3=0
dockermode2=1
dockersel3=mixer
dockersel2=explorer
dockheight=471
dockheight_l=395
mixwnd_dock=1
mixwnd_vis=1
transport_dock=1
transport_vis=1

[REAPERdockpref]
mixer=0.000000 3
transport=1.000000 3
explorer=0.500000 2

[reaper_sexplorer]
visible=1
peak_height=80
volume=4096
```

## Docks

Use `layout.docks` for docker containers:

```nix
layout.docks.right = {
  id = 1;
  position = "right";
  size = 233;
  selectedPanel = "transport";
};
```

`position` maps to `[reaper].dockermodeN`:

| position | dockermode value | size key |
| --- | ---: | --- |
| `bottom` | `0` | `dockheight` |
| `left` | `1` | `dockheight_l` |
| `top` | `2` | `dockheight_t` |
| `right` | `3` | `dockheight_r` |

The size keys are global buckets for a physical edge. They are not per-container geometry keys. If multiple dockers occupy the same edge, REAPER applies the same edge size value.

Use `mode` or `sizeKey` only as raw escape hatches when you have captured a REAPER layout that cannot be described by `position`.

## Toolbar Docker

REAPER's numbered floating toolbars are tabs inside a special Toolbar Docker, which uses docker ID `15`. Define the toolbar contents with `programs.reaper.menus`, then place the Toolbar Docker through `layout.docks`:

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

      # REAPER persists a Toolbar Docker tab separately from normal panels.
      rawSections."toolbar:1" = {
        dock = 1;
        wnd_vis = 1;
      };
    };
  };
}
```

This docks Floating toolbar 1 at the top of the main window. Change the section to `toolbar:2` for Floating toolbar 2, and so on. REAPER uses a different internal section index for MIDI floating toolbars; capture that section from a REAPER-created `reaper.ini` before managing it with `rawSections`.

## Panels

Use `layout.panels` for arbitrary dockable REAPER windows:

```nix
layout.panels.routingMatrix = {
  id = "routing";
  section = "reaper_routing";
  keyStyle = "window";
  visible = true;
  dock = "top";
  tabOrder = 0.0;
};
```

The `id` is the token REAPER uses in `[REAPERdockpref]` and `dockerselN`. The `section` is where that panel stores its own INI keys, if it has a separate section.

Supported `keyStyle` values:

- `reaper`: writes prefixed keys inside `[reaper]`, such as `mixwnd_vis`.
- `section-long`: writes section keys like `wnd_left`, `wnd_top`, `wnd_width`, `wnd_height`, and `dock`.
- `section-short`: writes section keys like `wnd_x`, `wnd_y`, `wnd_w`, `wnd_h`, and `wnd_dock`.
- `window`: writes section keys like `window_x`, `window_y`, `window_w`, `window_h`, and `visible`.
- `simple`: writes only `visible` plus any `raw` keys.

For example, REAPER's media explorer uses a separate `[reaper_sexplorer]` section, so `keyStyle = "window"` plus `raw` works well. The mixer is special and is still available through the first-class `layout.mixer` option because REAPER stores its window keys directly in `[reaper]` as `mixwnd_*`.

## First-Class Panels

The existing first-class options remain available:

- `mainWindow`
- `mixer`
- `masterMixer`
- `transport`

Use `tabOrder` when multiple panels share the same dock.

## Escape Hatches

Use `dockId` when you need to assign a panel to a raw docker ID, `dockPreference` when you already know the exact `[REAPERdockpref]` value, and `rawSections` for layout-related INI sections that are not worth modeling as panels.
