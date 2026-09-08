# Modular example flake

This directory is a complete, reusable REAPER configuration flake.

The example is split by responsibility:

- [`preferences.nix`](preferences.nix) configures representative preferences.
- [`extensions.nix`](extensions.nix) installs ReaPack, SWS, themes, and plug-in paths.
- [`menus.nix`](menus.nix) defines a menu, context menu, and toolbar.
- [`actions.nix`](actions.nix) installs a ReaScript and binds shortcuts.
- [`layout.nix`](layout.nix) defines windows, docks, and panels.

Copy this directory into your configuration repository and edit each module to
fit your setup. Replace the `reaper-flake` URL in `flake.nix` with a local path
while developing against a checkout:

```nix
inputs.reaper-flake.url = "path:../reaper-flake";
```
