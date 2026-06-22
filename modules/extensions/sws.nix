{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption literalExpression types mkEnableOption;
in {
  options.programs.reaper.extensions.sws = {
    enable = mkEnableOption "Enable SWS Extensions in the config";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../../packages/sws {};
      defaultText = literalExpression "inputs.reaper-flake.packages.${pkgs.system}.sws";
      description = "Package that provides SWS files under `UserPlugins` and `Scripts`.";
    };
  };
}
