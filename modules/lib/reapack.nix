let
  defaultRepository = name: url: {
    inherit name url;
    enable = true;
    installNewPackages = "global";
  };
in {
  defaultRepositories = [
    (defaultRepository "ReaPack" "https://reapack.com/index.xml")
    (defaultRepository "ReaTeam Scripts" "https://github.com/ReaTeam/ReaScripts/raw/master/index.xml")
    (defaultRepository "ReaTeam JSFX" "https://github.com/ReaTeam/JSFX/raw/master/index.xml")
    (defaultRepository "ReaTeam Themes" "https://github.com/ReaTeam/Themes/raw/master/index.xml")
    (defaultRepository "ReaTeam LangPacks" "https://github.com/ReaTeam/LangPacks/raw/master/index.xml")
    (defaultRepository "ReaTeam Extensions" "https://github.com/ReaTeam/Extensions/raw/master/index.xml")
    (defaultRepository "MPL Scripts" "https://github.com/MichaelPilyavskiy/ReaScripts/raw/master/index.xml")
    (defaultRepository "X-Raym Scripts" "https://github.com/X-Raym/REAPER-ReaScripts/raw/master/index.xml")
  ];

  autoInstallValues = {
    manual = 0;
    always = 1;
    global = 2;
  };

  fallbackProxyValues = {
    disable = 0;
    enable = 1;
    ask = 2;
  };
}
