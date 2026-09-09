{lib}: let
  inherit (lib) concatMap;

  profileLibDirectories = username: [
    "/etc/profiles/per-user/${username}/lib"
    "~/.nix-profile/lib"
    "/run/current-system/sw/lib"
  ];
in {
  inherit profileLibDirectories;

  profilePaths = username: formats:
    concatMap (
      directory: map (format: "${directory}/${format}") formats
    )
    (profileLibDirectories username);

  chainPositioning = {
    cascade = 0;
    automatic = 1024;
    modalDefault = 131072;
  };
  floatingPositioning = {
    cascade = 0;
    automatic = 2048;
    modalDefault = 262144;
  };
}
