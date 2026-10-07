{
  lib,
  pkgs,
  runCommand,
}: let
  reaperLib = import ../modules/lib {inherit lib;};

  evaluateFor = system: extraModule:
    lib.evalModules {
      specialArgs =
        reaperLib
        // {
          inherit reaperLib;
          pkgs = pkgs // {stdenv = pkgs.stdenv // {hostPlatform = lib.systems.elaborate system;};};
        };
      modules = [
        ../modules/ini.nix
        ../modules/preferences/plugins
        {
          options.assertions = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [];
          };
          options.warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          options.home.username = lib.mkOption {
            type = lib.types.str;
            default = "test-user";
          };
          options.programs.reaper.configPath = lib.mkOption {
            type = lib.types.str;
            default = "/tmp/reaper-plugin-path-tests";
          };
        }
        extraModule
      ];
    };

  evaluate = evaluateFor "x86_64-linux";
  platformCases = [
    {
      system = "x86_64-linux";
      vst = "vstpath";
      lv2 = "lv2path_linux";
      clap = "clap_path_linux-x86_64";
      mac = false;
    }
    {
      system = "aarch64-linux";
      vst = "vstpath";
      lv2 = "lv2path_linux";
      clap = "clap_path_linux-aarch64";
      mac = false;
    }
    {
      system = "x86_64-darwin";
      vst = "vstpath64";
      lv2 = "lv2path_mac";
      clap = "clap_path_macos-x86_64";
      mac = true;
    }
    {
      system = "aarch64-darwin";
      vst = "vstpath_arm64";
      lv2 = "lv2path_mac";
      clap = "clap_path_macos-aarch64";
      mac = true;
    }
  ];
  checkPlatform = case: let
    userPaths = {
      vst =
        if case.mac
        then ["/Library/Audio/Plug-Ins/VST" "/Library/Audio/Plug-Ins/VST3" "~/Library/Audio/Plug-Ins/VST" "~/Library/Audio/Plug-Ins/VST3"]
        else ["~/.vst" "~/.vst3"];
      lv2 =
        (
          if case.mac
          then ["/Library/Audio/Plug-Ins/LV2" "~/Library/Audio/Plug-Ins/LV2"]
          else ["/usr/lib/lv2" "/usr/local/lib/lv2" "~/.lv2"]
        )
        ++ ["%LV2_PATH%"];
      clap =
        (
          if case.mac
          then ["/Library/Audio/Plug-Ins/CLAP" "~/Library/Audio/Plug-Ins/CLAP"]
          else ["/usr/local/lib/clap" "/usr/lib/clap" "~/.clap"]
        )
        ++ ["%CLAP_PATH%"];
    };
    checkMode = nix: user: mutable: let
      result =
        (evaluateFor case.system {
          programs.reaper.preferences.plugIns = lib.genAttrs ["vst" "lv2" "clap"] (format: {
            searchPaths = ["/custom/${format}" "/custom/${format}"];
            enableNixPaths = nix;
            enableUserPaths = user;
            inherit mutable;
          });
        }).config.programs.reaper.ini;
      entries = result.sections.reaper;
    in
      assert builtins.attrNames entries == lib.sort builtins.lessThan [case.vst case.lv2 case.clap];
      assert lib.all (
        format:
          entries.${case.${format}}
          == ["/custom/${format}"]
          ++ lib.optionals nix (reaperLib.reaperPlugins.profilePaths "test-user" (
            if format == "vst"
            then ["vst" "vst3"]
            else [format]
          ))
          ++ lib.optionals user userPaths.${format}
      ) ["vst" "lv2" "clap"];
      assert lib.all (c:
        c.mutable
        == mutable
        && c.key
        == case.${
          if lib.hasInfix ".vst." c.optionPath
          then "vst"
          else if lib.hasInfix ".lv2." c.optionPath
          then "lv2"
          else "clap"
        })
      (lib.filter (c: lib.elem c.optionPath ["preferences.plugIns.vst.searchPaths" "preferences.plugIns.lv2.searchPaths" "preferences.plugIns.clap.searchPaths"]) result.contributions); true;
  in
    lib.all (nix: lib.all (user: lib.all (mutable: checkMode nix user mutable) [true false]) [true false]) [true false];

  defaults = (evaluate {}).config.programs.reaper.ini.sections.reaper;

  explicit =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        vst.searchPaths = ["/exact/vst" "/exact/vst3" "/exact/vst"];
        lv2.searchPaths = ["/exact/lv2"];
        clap.searchPaths = ["/exact/clap"];
      };
    }).config.programs.reaper.ini.sections.reaper;

  onlyCustom =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        vst = {
          searchPaths = ["/exact/vst" "/exact/vst3"];
          enableNixPaths = false;
          enableUserPaths = false;
        };
        lv2 = {
          searchPaths = ["/exact/lv2"];
          enableNixPaths = false;
          enableUserPaths = false;
        };
        clap = {
          searchPaths = ["/exact/clap"];
          enableNixPaths = false;
          enableUserPaths = false;
        };
      };
    }).config.programs.reaper.ini.sections.reaper;

  empty =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        vst = {
          enableNixPaths = false;
          enableUserPaths = false;
        };
        lv2 = {
          enableNixPaths = false;
          enableUserPaths = false;
        };
        clap = {
          enableNixPaths = false;
          enableUserPaths = false;
        };
      };
    }).config.programs.reaper.ini.sections.reaper;

  pluginUi =
    (evaluate {
      programs.reaper.preferences.plugIns = {
        automaticallyResizeFxWindow = {
          up = true;
          down = false;
        };
        autoFloatUiForFxCreatedViaFxBrowser = true;
        autoFloatUiForFxCreatedViaRightClickMenu = false;
        fxChainPositioning = "automatic";
        floatingFxPositioning = "modalDefault";
        onlyAllowOneFxFloatingAtATime.onePerTrack = true;
        preservePinMappingsWhenLoadingPresets = false;
        onlyShowFxMatchingFilterString = "";
        recentlyUsedListMax = 42;
      };
    }).config.programs.reaper.ini;

  mutableWithNonListCodec = evaluate {
    programs.reaper.ini.contributions = reaperLib.reaperPreference.contribution {
      path = "test.bad";
      value = "hello";
      section = "reaper";
      key = "badkey";
      codec = "identity";
      mutable = true;
      configured = true;
    };
  };

  mutableWithListCodec = evaluate {
    programs.reaper.ini.contributions = reaperLib.reaperPreference.contribution {
      path = "test.good";
      value = ["hello"];
      section = "reaper";
      key = "goodkey";
      codec = "list";
      mutable = true;
      configured = true;
    };
  };

  clapKey = "clap_path_linux-x86_64";
