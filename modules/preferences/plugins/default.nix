{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./Compatibility.nix
    ./vst.nix
    ./lv2Clap.nix
    ./ara.nix
    ./ReaScript.nix
  ];

  options.programs.reaper.preferences.plugIns.nixSystemPaths = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.hostPlatform.isLinux;
      defaultText = "pkgs.stdenv.hostPlatform.isLinux";
      description = ''
        Whether to include plugin directories from the current Nix system
        profile, such as `/run/current-system/sw/lib/vst3`.
      '';
    };
    root = lib.mkOption {
      type = lib.types.str;
      default = "/run/current-system/sw";
      description = "Root profile used for NixOS system plugin paths.";
    };
  };
}
