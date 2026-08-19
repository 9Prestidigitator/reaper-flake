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
  xwayland,
}:
stdenv.mkDerivation {
  pname = "swell-wayland";
  version = "0.6.2-beta";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = "667723a2c1d527644e050104837a541fc2334550";
    hash = "sha256-rpjjuJwKEMO0h3FLUUWRoxseMLLsFLyMZZM3MrByD4Q=";
  };

  sourceRoot = "source/WDL/swell";

  postPatch = ''
    substituteInPlace xwayland-bridge-wm.cpp \
      --replace-fail "/usr/bin/Xwayland" "${xwayland}/bin/Xwayland"
  '';

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
