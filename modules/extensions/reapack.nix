{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption literalExpression types mkEnableOption;
in {
  options.programs.reaper.extensions.reapack = {
    enable = mkEnableOption "Enable the ReaPack extension in the config.";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../../packages/reapack {};
      defaultText = literalExpression "inputs.reaper-flake.packages.${pkgs.system}.reapack";
      description = "Package that provides ReaPack files under `UserPlugins`.";
    };
  };
}
