{
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation {
  pname = "part-theme";
  version = "1.3.2";

  src = fetchzip {
    url = "https://github.com/Fleeesch/paRt/releases/download/v1.3.2/part_manual_install_v1.3.2.zip";
    hash = "sha256-W/VYoG9SyMlTe7v9qPOZh+j16PTkJTaXhyz+vy2dykY=";
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
