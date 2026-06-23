{lib}: {
  reaperWindows = import ./windows.nix;
  reaperAppearance = import ./appearance.nix;
  reaperMouse = import ./mouse.nix {inherit lib;};
  reaperActions = import ./actions.nix {inherit lib;};
}
