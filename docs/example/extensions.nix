{
  pkgs,
  reaperFlake,
  ...
}: {
  programs.reaper = {
    extensions = {
      reapack = {
        enable = true;

        repositories = [
          {
            name = "ReaTeam Scripts";
            url = "https://github.com/ReaTeam/ReaScripts/raw/master/index.xml";
            installNewPackages = "always";
          }
          {
            name = "ReaTeam Extensions";
            url = "https://github.com/ReaTeam/Extensions/raw/master/index.xml";
          }
        ];

        packages = [
          {
            repository = "ReaTeam Scripts";
            category = "MIDI Editor";
            name = "js_Mouse editing - Draw ramp.lua";
          }
        ];

        installNewPackagesWhenSynchronizing = false;
        enablePrereleasesGlobally = false;
        promptToUninstallObsoletePackages = true;
        browser.expandSynonyms = true;

        network = {
          verifyPeer = true;
          refreshIndexCacheAfterSeconds = 86400;
          fallbackProxy = "ask";
        };

        synchronizeOnActivation = true;
      };

      sws = {
        enable = true;
        # `null` leaves the palette unmanaged; `[]` clears all 16 slots.
        colors = [
          "#F5E0E6"
          "#F2CDCD"
          "#F5C2E7"
          "#CBA6F7"
        ];
      };
    };

    theme = {
      active = "Smooth_6.ReaperThemeZip";
      colorThemes = [];
      packages = [
        reaperFlake.packages.${pkgs.system}.smooth6-theme
        reaperFlake.packages.${pkgs.system}.reapertips-theme
      ];
    };

    # Linux only; harmless in a shared configuration used on macOS.
    swell.colortheme = {
      enable = true;
      preset = reaperFlake.packages.${pkgs.system}.reapertips-theme;
    };

    # Nix and conventional user plug-in paths are appended by default.
    preferences.plugIns = {
      reascript.python.enable = true;
      vst.searchPaths = ["~/Documents/VSTs"];
      clap.searchPaths = ["~/Documents/CLAP"];
      lv2 = {
        searchPaths = ["~/.lv2-experimental"];
        enableNixPaths = false;
        enableUserPaths = false;
      };
    };
  };
}
