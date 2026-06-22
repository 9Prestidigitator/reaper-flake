{lib}: {
  reaperWindows = import ./windows.nix;
  reaperMouse = import ./mouse.nix {inherit lib;};
  reaperAppearance = import ./appearance.nix;
}
