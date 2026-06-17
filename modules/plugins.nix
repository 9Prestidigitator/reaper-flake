{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) optionals types mkOption optionalAttrs unique;

  cfg = config.programs.reaper.preferences.plugIns;
  nixSystemRoot = cfg.nixSystemPaths.root;

  clapPathKey = "clap_path_linux-${pkgs.stdenv.hostPlatform.qemuArch}";

  nixSystemVstPaths = optionals cfg.nixSystemPaths.enable [
    "${nixSystemRoot}/lib/vst"
    "${nixSystemRoot}/lib/vst3"
  ];
  nixSystemClapPaths = optionals cfg.nixSystemPaths.enable [
    "${nixSystemRoot}/lib/clap"
  ];
  nixSystemLv2Paths = optionals cfg.nixSystemPaths.enable [
    "${nixSystemRoot}/lib/lv2"
  ];

  vstSearchPaths = unique (nixSystemVstPaths ++ cfg.vst.searchPaths);
  clapSearchPaths = unique (nixSystemClapPaths ++ cfg.clap.searchPaths);
  lv2SearchPaths = unique (nixSystemLv2Paths ++ cfg.lv2.searchPaths);
in {
  options.programs.reaper.preferences.plugIns = {
    nixSystemPaths = {
      enable = mkOption {
        type = types.bool;
        default = pkgs.stdenv.hostPlatform.isLinux;
        defaultText = "pkgs.stdenv.hostPlatform.isLinux";
        description = ''
          Whether to include plugin directories from the current Nix system
          profile, such as `/run/current-system/sw/lib/vst3`.
        '';
      };
      root = mkOption {
        type = types.str;
        default = "/run/current-system/sw";
        description = "Root profile used for NixOS system plugin paths.";
      };
    };

    vst.searchPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/.vst" "~/.vst3"];
      description = ''Additional VST(3) search paths appended to `[reaper].vstpath`.'';
    };
    lv2.searchPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/.lv2"];
      description = ''Additional LV2 search paths appended to `[reaper].lv2path_linux`.'';
    };
    clap.searchPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/.clap"];
      description = ''Additional CLAP search paths appended to REAPER's Linux Clap path.'';
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (vstSearchPaths != []) {vstpath = vstSearchPaths;}
    // optionalAttrs (clapSearchPaths != []) {${clapPathKey} = clapSearchPaths;}
    // optionalAttrs (lv2SearchPaths != []) {lv2path_linux = lv2SearchPaths;};
}
