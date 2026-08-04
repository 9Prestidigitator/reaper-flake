{lib}: let
  enum = values: {
    type = "enum";
    inherit values;
  };

  bool = {
    trueValue ? 1,
    falseValue ? 0,
  }: {
    type = "bool";
    inherit falseValue trueValue;
  };

  cpuIndexes = {
    type = "cpu-indexes";
    width = 32;
  };

  powerOfTwo = exponent:
    if exponent == 0
    then 1
    else 2 * powerOfTwo (exponent - 1);

  encode = codec: value:
    if codec == null || codec == "identity"
    then value
    else if codec == "bool"
    then
      if value
      then 1
      else 0
    else if codec == "integer" || codec == "float" || codec == "list"
    then value
    else if builtins.isAttrs codec && codec.type == "decibels"
    then value
    else if builtins.isAttrs codec && codec.type == "bool"
    then
      if value
      then codec.trueValue
      else codec.falseValue
    else if builtins.isAttrs codec && codec.type == "cpu-indexes"
    then builtins.foldl' (mask: cpu: mask + powerOfTwo cpu) 0 (lib.unique value)
    else if builtins.isAttrs codec && codec.type == "enum"
    then codec.values.${value}
    else throw "Unsupported REAPER preference codec.";

  decode = codec: value:
    if codec == null || codec == "identity"
    then value
    else if codec == "bool"
    then value != 0
    else if codec == "integer"
    then builtins.fromJSON (toString value)
    else if codec == "float"
    then builtins.fromJSON (toString value)
    else if codec == "list"
    then lib.splitString ";" value
    else if builtins.isAttrs codec && codec.type == "decibels"
    then value
    else if builtins.isAttrs codec && codec.type == "bool"
    then
      if value == codec.trueValue
      then true
      else if value == codec.falseValue
      then false
      else throw "Unknown value ${toString value} for REAPER boolean codec."
    else if builtins.isAttrs codec && codec.type == "cpu-indexes"
    then
      builtins.filter
      (index: builtins.bitAnd value (powerOfTwo index) != 0)
      (lib.range 0 (codec.width - 1))
    else if builtins.isAttrs codec && codec.type == "enum"
    then
      lib.findFirst
      (name: codec.values.${name} == value)
      (throw "Unknown value ${toString value} for REAPER enum codec.")
      (builtins.attrNames codec.values)
    else throw "Unsupported REAPER preference codec.";
in {
  inherit bool cpuIndexes decode encode enum;
}
