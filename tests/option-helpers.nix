{
  lib,
  runCommand,
}: let
  reaperLib = import ../modules/lib {inherit lib;};
  values = {
    first = 0;
    second = 4;
  };
  evaluate = configuration:
    lib.evalModules {
      modules = [
        {_module.args = {inherit (reaperLib) reaBool reaEnum;};}
        ({
          reaBool,
          reaEnum,
          ...
        }: {
          options = {
            flag = reaBool "Boolean shorthand.";
            detailed = reaBool {
              description = "Boolean with metadata.";
              default = false;
              example = false;
              visible = false;
              internal = true;
            };
            noExample = reaBool {description = "No example supplied.";};
            numeric = reaEnum {
              enum = values;
              description = "Numeric values.";
            };
            strings = reaEnum {
              enum = ["first" "second"];
              description = "String values.";
              default = "first";
              example = "second";
            };
            named = reaEnum {
              enum = values;
              coerce = "names";
              description = "Canonical names.";
            };
            numbered = reaEnum {
              enum = values;
              coerce = "values";
              description = "Canonical numbers.";
              example = lib.literalExpression "values.second";
            };
          };
          config = configuration;
        })
      ];
    };
  defaults = evaluate {};
  configured = evaluate {
    flag = true;
    numeric = 4;
    strings = "second";
    named = 4;
    numbered = "second";
  };
  rejects = config: !(builtins.tryEval (builtins.deepSeq (evaluate config).config true)).success;
in
  assert defaults.config
  == {
    flag = null;
    detailed = false;
    noExample = null;
    numeric = null;
    strings = "first";
    named = null;
    numbered = null;
  };
  assert configured.config.flag;
  assert configured.config.numeric == 4;
  assert configured.config.strings == "second";
  assert configured.config.named == "second";
  assert configured.config.numbered == 4;
  assert defaults.options.flag.example == true;
  assert defaults.options.detailed.example == false;
  assert defaults.options.detailed.visible == false;
  assert defaults.options.detailed.internal == true;
  assert !(defaults.options.noExample ? example);
  assert defaults.options.strings.example == "second";
  assert defaults.options.numbered.example == lib.literalExpression "values.second";
  assert (evaluate {flag = lib.mkDefault true;}).config.flag;
  assert rejects {flag = "true";};
  assert rejects {numeric = "second";};
  assert rejects {strings = "missing";};
  assert rejects {named = 99;};
  assert rejects {numbered = "missing";};
    runCommand "reaper-option-helper-tests" {} ''
      touch "$out"
    ''
