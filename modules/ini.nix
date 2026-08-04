{
  config,
  lib,
  pkgs,
  reaperCodecs,
  reaperLib,
  ...
}: let
  inherit (lib) concatLists concatMapStringsSep filter filterAttrs imap0 intersectLists listToAttrs mapAttrs mkMerge mkOption nameValuePair types unique;
  cfg = config.programs.reaper;

  # Normalized contribution records are the source of truth shared by the
  # forward INI writer and reaper2nix's reverse schema.
  contributionType = types.submodule {
    options = {
      kind = mkOption {
        type = types.enum ["value" "bitfield"];
        description = "Contribution kind.";
      };
      file = mkOption {
        type = types.str;
        default = "reaper.ini";
        description = "Mutable INI file receiving this contribution.";
      };
      section = mkOption {
        type = types.str;
        description = "INI section receiving this contribution.";
      };
      key = mkOption {
        type = types.str;
        description = "INI key receiving this contribution.";
      };
      value = mkOption {
        type = types.anything;
        default = null;
        description = "Public option value encoded by this contribution's codec.";
      };
      configured = mkOption {
        type = types.bool;
        default = true;
        description = "Whether this mapping currently contributes a managed value.";
      };
      mask = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Managed bit mask for a bitfield contribution.";
      };
      optionPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Public Nix option that produced this contribution.";
      };
      gui = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "REAPER GUI label associated with this contribution.";
      };
      valueType = mkOption {
        type = types.nullOr (types.enum ["assignments" "bool" "enum" "integer" "float" "list" "string"]);
        default = null;
        description = "Nix value type expected by the importer.";
      };
      trueValue = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        internal = true;
        description = "Encoded bitfield value corresponding to true.";
      };
      falseValue = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        internal = true;
        description = "Encoded bitfield value corresponding to false.";
      };
      importValues = mkOption {
        type = types.nullOr (types.attrsOf types.ints.unsigned);
        default = null;
        internal = true;
        description = "Reverse enum mapping used by the INI importer.";
      };
      importAssignments = mkOption {
        type = types.nullOr types.attrs;
        default = null;
        internal = true;
        description = "Reverse composite bitfield assignments used by the INI importer.";
      };
      ignoredValues = mkOption {
        type = types.listOf types.ints.unsigned;
        default = [];
        internal = true;
        description = "Encoded bitfield values that mean the public option remains unset.";
      };
      codec = mkOption {
        type = types.anything;
        default = "identity";
        internal = true;
        description = "Named codec used to encode this contribution.";
      };
    };
  };

  contributions = cfg.ini.contributions;
  valueContributions = filter (contribution: contribution.kind == "value" && contribution.configured) contributions;

  addValue = result: contribution:
    if contribution.file == "reaper.ini"
    then
      result
      // {
        ${contribution.section} =
          (result.${contribution.section} or {})
          // {
            ${contribution.key} = reaperCodecs.encode contribution.codec contribution.value;
          };
      }
    else result;

  addFileValue = result: contribution:
    if contribution.file == "reaper.ini"
    then result
    else
      result
      // {
        ${contribution.file} =
          (result.${contribution.file} or {})
          // {
            ${contribution.section} =
              (result.${contribution.file}.${contribution.section} or {})
              // {
                ${contribution.key} = reaperCodecs.encode contribution.codec contribution.value;
              };
          };
      };

  bitfieldMappings = filter (contribution: contribution.kind == "bitfield") contributions;
  bitfieldContributions = filter (contribution: contribution.kind == "bitfield" && contribution.configured) contributions;

  groupBitfieldContributions = contributions:
    builtins.foldl'
    (
      result: contribution: let
        file = contribution.file;
        section = contribution.section;
        key = contribution.key;
        current = result.${file}.${section}.${key} or [];
      in
        result
        // {
          ${file} =
            (result.${file} or {})
            // {
              ${section} =
                (result.${file}.${section} or {})
                // {${key} = current ++ [contribution];};
            };
        }
    )
    {}
    contributions;

  bitfieldGroups = groupBitfieldContributions bitfieldContributions;

  reduceBitfield = entries: {
    mask = builtins.foldl' (total: entry: total + entry.mask) 0 entries;
    value = builtins.foldl' (total: entry: total + entry.value) 0 entries;
  };

  reduceBitfieldSections = sections:
    builtins.mapAttrs
    (_: entries: builtins.mapAttrs (_: entriesForKey: reduceBitfield entriesForKey) entries)
    sections;

  reducedBitfields = reduceBitfieldSections (bitfieldGroups."reaper.ini" or {});

  reducedFileBitfields =
    builtins.mapAttrs (_: reduceBitfieldSections)
    (filterAttrs (file: _: file != "reaper.ini") bitfieldGroups);

  bitfieldBitPositions = number:
    if number == 0
    then []
    else let
      half = builtins.div number 2;
      remainder = number - (half * 2);
    in
      (
        if remainder == 1
        then [0]
        else []
      )
      ++ map (position: position + 1) (bitfieldBitPositions half);

  overlappingBits = left: right:
    intersectLists (bitfieldBitPositions left) (bitfieldBitPositions right) != [];

  bitfieldContributionPairs = concatLists (
    imap0
    (index: entry: map (other: {inherit entry other;}) (lib.drop (index + 1) bitfieldMappings))
    bitfieldMappings
  );

  bitfieldConflictAssertions =
    map
    (pair: {
      assertion = false;
      message = ''
        REAPER INI bitfield conflict for ${pair.entry.file}:[${pair.entry.section}].${pair.entry.key}: masks ${toString pair.entry.mask} and ${toString pair.other.mask} overlap.
        ${pair.entry.optionPath or "First contribution"} conflicts with ${pair.other.optionPath or "Second contribution"}.
      '';
    })
    (filter (pair:
      pair.entry.file
      == pair.other.file
      && pair.entry.section == pair.other.section
      && pair.entry.key == pair.other.key
      && overlappingBits pair.entry.mask pair.other.mask)
    bitfieldContributionPairs);

  bitfieldNumberType = types.mkOptionType {
    name = "bitfield number";
    description = "an unsigned integer bitfield contribution";
    check = value: builtins.isInt value && value >= 0;
    merge = _: definitions: builtins.foldl' (total: definition: total + definition.value) 0 definitions;
  };

  # bitfield INI types:
  bitfieldType = types.submodule {
    options = {
      mask = mkOption {
        type = bitfieldNumberType;
        description = "Bit mask to update.";
      };
      value = mkOption {
        type = bitfieldNumberType;
        description = "Masked bit value to write.";
      };
    };
  };

  # Reaper uses semicolon separated lists of strings and booleans
  # are always either zero or one
  formatIniValue = value:
    if builtins.isBool value
    then
      if value
      then "1"
      else "0"
    else if builtins.isList value
    then concatMapStringsSep ";" formatIniValue value
    else toString value;

  renderPayload = sections: bitfields: removeSections:
    builtins.toJSON {
      sections = builtins.mapAttrs (_: entries: builtins.mapAttrs (_: formatIniValue) entries) sections;
      inherit bitfields;
      removeSections = removeSections;
    };

  nonEmptySections = filterAttrs (_: entries: entries != {}) cfg.ini.sections;

  nonEmptyFileSections =
    filterAttrs (_: sections: sections != {})
    (mapAttrs (_: sections: filterAttrs (_: entries: entries != {}) sections)
      cfg.ini.files);

  nonEmptyBitfieldSections = filterAttrs (_: entries: entries != {}) cfg.ini.bitfields;

  nonEmptyFileBitfieldSections =
    filterAttrs (_: sections: sections != {})
    (mapAttrs (_: sections: filterAttrs (_: entries: entries != {}) sections)
      cfg.ini.fileBitfields);

  nonEmptyFileRemovedSections = filterAttrs (_: sections: sections != []) cfg.ini.removeSections;

  emptyPayloadFile = pkgs.writeText "reaper-managed-empty.json" (renderPayload {} {} []);
  managedIniFileNames = unique (
    ["reaper.ini"]
    ++ builtins.attrNames nonEmptyFileSections
    ++ builtins.attrNames nonEmptyFileBitfieldSections
    ++ builtins.attrNames nonEmptyFileRemovedSections
  );
  schemaContributions = filter (contribution: contribution.optionPath != null) contributions;
  automaticSchemaSources = listToAttrs (map
    (file:
      nameValuePair file {
        format = "ini";
        adapter = "ini";
      })
    (unique (map (contribution: contribution.file) schemaContributions)));
  schemaSources = automaticSchemaSources // cfg.schema.sources;
  schemaFile = pkgs.writeText "reaper-managed-schema.json" (builtins.toJSON {
    version = 2;
    sources = schemaSources;
    options =
      map (contribution: {
        path = contribution.optionPath;
        kind = contribution.kind;
        file = contribution.file;
        section = contribution.section;
        key = contribution.key;
        mask = contribution.mask;
        codec = contribution.codec;
        gui = contribution.gui;
        valueType = contribution.valueType;
        trueValue = contribution.trueValue;
        falseValue = contribution.falseValue;
        importValues = contribution.importValues;
        importAssignments = contribution.importAssignments;
        ignoredValues = contribution.ignoredValues;
      })
      schemaContributions;
  });
