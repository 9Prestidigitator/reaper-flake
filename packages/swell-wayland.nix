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
  xorg-server,
}:
stdenv.mkDerivation {
  pname = "swell-wayland";
  version = "0.3";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = "a3ebc5d75a50cee6908f7c0b24afe726b23412fa";
    hash = "sha256-z+rMPIXXmAnihvIn0haqN13XkgogU+LDdzuYhw8YZoo=";
  };

  sourceRoot = "source/WDL/swell";

  postPatch = ''
    substituteInPlace xwayland-bridge-wm.cpp \
      --replace-fail "/usr/bin/Xvfb" "${xorg-server}/bin/Xvfb"
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
