{lib}: let
  reaperCodecs = import ./codecs.nix {inherit lib;};
in {
  reaperTypes = import ./types.nix {inherit lib;};
  inherit reaperCodecs;
  reaperPreference = import ./preference.nix {inherit lib;};
  # helper method that really smooths out associating bitfields with reaper options
  reaperBitfield = import ./bitfield.nix {inherit lib;};

  reaperLayout = import ./layout.nix;
  reaperMenus = import ./menus.nix;
  reaperWindows = import ./windows.nix;

  reaperActions = import ./actions.nix {inherit lib;};

  reaperGeneral = import ./general.nix;
  reaperProject = import ./project.nix;
  reaperAudio = import ./audio.nix;
  reaperAppearance = import ./appearance.nix;
  reaperEditingBehavior = import ./editing-behavior.nix;
  reaperMouse = import ./mouse.nix {inherit lib;};
  reaperMedia = import ./media.nix;
  reaperPlugins = import ./plugins.nix {inherit lib;};
  reaperControlOscWeb = import ./control-osc-web.nix;

  reapack = import ./reapack.nix;
}
