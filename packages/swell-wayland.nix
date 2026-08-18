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
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = "95b4de72e1462e5bc10d32f69d3a9e99653651bd";
    hash = "sha256-TGtxrIf3dRQ8gNFHiln6wUw7pcWWRm6kwjetAGClkEg=";
  };

  sourceRoot = "source/WDL/swell";

  # temporary fix since 7.79 requires `MoveFile` which is not in 0.6.1
  patches = [./swell-wayland-move-file.patch];

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
