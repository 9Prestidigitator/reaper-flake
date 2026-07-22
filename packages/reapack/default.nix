{
  lib,
  boost,
  catch2_3,
  cmake,
  curl,
  fetchFromGitea,
  git,
  libxml2,
  openssl,
  php,
  ruby,
  sqlite,
  stdenv,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "reaper-reapack-extension";
  version = "1.2.6";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "cfillion";
    repo = "reapack";
    tag = "v${finalAttrs.version}";
    hash = "sha256-M1EUBksCCcGD6zRT0Kr32t+inyKMieGR/y+KGxt/qrc=";
    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    git
    php
    ruby
  ];

  buildInputs = [
    boost
    catch2_3
    curl
    libxml2
    openssl
    sqlite
    zlib
  ];

  cmakeFlags = ["-Wno-dev"];

  # Building from source on every platform ensures the managed-package API is
  # present in both the Linux shared object and the macOS dylib.
  patches = [./managed-packages-api.patch];

  meta = {
    description = "Package manager for REAPER";
    homepage = "https://codeberg.org/cfillion/reapack";
    changelog = "https://codeberg.org/cfillion/reapack/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      lgpl3Plus
      gpl3Plus
    ];
    maintainers = with lib.maintainers; [pancaek];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
