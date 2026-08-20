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
    rev = "1ddda3f7ceb4cb815a74d15a7baa393a9598761f";
    hash = "sha256-OvmM6xwwgDiwM0s+53eF4EarvSPngQ87EjTJs+l0gPM=";
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
