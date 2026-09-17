{
  lib,
  pkgs,
  runCommand,
}: let
  reaperLib = import ../modules/lib {inherit lib;};
  evaluate = menus:
    (lib.evalModules {
      specialArgs = reaperLib // {inherit pkgs reaperLib;};
      modules = [
        ../modules/ini.nix
        ../modules/menus.nix
        {
          options.assertions = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [];
          };
          config.programs.reaper.menus = menus;
        }
      ];
    }).config.programs.reaper.ini;
  configured = evaluate {
    "Main toolbar" = [
      {
        action = 40023;
        label = "New";
      }
    ];
    "Main file" = null;
  };
  empty = evaluate {"Main toolbar" = [];};
in
  runCommand "reaper-menu-replacement-tests" {
    nativeBuildInputs = [pkgs.python3];
    WRITER = ../scripts/write_config.py;
    CONFIGURED = configured.generatedPayloadFiles."reaper-menu.ini";
    EMPTY = empty.generatedPayloadFiles."reaper-menu.ini";
  } ''
    python3 - <<'PY'
    import json, os, pathlib, subprocess, sys
    target = pathlib.Path("reaper-menu.ini")
    state = pathlib.Path("state.json")
    target.write_text("[Main toolbar]\nitem_0=old\nitem_1=extra\nicon_0=old.png\n[Main file]\nitem_0=old\n[Other]\nkeep=yes\n")
    def write(payload):
        subprocess.run([sys.executable, os.environ["WRITER"], str(target), str(state), payload], check=True)
    payload = json.loads(pathlib.Path(os.environ["CONFIGURED"]).read_text())
    assert payload["replaceSections"] == ["Main toolbar"]
    assert payload["removeSections"] == ["Main file"]
    write(os.environ["CONFIGURED"])
    assert target.read_text() == "[Other]\nkeep=yes\n\n[Main toolbar]\nitem_0=40023 New\n", target.read_text()
    write(os.environ["EMPTY"])
    assert target.read_text() == "[Other]\nkeep=yes\n\n[Main toolbar]\n", target.read_text()
    PY
    touch "$out"
  ''
