{
  config,
  lib,
  reaperLib,
  reaperPlugins,
  ...
}: let
  inherit (lib) mkOption optionals types unique;
  inherit (reaperLib) reaperPreference;
in {
  imports = [
    ./Compatibility.nix
    ./vst.nix
    ./lv2Clap.nix
    ./ara.nix
    ./ReaScript.nix
  ];
  options.programs.reaper.preferences.plugIns = {
    automaticallyResizeFxWindow = mkOption {
    };
    autoFloatUiForFxCreatedViaFxBrowser = mkOption {
    };
  };
}
