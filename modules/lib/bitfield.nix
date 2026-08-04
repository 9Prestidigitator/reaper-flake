{lib}: let
  inherit (lib) concatLists;

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
    inherit falseValue trueValue value;
  };

  from = specs: let
    parts = map part specs;
  in {
    mask = sum (map (entry: entry.mask) parts);
    value = sum (map (entry: entry.value) parts);
  };

  contribution = key: spec: let
    bitfield = part spec;
    declaredMask =
      if spec ? mask
      then spec.mask
      else spec.bit;
    valueType =
      if spec ? valueType
      then spec.valueType
      else if spec ? importAssignments
      then "assignments"
      else if spec ? importValues
      then "enum"
      else if spec ? bit || spec ? trueValue || spec ? falseValue
      then "bool"
      else "integer";
  in [
    (
      {
        kind = "bitfield";
        inherit key;
        configured = bitfield.mask != 0;
        mask = declaredMask;
        value = bitfield.value;
        falseValue = bitfield.falseValue;
        trueValue = bitfield.trueValue;
        inherit valueType;
      }
      // lib.optionalAttrs (spec ? optionPath) {inherit (spec) optionPath;}
      // lib.optionalAttrs (spec ? gui) {inherit (spec) gui;}
      // lib.optionalAttrs (spec ? importValues) {inherit (spec) importValues;}
      // lib.optionalAttrs (spec ? importAssignments) {inherit (spec) importAssignments;}
      // lib.optionalAttrs (spec ? ignoredValues) {inherit (spec) ignoredValues;}
    )
  ];
in {
  entry = name: specs: let
    bitfield = from specs;
  in
    lib.optionalAttrs (bitfield.mask != 0) {
      ${name} = bitfield;
    };

  contributions = fields:
    concatLists (lib.mapAttrsToList (key: specs: concatLists (map (contribution key) specs)) fields);
}
