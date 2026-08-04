{pkgs, ...}: {
  imports = [
    ./Compatibility.nix
    ./vst.nix
    ./lv2Clap.nix
    ./ara.nix
    ./ReaScript.nix
  ];

  config.programs.reaper.schema.sources."reaper.ini" = {
    adapters = ["plugin-paths"];
    adapterConfig.pluginPathKeys = {
      vst = "vstpath";
      lv2 = "lv2path_linux";
      clap = "clap_path_linux-${pkgs.stdenv.hostPlatform.qemuArch}";
    };
  };
}
