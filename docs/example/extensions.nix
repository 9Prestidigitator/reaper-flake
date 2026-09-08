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

        # Additional community repositories beyond the built-in ReaTeam, MPL,
        # and X-Raym indexes. Keep bulk auto-install disabled: each repository
        # represents a substantial, workflow-specific ecosystem.
        repositories = [
          {
            name = "BirdBird ReaScript Testing";
            url = "https://raw.githubusercontent.com/Bird-Bird/ReaScript_Testing/main/index.xml";
            installNewPackages = "manual";
          }
          {
            name = "Helgoboss Projects";
            url = "https://raw.githubusercontent.com/helgoboss/reaper-packages/master/index.xml";
            installNewPackages = "manual";
          }
          {
            name = "Reaticulate";
            url = "https://reaticulate.com/index.xml";
            installNewPackages = "manual";
          }
          {
            name = "Tukan";
            url = "https://raw.githubusercontent.com/TukanStudios/TUKAN_STUDIOS_PLUGINS/main/index2.xml";
            installNewPackages = "manual";
          }
        ];

        # A curated set of small, established tools for everyday editing,
        # navigation, MIDI programming, composition, and rendering.
        packages = [
          {
            repository = "ReaTeam Extensions";
            category = "API";
            name = "js_ReaScriptAPI.ext";
          }
          {
            repository = "BirdBird ReaScript Testing";
            category = "Global Sampler";
            name = "BirdBird_Global Sampler.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "Items Editing";
            name = "amagalma_Smart Crossfade.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "MIDI Editor";
            name = "js_Mouse editing - Draw ramp.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "MIDI Editor";
            name = "js_Mouse editing - Multi tool.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "MIDI Editor";
            name = "js_LFO Tool (MIDI editor version, insert CCs in time selection in lane under mouse).lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "Rendering";
            name = "cfillion_Apply render preset.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "Various";
            name = "amagalma_Smart contextual zoom.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "Various";
            name = "pandabot_ChordGun.lua";
          }
          {
            repository = "ReaTeam Scripts";
            category = "Various";
            name = "rodilab_Smart select all (depending on focus, tracks selected and time selection).lua";
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
