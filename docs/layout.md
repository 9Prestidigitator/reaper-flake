# Layout

`programs.reaper.layout` controls REAPER window placement and docking state. It writes the INI keys REAPER uses for the main window, mixer, master mixer, transport, and any additional docked windows you model.

## Basic Example

This is the smallest useful shape:

```nix
{
  reaperLayout,
  reaperWindows,
  ...
}: {
  programs.reaper.layout = {
    mainWindow = {
      position = {
        x = 60;
        y = 50;
      };
      size = {
        width = 1120;
        height = 760;
      };
    };

    mixer = {
      visible = true;
      docked = true;
      docker = "main";
    };

    transport = {
      visible = true;
      docked = true;
      docker = "main";
      dockPosition = reaperWindows.transport.topOfMainWindow;
    };
  };
}
```

## What It Covers

The first-class layout options are:

- `mainWindow`
- `mixer`
- `masterMixer`
- `transport`

These options let you set things like position, size, visibility, docked state, and a few window-specific values such as `mainWindow.state` or `transport.dockPosition`.

## Dock Containers

Docker topology is modeled separately from the windows that live inside it.

Use `programs.reaper.layout.dockers` to name docker containers:

```nix
layout.dockers = {
  main = {
    id = reaperLayout.dock.mainDocker;
    position = "main";
  };

  left = {
    id = 1;
    position = "left";
    size = 320;
    preference = "0.85531396 1";
  };
};
```

The built-in `main` docker is available by default. Additional entries are useful when you want to describe a more specific docker topology.

If REAPER stores the container geometry as an opaque composite value, keep that value in `preference` and leave the semantic name in `position`:

```nix
layout.dockers.left = {
  id = 1;
  position = "left";
  size = 320;
  preference = "0.85531396 1";
};
```

## Docked Windows

First-class windows such as `mixer` and `transport` can point at a named docker with `docker = "main"`.

For other dockable REAPER windows, use `programs.reaper.layout.dockedWindows`:

```nix
layout.dockedWindows.explorer.docker = "left";
```

That writes the corresponding `[REAPERdockpref]` entry for the window ID.

If you already know the raw window ID or the exact dock preference string, you can still use the lower-level options:

```nix
layout = {
  dockPreferences.navigator = reaperLayout.dock.mainDocker;

  rawSections.reaper_explorer = {
    window_x = 80;
    window_y = 80;
    window_w = 900;
    window_h = 420;
  };
};
```

## Raw Escape Hatches

Use `dockPreferences` when you already know the exact `[REAPERdockpref]` value you want to write, and use `rawSections` for layout-related INI sections that are not modeled yet.

## Practical Rule

- Use `docker` when you want to refer to a named docker container.
- Use `dockId` only when you need a raw docker ID.
- Use `dockPreferences` and `rawSections` only when REAPER stores the layout state in a form that is not yet modeled directly.
