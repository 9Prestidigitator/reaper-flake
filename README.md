# reaper-flake

Declare your REAPER configuration with Nix.

# Packages

- REAPER: `7.74`
- ReaPack: `1.2.6`
- SWS: `2.14.0.7`
- Reapertips Theme: `1.90`

Package derivations originally from nixpkgs with updated hashes and small tweaks.

# Home Manager Module

Declare your own REAPER configuration using Home Manager.

## Example

```nix
{
  imports = [inputs.reaper-flake.homeModules.reaper];

  programs.reaper = {
    enable = true;
    extensions = {
      reapack.enable = true;
      sws.enable = true;
    };
  };
}
```

# TODO

Create a script that takes the final Nix options and applies them to the existing REAPER INI files without overriding stateful data. Plasma Manager does this with a Python activation script, so this will likely follow a similar approach.

# Inspirations

- [plasma-manager](https://github.com/nix-community/plasma-manager)
- [audio.nix](https://github.com/polygon/audio.nix)
