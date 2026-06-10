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
    rev = "4c139ab9982ed358950d632568bb5758f649c5d7";
    sha256 = "sha256-4W6YVNnQrIg/LuiKif9W0DcV4xVZFdLEa1p80xXY5RU=";
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
