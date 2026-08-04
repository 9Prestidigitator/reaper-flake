{
  lib,
  pkgs,
  runCommand,
}: let
  evaluate = extraModule:
    lib.evalModules {
      specialArgs = {inherit pkgs;};
      modules = [
        ../modules/line-files.nix
        ../modules/resources.nix
        ../modules/extensions/sws.nix
        {
          options.assertions = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [];
          };
        }
        extraModule
      ];
    };

  unmanaged = (evaluate {}).config.programs.reaper;

  managed =
    (evaluate {
      programs.reaper = {
        extensions.sws = {
          enable = true;
          colors = ["#F5E0E6" "#012345"];
        };
        lineFiles.files."Scripts/__startup.lua" = ["user_startup_line()"];
      };
    }).config;

  cleared =
    (evaluate {
      programs.reaper.extensions.sws = {
        enable = true;
        colors = [];
      };
    }).config;

  disabled =
    (evaluate {
      programs.reaper.extensions.sws.colors = ["#F5E0E6"];
    }).config;

  tooMany =
    (evaluate {
      programs.reaper.extensions.sws = {
        enable = true;
        colors = builtins.genList (_: "#000000") 17;
      };
    }).config;

  invalidColorValue =
    (evaluate {
      programs.reaper.extensions.sws = {
        enable = true;
        colors = ["F5E0E6"];
      };
    }).config.programs.reaper.extensions.sws.colors;

  invalidColor = builtins.tryEval (builtins.deepSeq invalidColorValue invalidColorValue);

  managedScript = managed.programs.reaper.resourceFiles.files."Scripts/reaper-flake/sws-colors.lua";
  managedStartup = managed.programs.reaper.lineFiles.generatedFiles."Scripts/__startup.lua";
  clearedScript = cleared.programs.reaper.resourceFiles.files."Scripts/reaper-flake/sws-colors.lua";

  luaTest = pkgs.writeText "test-sws-colors.lua" ''
    local calls = {}
    reaper = {
      APIExists = function(name)
        assert(name == "CF_SetCustomColor")
        return true
      end,
      defer = function()
        error("defer should not be called when SWS is available")
      end,
      ColorToNative = function(red, green, blue)
        return red * 65536 + green * 256 + blue
      end,
      CF_SetCustomColor = function(index, color)
        calls[index + 1] = { index = index, color = color }
      end,
    }

    dofile(${builtins.toJSON (toString managedScript)})

    assert(#calls == 16)
    assert(calls[1].index == 0 and calls[1].color == 0xF5E0E6)
    assert(calls[2].index == 1 and calls[2].color == 0x012345)
    assert(calls[3].index == 2 and calls[3].color == 0)
    assert(calls[16].index == 15 and calls[16].color == 0)

    calls = {}
    dofile(${builtins.toJSON (toString clearedScript)})
    assert(#calls == 16)
    for index, call in ipairs(calls) do
      assert(call.index == index - 1 and call.color == 0)
    end
  '';
in
  assert unmanaged.extensions.sws.colors == null;
  assert unmanaged.resourceFiles.files == {};
  assert unmanaged.lineFiles.files == {};
  assert builtins.all (entry: entry.assertion) managed.assertions;
  assert builtins.all (entry: entry.assertion) cleared.assertions;
  assert builtins.any (entry: !entry.assertion) disabled.assertions;
  assert builtins.any (entry: !entry.assertion) tooMany.assertions;
  assert !invalidColor.success;
    runCommand "reaper-sws-colors-tests" {
      nativeBuildInputs = [pkgs.lua];
    } ''
      grep -F 'user_startup_line()' ${managedStartup}
      grep -F 'pcall(dofile, reaper.GetResourcePath() .. "/Scripts/reaper-flake/sws-colors.lua")' ${managedStartup}
      lua ${luaTest}
      touch "$out"
    ''
