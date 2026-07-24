{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  fontconfig,
  libGL,
  gtk3,
  libX11,
  libXtst,
  libXcomposite,
}:
stdenv.mkDerivation {
  pname = "swell-wayland";
  version = "1.1.0w";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = "96b770f7368f75b53756e0c8941ce3ecc8b6c29b";
    sha256 = "sha256-P9rLgnetRk7KAnXH2s+0CMcnjAIibncVPI3S7D0On+g=";
  };

  sourceRoot = "source/WDL/swell";

  nativeBuildInputs = [pkg-config];
  buildInputs = [
    gtk3
    fontconfig
    libGL
    libX11
    libXtst
    libXcomposite
  ];

  makeFlags = ["SWELL_SUPPORT_GTK=1"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp libSwell.so $out/lib/
    runHook postInstall
  '';

  meta.platforms = lib.platforms.linux;
}
