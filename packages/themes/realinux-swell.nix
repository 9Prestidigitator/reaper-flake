{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  variant,
}:
assert lib.assertOneOf "variant" variant ["dark" "light"];
  stdenvNoCC.mkDerivation {
    pname = "realinux-${variant}-swell-theme";
    version = "2022-02-22";

    src = fetchurl {
      url = "https://stash.reaper.fm/43867/ReaLinuxThemes.zip";
      hash = "sha256-UR1X6e3OrTFUiOb8q4Vp3RBlcse/ZeekWwLxQkcZgtk=";
    };

    sourceRoot = ".";
    nativeBuildInputs = [unzip];

    dontBuild = true;

    passthru.reaperSwellColorTheme = "libSwell-user.colortheme";

    installPhase = ''
      runHook preInstall

      install -Dm0644 "libSwell.colortheme.${variant}" \
        "$out/share/reaper/libSwell-user.colortheme"

      runHook postInstall
    '';

    meta = {
      description = "ReaLinux ${variant} SWELL color theme for REAPER on Linux";
      homepage = "https://stash.reaper.fm/theme/2802/ReaLinuxThemes.zip";
      platforms = lib.platforms.linux;
    };
  }
