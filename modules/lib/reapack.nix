{
  defaultRepositories = [
    {
      name = "ReaPack";
      url = "https://reapack.com/index.xml";
    }
    {
      name = "ReaTeam Scripts";
      url = "https://github.com/ReaTeam/ReaScripts/raw/master/index.xml";
    }
    {
      name = "ReaTeam JSFX";
      url = "https://github.com/ReaTeam/JSFX/raw/master/index.xml";
    }
    {
      name = "ReaTeam Themes";
      url = "https://github.com/ReaTeam/Themes/raw/master/index.xml";
    }
    {
      name = "ReaTeam LangPacks";
      url = "https://github.com/ReaTeam/LangPacks/raw/master/index.xml";
    }
    {
      name = "ReaTeam Extensions";
      url = "https://github.com/ReaTeam/Extensions/raw/master/index.xml";
    }
    {
      name = "MPL Scripts";
      url = "https://github.com/MichaelPilyavskiy/ReaScripts/raw/master/index.xml";
    }
    {
      name = "X-Raym Scripts";
      url = "https://github.com/X-Raym/REAPER-ReaScripts/raw/master/index.xml";
    }
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
