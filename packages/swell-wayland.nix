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
  version = "0.6";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = "2512c9e84ed402fa6e4be2f22576b3f3492f30d7";
    hash = "sha256-989Ov1omA4gnkIAxSVy8RdtfBzIiM2MNFBkFiDZsOE8=";
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
