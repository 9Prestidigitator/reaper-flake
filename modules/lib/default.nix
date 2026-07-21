{lib}: {
  reaperTypes = import ./types.nix {inherit lib;};
  # helper method that really smooths out associating bitfields with reaper options
  reaperBitfield = import ./bitfield.nix {inherit lib;};

  reaperLayout = import ./layout.nix;
  reaperWindows = import ./windows.nix;

  reaperMouse = import ./mouse.nix {inherit lib;};
  reaperActions = import ./actions.nix {inherit lib;};

  reaperGeneral = import ./general.nix;
  reaperProject = import ./project.nix {inherit lib;};
  reaperAppearance = import ./appearance.nix;

  reapack = import ./reapack.nix;
}
