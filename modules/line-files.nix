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
    emptyFile = mkOption {
      type = types.path;
      internal = true;
      readOnly = true;
      description = "Empty generated line fragment used for stale cleanup.";
    };
  };

  config.programs.reaper.lineFiles = {
    emptyFile = pkgs.writeText "reaper-managed-empty-lines" "";
    generatedFiles =
      mapAttrs
      (fileName: lines: pkgs.writeText "reaper-managed-${fileName}" (concatStringsSep "\n" lines + "\n"))
      (filterAttrs (_: lines: lines != []) cfg.lineFiles.files);
  };
}
