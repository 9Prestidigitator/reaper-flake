{lib}: let
  enum = values: {
    type = "enum";
    inherit values;
  };

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
    else if builtins.isAttrs codec && codec.type == "enum"
    then
      lib.findFirst
      (name: codec.values.${name} == value)
      (throw "Unknown value ${toString value} for REAPER enum codec.")
      (builtins.attrNames codec.values)
    else throw "Unsupported REAPER preference codec.";
in {
  inherit decode encode enum;
}
