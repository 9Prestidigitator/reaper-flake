{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  fontconfig,
  libGL,
  gtk3,
  libX11,
  libXcomposite,
  libXfixes,
  libXtst,
  xwayland,
}:
stdenv.mkDerivation rec {
  pname = "swell-wayland";
  version = "0.6.6";

  src = fetchFromGitHub {
    owner = "GoranKovac";
    repo = "WDL";
    rev = version;
    hash = "sha256-OrRwmf06ptdXUFFs2G5F3uUzoTyF67GP0QmxeBA1oYo=";
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
    libXcomposite
    libXfixes
    libXtst
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