in {
  options.programs.reaper.schema.sources = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        format = mkOption {
          type = types.enum ["ini" "json" "line"];
          description = "Physical configuration format used by this REAPER file.";
        };
        adapter = mkOption {
          type = types.str;
          description = "Importer adapter responsible for this configuration source.";
        };
        adapters = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional semantic importer adapters for this configuration source.";
        };
        adapterConfig = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          internal = true;
          description = "Adapter-specific, JSON-serializable reverse-import metadata.";
        };
      };
    });
    default = {};
    internal = true;
    description = "Curated configuration sources supported by reaper2nix.";
  };

  options.programs.reaper.ini = {
    # Modules assign `programs.reaper.ini.sections.<section>.<key> = value`
    # when the target file is `reaper.ini`.
    sections = mkOption {
      type = types.attrsOf (types.attrsOf reaperLib.reaperTypes.iniValue);
      default = {};
      internal = true;
      description = "reaper.ini sections generated by preferences modules.";
    };

    # `programs.reaper.ini.files.<file>.<section>.<key> = value` when the target
    # is another mutable ini file, such as reapack.ini.
    files = mkOption {
      type = types.attrsOf (types.attrsOf (types.attrsOf reaperLib.reaperTypes.iniValue));
      default = {};
      internal = true;
      description = "Additional mutable INI files generated by scoped REAPER modules.";
    };

    bitfields = mkOption {
      type = types.attrsOf (types.attrsOf bitfieldType);
      default = {};
      internal = true;
      description = "Bitfield updates generated for mutable `reaper.ini` keys.";
    };

    contributions = mkOption {
      type = types.listOf contributionType;
      default = [];
      internal = true;
      description = "Generic normalized preference contributions.";
    };

    fileBitfields = mkOption {
      type = types.attrsOf (types.attrsOf (types.attrsOf bitfieldType));
      default = {};
      internal = true;
      description = "Bitfield updates generated for additional mutable REAPER INI files.";
    };

    removeSections = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      internal = true;
      description = "INI sections to remove completely from additional mutable REAPER INI files.";
    };

    emptyPayloadFile = mkOption {
      type = types.path;
      internal = true;
      readOnly = true;
      description = "Empty JSON payload used for stale cleanup.";
    };

    generatedPayloadFiles = mkOption {
      type = types.attrsOf types.path;
      internal = true;
      readOnly = true;
      description = "Generated JSON payloads merged into mutable REAPER config files.";
    };

    generatedSchemaFile = mkOption {
      type = types.path;
      internal = true;
      readOnly = true;
      description = "Machine-readable schema for normalized preference contributions.";
    };

    writerPackage = mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      description = "Python INI writer used during activation.";
    };
  };
  config = mkMerge [
    {
      programs.reaper.ini.sections = builtins.foldl' addValue {} valueContributions;
      programs.reaper.ini.files = builtins.foldl' addFileValue {} valueContributions;
      programs.reaper.ini.bitfields = reducedBitfields;
      programs.reaper.ini.fileBitfields = reducedFileBitfields;
      assertions = bitfieldConflictAssertions;
    }
    {
      programs.reaper.ini = {
        emptyPayloadFile = emptyPayloadFile;

        generatedPayloadFiles = listToAttrs (map
          (fileName:
            nameValuePair fileName (let
              sections =
                if fileName == "reaper.ini"
                then nonEmptySections
                else nonEmptyFileSections.${fileName} or {};
              bitfields =
                if fileName == "reaper.ini"
                then nonEmptyBitfieldSections
                else nonEmptyFileBitfieldSections.${fileName} or {};
              removeSections =
                if fileName == "reaper.ini"
                then []
                else nonEmptyFileRemovedSections.${fileName} or [];
            in
              pkgs.writeText "reaper-managed-${fileName}.json" (renderPayload sections bitfields removeSections)))
          managedIniFileNames);

        generatedSchemaFile = schemaFile;

        writerPackage = pkgs.writeShellApplication {
          name = "write-config";
          runtimeInputs = [pkgs.python3];
          text = ''exec python3 ${../scripts/write_config.py} "$@"'';
        };
      };
    }
  ];
}
