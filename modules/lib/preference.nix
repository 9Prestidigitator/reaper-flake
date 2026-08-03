{
  lib,
  reaperCodecs,
}: let
  inherit (lib) mkOption optional;

  option = spec:
    mkOption {
      type = spec.type;
      default = spec.default or null;
      example = spec.example or null;
      description = spec.description;
    };

  contribution = spec: let
    value = spec.value;
  in
    optional (value != null) {
      kind = "value";
      file = spec.file or "reaper.ini";
      section = spec.section;
      key = spec.key;
      value = value;
      codec = spec.codec or "identity";
      optionPath = spec.path;
      gui = spec.gui or null;
    };

  contributions = specs: builtins.concatLists (map contribution specs);
in {
  inherit contribution contributions option;
}
