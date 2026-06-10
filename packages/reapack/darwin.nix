{
  stdenvNoCC,
  fetchurl,
  pname,
  version,
  meta,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit
    pname
    version
    meta
    ;
  src = fetchurl {
    url = let
      arch =
        if stdenvNoCC.hostPlatform.system == "x86_64-darwin"
        then "x86_64"
        else "arm64";
    in "https://github.com/cfillion/reapack/releases/download/v${finalAttrs.version}/reaper_reapack-${arch}.dylib";
    hash =
      {
        x86_64-darwin = "sha256-SLJhl042ZxOEypAqOz1aYUF49Asb63wTjHQUEOpdfZ4=";
        aarch64-darwin = "sha256-x2cPOy5AW5A31JsZQaTYw3Yv/zJs7MDFisT67KFx8Hs=";
      }
      .${
        stdenvNoCC.hostPlatform.system
      };
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -D * -t $out/UserPlugins
    runHook postInstall
  '';
})
