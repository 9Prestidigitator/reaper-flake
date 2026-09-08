{
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation {
  pname = "reark-theme";
  version = "6.73b";

  src = fetchzip {
    url = "https://arkadata.com/wp-content/uploads/2023/01/reARK-v6.73b.zip";
    hash = "sha256-uA5EuWzk8FVcQy4sceY4TbPV/qDl8InCNV7XbvT3hx8=";
    stripRoot = false;
  };

  sourceRoot = "source";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/reaper/ColorThemes"
    install -m 0644 *.ReaperThemeZip -t "$out/share/reaper/ColorThemes"

    runHook postInstall
  '';
}
