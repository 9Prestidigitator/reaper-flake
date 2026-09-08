# Modular example flake

This directory is a complete REAPER Home Manager configuration that can also be imported as a reusable module. Its direct inputs are `nixpkgs`, Home Manager, and `reaper-flake`.

The enabled example is an opinionated, community-informed music-production setup. It combines the strongest recurring recommendations with portable ergonomic choices that make the flake's capabilities concrete:

- [`preferences.nix`](preferences.nix) covers project safety, backups, track and
  item defaults, low-latency monitoring, visual feedback, MIDI editing, mouse
  behavior, and media handling.
- [`extensions.nix`](extensions.nix) installs SWS, ReaPack, and the Reapertips
  theme, plus one focused MIDI-editing script and a useful SWS color palette.
- [`actions.nix`](actions.nix), [`menus.nix`](menus.nix), and
  [`layout.nix`](layout.nix) demonstrate declarative scripts, shortcuts,
  toolbars, menus, windows, docks, and panels.

