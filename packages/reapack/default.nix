{
  lib,
  llvmPackages,
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

  NIX_CFLAGS_COMPILE =
    lib.optionalString
    stdenv.hostPlatform.isDarwin "-Wno-deprecated-declarations";

  nativeBuildInputs =
    [
      cmake
      git
      php
      ruby
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      llvmPackages.llvm
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

  cmakeFlags =
    [
      "-Wno-dev"
      # Upstream requires C++17; newer compiler defaults enable C++20 lambda
      # deprecation warnings that its -Werror turns into build failures.
      "-DCMAKE_CXX_STANDARD=17"
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      "-DCMAKE_C_COMPILER_AR=${llvmPackages.llvm}/bin/llvm-ar"
      "-DCMAKE_CXX_COMPILER_AR=${llvmPackages.llvm}/bin/llvm-ar"
      "-DCMAKE_C_COMPILER_RANLIB=${llvmPackages.llvm}/bin/llvm-ranlib"
      "-DCMAKE_CXX_COMPILER_RANLIB=${llvmPackages.llvm}/bin/llvm-ranlib"
    ];

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
