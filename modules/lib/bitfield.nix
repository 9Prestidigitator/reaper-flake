{lib}: let
  inherit (lib) filterAttrs;

  sum = builtins.foldl' (total: value: total + value) 0;

  part = spec: let
    mask =
      if spec ? mask
      then spec.mask
      else spec.bit;
    option = spec.option or null;
    configured =
      if spec ? configured
      then spec.configured
      else option != null;
    inverted = spec.inverted or false;
    trueValue =
      if spec ? trueValue
      then spec.trueValue
      else if inverted
      then 0
      else mask;
    falseValue =
      if spec ? falseValue
      then spec.falseValue
      else if inverted
      then mask
      else 0;
    value =
      if !configured
      then 0
      else if spec ? value
      then spec.value
      else if spec ? valueFor
      then spec.valueFor option
      else if builtins.isBool option
      then
        if option
        then trueValue
        else falseValue
      else option;
  in {
    mask =
      if configured
      then mask
      else 0;
    inherit value;
  };

  from = specs: let
    parts = map part specs;
  in {
    mask = sum (map (entry: entry.mask) parts);
    value = sum (map (entry: entry.value) parts);
  };
in {
  inherit from;

  entry = name: specs: let
    bitfield = from specs;
  in
    lib.optionalAttrs (bitfield.mask != 0) {
      ${name} = bitfield;
    };

  entries = fields:
    filterAttrs (_: bitfield: bitfield.mask != 0)
    (builtins.mapAttrs (_: specs: from specs) fields);
}
