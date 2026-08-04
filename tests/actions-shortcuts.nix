{
  lib,
  runCommand,
}: let
  reaperActions = import ../modules/lib/actions.nix {inherit lib;};
  symbols = ["!" "\"" "#" "$" "%" "&" "'" "(" ")" "*" "+" "," "-" "." "/" ":" ";" "<" "=" ">" "?" "@" "[" "\\" "]" "^" "_" "`" "{" "|" "}" "~"];
  expectedKeyCodes = [33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 58 59 60 61 62 63 64 91 92 93 94 95 96 123 124 125 126];
  bindingFor = shortcut:
    reaperActions.shortcut {
      inherit shortcut;
      command = 1007;
    };
  selectEncoding = binding: {
    inherit (binding) keyCode modifierFlags;
  };
  actual = map (shortcut: selectEncoding (bindingFor shortcut)) symbols;
  expected =
    map (keyCode: {
      inherit keyCode;
      modifierFlags = 0;
    })
    expectedKeyCodes;
  dollar = bindingFor "$";
  physicalDollar = bindingFor "Shift+4";
  controlDollar = bindingFor "Ctrl+$";
  literalPlus = bindingFor "+";
  physicalPlus = bindingFor "Shift+plus";
in
  assert actual == expected;
  assert dollar.keyCode == 36;
  assert dollar.modifierFlags == 0;
  assert physicalDollar.keyCode == 52;
  assert physicalDollar.modifierFlags == 5;
  assert controlDollar.keyCode == 36;
  assert controlDollar.modifierFlags == 8;
  assert literalPlus.keyCode == 43;
  assert literalPlus.modifierFlags == 0;
  assert physicalPlus.keyCode == 187;
  assert physicalPlus.modifierFlags == 5;
    runCommand "reaper-actions-shortcut-tests" {} ''
      touch "$out"
    ''
