{lib}: let
  inherit (lib) mkOption types;
  reaperTypes = import ./types.nix {inherit lib;};
in {
  # The string shorthand retains windows.nix's conventional true example.
  # Attribute sets pass mkOption metadata through without inventing examples.
  reaBool = spec:
    mkOption ({
        type = types.nullOr types.bool;
        default = null;
      }
      // (
        if builtins.isString spec
        then {
          description = spec;
          example = true;
        }
        else spec
      ));

  # Lists describe accepted values directly; attribute sets use their values.
  # Coercion preserves the existing namedEnum/numericEnum representations.
  reaEnum = {
    enum,
    coerce ? null,
    ...
  } @ spec: let
    enumType =
      if coerce == "names"
      then reaperTypes.namedEnum enum
      else if coerce == "values"
      then reaperTypes.numericEnum enum
      else if coerce == null
      then
        types.enum (
          if builtins.isAttrs enum
          then builtins.attrValues enum
          else enum
        )
      else throw "reaEnum.coerce must be null, names, or values.";
  in
    mkOption ({
        type = types.nullOr enumType;
        default = null;
      }
      // removeAttrs spec ["enum" "coerce"]);
}
