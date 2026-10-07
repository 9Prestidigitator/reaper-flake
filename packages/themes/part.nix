{
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation {
  pname = "part-theme";
  version = "1.3.2";

  src = fetchzip {
    url = "https://github.com/Fleeesch/paRt/releases/download/v1.3.2/part_manual_install_v1.3.2.zip";
    hash = "sha256-czNBXS2Y2zg3wC7RSbcD+ujL9BpkOshgoXxCWFKaLg0=";
    stripRoot = false;
  };

  sourceRoot = "source";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/reaper"
    cp -R ColorThemes Data Scripts "$out/share/reaper/"

    runHook postInstall
  '';
}