in
  assert lib.all checkPlatform platformCases;
  # Unset UI preferences must not overwrite REAPER's defaults.
  assert !(defaults ? fxresize);
  assert (evaluate {}).config.programs.reaper.ini.bitfields == {};
  assert pluginUi.bitfields.reaper.fxresize
  == {
    mask = 3;
    value = 1;
  };
  assert pluginUi.bitfields.reaper.fxfloat_focus
  == {
    mask = 134614148;
    value = 134481028;
  };
  assert pluginUi.bitfields.reaper.vstfullstate
  == {
    mask = 8388608;
    value = 0;
  };
  assert pluginUi.sections.reaper.def_fx_filtgen == "";
  assert pluginUi.sections.reaper.maxrecentfx == 42;
  assert defaults.vstpath
  == [
    "/etc/profiles/per-user/test-user/lib/vst"
    "/etc/profiles/per-user/test-user/lib/vst3"
    "~/.nix-profile/lib/vst"
    "~/.nix-profile/lib/vst3"
    "/run/current-system/sw/lib/vst"
    "/run/current-system/sw/lib/vst3"
    "~/.vst"
    "~/.vst3"
  ];
  assert defaults.lv2path_linux
  == [
    "/etc/profiles/per-user/test-user/lib/lv2"
    "~/.nix-profile/lib/lv2"
    "/run/current-system/sw/lib/lv2"
    "/usr/lib/lv2"
    "/usr/local/lib/lv2"
    "~/.lv2"
    "%LV2_PATH%"
  ];
  assert defaults.${clapKey}
  == [
    "/etc/profiles/per-user/test-user/lib/clap"
    "~/.nix-profile/lib/clap"
    "/run/current-system/sw/lib/clap"
    "/usr/local/lib/clap"
    "/usr/lib/clap"
    "~/.clap"
    "%CLAP_PATH%"
  ];
  assert explicit.vstpath
  == [
    "/exact/vst"
    "/exact/vst3"
    "/etc/profiles/per-user/test-user/lib/vst"
    "/etc/profiles/per-user/test-user/lib/vst3"
    "~/.nix-profile/lib/vst"
    "~/.nix-profile/lib/vst3"
    "/run/current-system/sw/lib/vst"
    "/run/current-system/sw/lib/vst3"
    "~/.vst"
    "~/.vst3"
  ];
  assert explicit.lv2path_linux
  == [
    "/exact/lv2"
    "/etc/profiles/per-user/test-user/lib/lv2"
    "~/.nix-profile/lib/lv2"
    "/run/current-system/sw/lib/lv2"
    "/usr/lib/lv2"
    "/usr/local/lib/lv2"
    "~/.lv2"
    "%LV2_PATH%"
  ];
  assert explicit.${clapKey}
  == [
    "/exact/clap"
    "/etc/profiles/per-user/test-user/lib/clap"
    "~/.nix-profile/lib/clap"
    "/run/current-system/sw/lib/clap"
    "/usr/local/lib/clap"
    "/usr/lib/clap"
    "~/.clap"
    "%CLAP_PATH%"
  ];
  assert onlyCustom.vstpath == ["/exact/vst" "/exact/vst3"];
  assert onlyCustom.lv2path_linux == ["/exact/lv2"];
  assert onlyCustom.${clapKey} == ["/exact/clap"];
  assert empty.vstpath == [];
  assert empty.lv2path_linux == [];
  assert empty.${clapKey} == [];
  assert !(lib.all (x: x.assertion) mutableWithNonListCodec.config.assertions);
  assert lib.any (x: !x.assertion && lib.hasInfix "mutable = true but codec is" x.message) mutableWithNonListCodec.config.assertions;
  assert lib.all (x: x.assertion) mutableWithListCodec.config.assertions;
    runCommand "reaper-plugin-path-tests" {} ''
      touch "$out"
    ''
