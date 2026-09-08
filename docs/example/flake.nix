{
  description = "Example declarative REAPER configuration";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    reaper-flake = {
      url = "github:9Prestidigitator/reaper-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    home-manager,
    nixpkgs,
    reaper-flake,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    reaperModule = {config, ...}: {
      imports = [
        reaper-flake.homeModules.reaper
        ./actions.nix
        ./extensions.nix
        ./layout.nix
        ./menus.nix
        ./preferences.nix
        {
          programs.reaper = {
            enable = true;

            # Use a separate resource directory while trying the example. Remove this
            # line to accept reaper-flake's default path.
            configPath = "${config.xdg.configHome}/reaper-example";
          };
        }
      ];

      # Makes the reaper-flake package set available to extensions.nix.
      _module.args.reaperFlake = reaper-flake;
    };
  in {
    # A complete standalone Home Manager configuration. Change these example
    # identity values and `system` above before activating it.
    homeConfigurations.your-user = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        reaperModule
        {
          home = {
            username = "your-user";
            homeDirectory = "/home/your-user";
            stateVersion = "26.11";
          };
        }
      ];
    };

    # Also expose the REAPER portion for users who want to import it into an
    # existing Home Manager configuration instead of using the output above.
    homeModules.default = reaperModule;
  };
}
