{
  stdenvNoCC,
  fetchurl,
}: let
  mainTheme = fetchurl {
    url = "https://www.extremraym.com/en/file/x-raym-analog/";
    hash = "sha256-hydDmZz09fdfMFKeLqzbZUeg1yumL5qI4HH0NtiMPfk=";
  };

  darkTheme = fetchurl {
    # The download endpoint currently serves Analog Dark v1.0.7.
    url = "https://www.extremraym.com/en/file/x-raym-analog-dark-v1-0/";
    hash = "sha256-582zbNMHA6RoRhNwQycK1Bhud8S7V5I7uML7xonvnLg=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "xraym-analog-theme";
    version = "2.5.7";

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dm0644 ${mainTheme} "$out/share/reaper/ColorThemes/X-Raym_Analog.ReaperThemeZip"
      install -Dm0644 ${darkTheme} "$out/share/reaper/ColorThemes/X-Raym_Analog_Dark.ReaperTheme"

      runHook postInstall
    '';
  }
