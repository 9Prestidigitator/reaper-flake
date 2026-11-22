{
  lib,
  stdenv,
  wdlSource,
  pkg-config,
  cairo,
  fontconfig,
  glib,
  libGL,
  libdrm,
  libepoxy,
  gtk3,
  libX11,
  libdecor,
  libxkbcommon,
  libxcb,
  wayland,
  wayland-protocols,
  wayland-scanner,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  xwayland,
}:
stdenv.mkDerivation {
  pname = "swell-wayland";
  version = "unstable-${lib.substring 0 8 wdlSource.lastModifiedDate}-${wdlSource.shortRev}";

  # GitHub's PR test merge, pinned and hashed by flake.lock.
  src = wdlSource;

  postPatch = ''
    substituteInPlace WDL/swell/swell-xwayland-bridge.cpp \
      --replace-fail '"Xwayland", socket_path.name' '"${xwayland}/bin/Xwayland", socket_path.name'
  '';

  nativeBuildInputs = [pkg-config wayland-scanner];
  buildInputs = [
    cairo
    fontconfig
    glib
    libGL
    libdrm
    libepoxy
    libxcb
    libX11
    libdecor
    libxkbcommon
    gtk3
    wayland
    wayland-protocols
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
  ];

  makeFlags = [
    "-C"
    "WDL/swell"
    "WAYLAND=1"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp WDL/swell/libSwell.so $out/lib/
    runHook postInstall
  '';

  meta = {
    description = "Experimental native-Wayland SWELL library for REAPER";
    homepage = "https://github.com/justinfrankel/WDL";
    changelog = "https://github.com/justinfrankel/WDL/pull/40";
    platforms = lib.platforms.linux;
  };
}
