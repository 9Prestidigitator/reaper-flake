{
  config,
  lib,
  pkgs,
  reaperLib,
  ...
}: let
  inherit (lib) optionals mkEnableOption types mkOption optionalAttrs literalExpression unique;
  inherit (reaperLib) reaperBitfield;

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

  userVstPaths = optionals cfg.vst.enableUserPaths [
    "~/.vst"
    "~/.vst3"
  ];
  userClapPaths = optionals cfg.clap.enableUserPaths [
    "/usr/local/lib/clap"
    "/usr/lib/clap"
    "~/.clap"
    "%CLAP_PATH%"
  ];
  userLv2Paths = optionals cfg.lv2.enableUserPaths [
    "/usr/lib/lv2"
    "/usr/local/lib/lv2"
    "~/.lv2"
  ];

  vstSearchPaths = unique (nixSystemVstPaths ++ userVstPaths ++ cfg.vst.searchPaths);
  clapSearchPaths = unique (nixSystemClapPaths ++ userClapPaths ++ cfg.clap.searchPaths);
  lv2SearchPaths = unique (nixSystemLv2Paths ++ userLv2Paths ++ cfg.lv2.searchPaths);
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

    vst = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/Documents/vsts" "~/Downloads/vst3"];
        description = ''Additional VST(3) search paths appended to `[reaper].vstpath`.'';
      };
      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = ''Whether to include default ~/.vst(3) paths in searchPaths'';
      };
    };
    lv2 = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.lv2"];
        description = ''Additional LV2 search paths appended to `[reaper].lv2path_linux`.'';
      };
      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = ''Whether to include default ~/.lv2 paths in searchPaths'';
      };
    };
    clap = {
      searchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["~/.clap"];
        description = ''Additional CLAP search paths appended to REAPER's Linux Clap path.'';
      };
      enableUserPaths = mkOption {
        type = types.bool;
        default = true;
        description = ''Whether to include default ~/.clap paths in searchPaths'';
      };
    };
    reascript.python = {
      enable = mkEnableOption "Python support in REAPER";

      package = mkOption {
        type = types.package;
        default = pkgs.python3;
        defaultText = literalExpression "pkgs.python3";
        description = ''
          Python package made available to REAPER for Python ReaScripts when
          using the module's default `programs.reaper.package` (BROKEN).
        '';
      };
    };
  };

  config.programs.reaper.ini.sections.reaper =
    optionalAttrs (vstSearchPaths != []) {vstpath = vstSearchPaths;}
    // optionalAttrs (clapSearchPaths != []) {${clapPathKey} = clapSearchPaths;}
    // optionalAttrs (lv2SearchPaths != []) {lv2path_linux = lv2SearchPaths;}
    // optionalAttrs cfg.reascript.python.enable {
      pythonlibpath64 = "${cfg.reascript.python.package}/lib";
      pythonlibdll64 = "libpython${cfg.reascript.python.package.pythonVersion}.so";
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    reascript = [
      {
        optionPath = "preferences.plugIns.reascript.python.enable";
        gui = "Enable ReaScript";
        configured = cfg.reascript.python.enable;
        option = cfg.reascript.python.enable;
        bit = 1;
      }
    ];
  };
}
