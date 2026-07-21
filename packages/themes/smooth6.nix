{
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation {
  pname = "smooth6-theme";
  version = "2.1";

  src = fetchzip {
    url = "https://dl.dropboxusercontent.com/s/7eqaousbr0fnkfx/Smooth%206%20V2.1.zip";
    hash = "sha256-7+QosEyoBEJIbhHLl1CzGRnKK27vgauJFSPMBz4GEQY=";
    stripRoot = false;
  };

  sourceRoot = "source";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/reaper/ColorThemes" "$out/share/reaper/Scripts" "$out/share/fonts/opentype"

    install -m 0644 "Smooth 6 V2.1/3-Theme"/*.ReaperThemeZip "Smooth 6 V2.1/3-Theme"/*.ReaperTheme -t "$out/share/reaper/ColorThemes"
    install -m 0644 "Smooth 6 V2.1/2-Theme Adjuster"/*.lua -t "$out/share/reaper/Scripts"
    install -m 0644 "Smooth 6 V2.1/1-Fonts/Mac"/*.otf -t "$out/share/fonts/opentype"

    runHook postInstall
  '';
}
