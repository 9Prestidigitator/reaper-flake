{lib}: {
  reaperWindows = import ./windows.nix {inherit lib;};
  reaperMouse = import ./mouse.nix {inherit lib;};
}
