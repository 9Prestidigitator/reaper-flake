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
}
