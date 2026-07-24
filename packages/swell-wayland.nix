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
  version = "0.1";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = "0.1";
    hash = "sha256-7Tq7AbbKXTPMujEu/iHv2UeA7qDWcvp5S5prfDjBAEQ=";
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

  makeFlags = [
    "SWELL_SUPPORT_GTK=1"
    "WAYLAND=1"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp libSwell.so $out/lib/
    runHook postInstall
  '';

  meta.platforms = lib.platforms.linux;
}
