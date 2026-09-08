{
  pkgs,
  reaperFlake,
  ...
}: {
  programs.reaper = {
    extensions = {
      reapack = {
        enable = true;
        addDefaultRepositories = true;

        # A focused example of declarative ReaPack package management. The
        # mouse-editing ramp tool is broadly useful for MIDI CC and velocity
        # work without pulling in an entire workflow bundle.
        packages = [
          {
            repository = "ReaTeam Scripts";
            category = "MIDI Editor";
            name = "js_Mouse editing - Draw ramp.lua";
          }
        ];

        # Synchronize the community indexes, but let users choose packages for
        # their own workflow instead of installing every new script implicitly.
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

        # A compact, colorblind-friendly starting palette for manual track and
        # item coloring. Declarative auto-color rules are not supported yet.
        colors = [
          "#56B4E9"
          "#E69F00"
          "#009E73"
          "#CC79A7"
          "#0072B2"
          "#D55E00"
          "#F0E442"
          "#999999"
        ];
      };
    };

    theme = {
      active = "Reapertips Theme.ReaperThemeZip";
      colorThemes = [];
      packages = [
        reaperFlake.packages.${pkgs.system}.reapertips-theme
      ];
    };

    # Linux only; harmless in a shared configuration used on macOS.
    swell.colortheme = {
      enable = true;
      preset = reaperFlake.packages.${pkgs.system}.reapertips-theme;
    };
  };
}
