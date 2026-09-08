{
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation {
  pname = "imperial-theme";
  version = "2012-12-01";

  src = fetchurl {
    url = "https://www.houseofwhitetie.com/reaper/imperial/WT_Imperial.ReaperThemeZip";
    hash = "sha256-nqH6Rqenu5UM5e5oxzD+J9FJEBgmGSwF/8YE1J3s4+E=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm0644 "$src" "$out/share/reaper/ColorThemes/WT_Imperial.ReaperThemeZip"

    runHook postInstall
  '';
}
