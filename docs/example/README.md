# Modular example flake

This directory is a complete REAPER Home Manager configuration that can also
be imported as a reusable module. Its direct inputs are `nixpkgs`, Home
Manager, and `reaper-flake`.

The example is split by responsibility:

- [`preferences.nix`](preferences.nix) configures representative preferences.
- [`extensions.nix`](extensions.nix) installs ReaPack, SWS, themes, and plug-in paths.
- [`menus.nix`](menus.nix) defines a menu, context menu, and toolbar.
- [`actions.nix`](actions.nix) installs a ReaScript and binds shortcuts.
- [`layout.nix`](layout.nix) defines windows, docks, and panels.

Copy this directory into your configuration repository and edit each module to
fit your setup. Before activating it, change these placeholders in `flake.nix`:

- `system`
- `homeConfigurations.your-user`
- `home.username`
- `home.homeDirectory`
- `home.stateVersion`, if your existing Home Manager configuration uses a
  different value

Then create the lock file and activate the configuration:

```console
nix flake lock
home-manager switch --flake .#your-user
```

Replace the `reaper-flake` URL with a local path while developing against a
checkout:

```nix
inputs.reaper-flake.url = "path:../reaper-flake";
```

## Import into an existing configuration

If Home Manager is already configured elsewhere, add this example as an input
to that flake and import its reusable module:

```nix
inputs.reaper-config.url = "path:./reaper-config";
```

```nix
home-manager.users.your-user.imports = [
  inputs.reaper-config.homeModules.default
];
```

The example writes to `~/.config/reaper-example`, keeping it separate from the
default REAPER resource directory. Close REAPER before activating changes.

The values are illustrative. In particular, change the MIDI device indexes,
OSC address, web-control credentials, filesystem paths, and ReaPack packages
before adopting the configuration.
