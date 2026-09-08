{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "reaclassical-theme";
  version = "26.8.1";

  src = fetchFromGitHub {
    owner = "chmaha";
    repo = "ReaClassical";
    rev = "48bd6aac87e2c4109fcfdc0faa5a9a1251d4b269";
    hash = "sha256-7Lp+Hd6z4ENKZOmEJuElxgZPcwnyxzQpXpFbvRmAXck=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/reaper/ColorThemes" "$out/share/doc/reaclassical-theme"
    install -m 0644 ReaClassical/ReaClassical*.ReaperThemeZip -t "$out/share/reaper/ColorThemes"
    install -m 0644 LICENSE "$out/share/doc/reaclassical-theme/LICENSE"

    runHook postInstall
  '';

  meta.license = lib.licenses.gpl3Only;
}
