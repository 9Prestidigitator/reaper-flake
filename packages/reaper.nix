{
  config,
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  undmg,
  alsa-lib,
  curl,
  gtk3,
  lame,
  libxml2_13,
  libjack2,
  ffmpeg_4-headless,
  vlc,
  xdg-utils,
  xdotool,
  which,
  openssl,
  jackSupport ? stdenv.hostPlatform.isLinux,
  jackLibrary ? libjack2, # Another option is "pipewire.jack"
  pulseaudioSupport ? config.pulseaudio or stdenv.hostPlatform.isLinux,
  libpulseaudio,
  pythonSupport ? false,
  python3,
  waylandSwellSupport ? false,
  swell-wayland ? null,
}:
assert waylandSwellSupport -> swell-wayland != null; let
  inherit (stdenv) hostPlatform;
  urlForPlatform = version: arch: let
    majorVersion = lib.versions.major version;
    compactVersion = builtins.replaceStrings ["."] [""] version;
    baseUrl = "https://www.reaper.fm/files/${majorVersion}.x/reaper${compactVersion}";
  in
    if hostPlatform.isDarwin
    then "${baseUrl}_universal.dmg"
    else "${baseUrl}_linux_${arch}.tar.xz";

  pythonRuntimeInputs = lib.optional pythonSupport python3;
  pythonBinPath = lib.makeBinPath pythonRuntimeInputs;
  pythonLibraryPath = lib.makeLibraryPath pythonRuntimeInputs;
  darwinPythonWrapperArgs =
    lib.optionalString pythonSupport
    "--prefix PATH : ${lib.escapeShellArg pythonBinPath} --prefix DYLD_LIBRARY_PATH : ${lib.escapeShellArg pythonLibraryPath}";

  wrapperPath = [xdg-utils] ++ pythonRuntimeInputs;
  wrapperLibraryPath =
    [
      curl
      lame
      libxml2_13
      ffmpeg_4-headless
      vlc
      xdotool
      stdenv.cc.cc
      openssl
    ]
    ++ pythonRuntimeInputs;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "reaper";
    version = "7.76";

    src = fetchurl {
      url = urlForPlatform finalAttrs.version stdenv.hostPlatform.qemuArch;
      hash =
        if hostPlatform.isDarwin
        then "sha256-7lGMSRXawS8/ISCPLjUlQmxqW/pQy3iWviM+2fZ6LSc="
        else
          {
            x86_64-linux = "sha256-P13PaZjGnA3bLpz9latebVJAdL6ZF+UVtX94mKmq/xg=";
            aarch64-linux = "sha256-dVloxbTYK3wPSFpIs/UD6ons1ePY7tpTMI7WoSngaVs=";
          }
        .${
            hostPlatform.system
          };
    };

    nativeBuildInputs =
      [
        makeWrapper
      ]
      ++ lib.optionals hostPlatform.isLinux [
        which
        autoPatchelfHook
        xdg-utils # Required for install script
      ]
      ++ lib.optionals hostPlatform.isDarwin [
        undmg
      ];

    sourceRoot = lib.optionalString stdenv.hostPlatform.isDarwin "Reaper.app";

    buildInputs =
      [
        (lib.getLib stdenv.cc.cc) # reaper and libSwell need libstdc++.so.6
      ]
      ++ lib.optionals hostPlatform.isLinux [
        gtk3
        alsa-lib
      ];

    runtimeDependencies =
      lib.optionals hostPlatform.isLinux [
        gtk3 # libSwell needs libgdk-3.so.0
      ]
      ++ lib.optional jackSupport jackLibrary
      ++ lib.optional pulseaudioSupport libpulseaudio;

    dontBuild = true;
    dontStrip = true;

    installPhase =
      if hostPlatform.isDarwin
      then ''
        runHook preInstall
        mkdir -p "$out/Applications/Reaper.app"
        cp -r * "$out/Applications/Reaper.app/"
        makeWrapper "$out/Applications/Reaper.app/Contents/MacOS/REAPER" "$out/bin/reaper" ${darwinPythonWrapperArgs}
        runHook postInstall
      ''
      else ''
        runHook preInstall

        HOME="$out/share" XDG_DATA_HOME="$out/share" ./install-reaper.sh \
          --install $out/opt \
          --integrate-user-desktop
        rm $out/opt/REAPER/uninstall-reaper.sh

        ${lib.optionalString waylandSwellSupport ''
          rm -f $out/opt/REAPER/libSwell.so
          ln -s ${swell-wayland}/lib/libSwell.so $out/opt/REAPER/libSwell.so
        ''}

        # Dynamic loading of plugin dependencies does not adhere to rpath of
        # reaper executable that gets modified with runtimeDependencies.
        # Patching each plugin with DT_NEEDED is cumbersome and requires
        # hardcoding of API versions of each dependency.
        # Setting the rpath of the plugin shared object files does not
        # seem to have an effect for some plugins.
        # We opt for wrapping the executable with LD_LIBRARY_PATH prefix.
        # Note that libcurl and libxml2_13 are needed for ReaPack to run.
        wrapProgram $out/opt/REAPER/reaper \
          --prefix PATH : "${lib.makeBinPath wrapperPath}" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath wrapperLibraryPath}"

        mkdir $out/bin
        ln -s $out/opt/REAPER/reaper $out/bin/

        # Avoid store path in Exec, since we already link to $out/bin
        substituteInPlace $out/share/applications/cockos-reaper.desktop \
          --replace-fail "Exec=\"$out/opt/REAPER/reaper\"" "Exec=reaper"

        runHook postInstall
      '';

    passthru.updateScript = ./updater.sh;

    meta = {
      description = "Digital audio workstation";
      homepage = "https://www.reaper.fm/";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.unfree;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      maintainers = with lib.maintainers; [
        ilian
        viraptor
        pancaek
      ];
    };
  })
