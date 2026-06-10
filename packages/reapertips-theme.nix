{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "reapertips-theme";
  version = "1.90";

  src = fetchFromGitHub {
    owner = "mrtnvgr";
    repo = "reapertips-theme";
    rev = "4bed52d9e8284ee057cc2311c1872c999a267523";
    sha256 = "sha256-rOXINkPbBqlQL/10mhdI1FhJOp0lINAREN5oo4BjB8M=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/reaper/ColorThemes" "$out/share/reaper" "$out/share/fonts/truetype"

    find "02_Theme" -name '*.ReaperThemeZip' -exec install -m 0644 -t "$out/share/reaper/ColorThemes" {} +
    install -m 0644 "03_Extras/Linux Colortheme/libSwell-user.colortheme" "$out/share/reaper/libSwell-user.colortheme"
    install -m 0644 "01_Install these fonts"/*.ttf "$out/share/fonts/truetype"

    runHook postInstall
  '';
}
