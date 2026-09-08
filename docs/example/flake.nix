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

  outputs = {reaper-flake, ...}: {
    homeModules.default = {config, ...}: {
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
    };
  };
}
