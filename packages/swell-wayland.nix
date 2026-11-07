{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  cairo,
  fontconfig,
  glib,
  libGL,
  libdrm,
  libepoxy,
  gtk3,
  libX11,
  libXcomposite,
  libXfixes,
  libXtst,
  libxcb,
  wayland,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  xwayland,
}:
stdenv.mkDerivation rec {
  pname = "swell-wayland";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = version;
    hash = "sha256-9sA3gRcSSMBzYa1fmPOnUf4Xf6p1KuGtBIZp20AZ+EM=";
  };

  sourceRoot = "source/WDL/swell";

  postPatch = ''
    substituteInPlace swell-xwayland-bridge.cpp \
      --replace-fail "/usr/bin/Xwayland" "${xwayland}/bin/Xwayland"
    substituteInPlace Makefile \
      --replace-fail "gtk+-3.0)" "gtk+-3.0 gio-unix-2.0)"
  '';

  nativeBuildInputs = [pkg-config];
  buildInputs = [
    cairo
    fontconfig
    glib
    libGL
    libdrm
    libepoxy
    libxcb
    libX11
    libXcomposite
    libXfixes
    libXtst
    gtk3
    wayland
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
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

  meta = {
    description = "Experimental native-Wayland SWELL library for REAPER";
    homepage = "https://github.com/GoranKovac/WDL";
    changelog = "https://github.com/GoranKovac/WDL/releases/tag/${version}";
    platforms = lib.platforms.linux;
  };
}
