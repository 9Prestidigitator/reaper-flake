{
  stdenv,
  fetchFromGitHub,
  cmake,
  php,
  perl,
  git,
  pkg-config,
  gtk3,
  pname,
  version,
  meta,
}:
stdenv.mkDerivation (finalAttrs: {
  inherit pname version meta;

  src = fetchFromGitHub {
    owner = "reaper-oss";
    repo = "sws";
    tag = "v${finalAttrs.version}";
    hash = "sha256-J2igVacDClHgKGZ2WATcd5XW2FkarKtALxVLgqa90Cs=";
    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    git
    perl
    php
    pkg-config
  ];

  buildInputs = [gtk3];

  # SWS 2.14 uses aggregate initialization that is incompatible with C++20.
  # Keep the language mode stable when the compiler's default changes.
  cmakeFlags = ["-DCMAKE_CXX_STANDARD=17"];
})
