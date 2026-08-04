{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mkOption types mapAttrs filterAttrs;
  cfg = config.programs.reaper;
in {
  options.programs.reaper.lineFiles = {
    files = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      internal = true;
      description = "Line-oriented REAPER files managed additively with previous-generation cleanup.";
    };
    generatedFiles = mkOption {
      type = types.attrsOf types.path;
      internal = true;
      readOnly = true;
      description = "Generated line-oriented REAPER config fragments.";
    };
  };

  config.programs.reaper.lineFiles = {
    generatedFiles =
      mapAttrs
      (fileName: lines: pkgs.writeText "reaper-managed-${fileName}" (concatStringsSep "\n" lines + "\n"))
      (filterAttrs (_: lines: lines != []) cfg.lineFiles.files);
  };
}
