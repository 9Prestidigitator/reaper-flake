{
  lib,
  pkgs,
  runCommand,
}: let
  fixture = runCommand "reaper-launcher-fixture" {} ''
    mkdir -p "$out/bin" "$out/Applications/Reaper.app/Contents/MacOS" "$out/Applications/Reaper.app/Contents/Resources"
    cat > "$out/bin/reaper" <<'EOF'
    #!${pkgs.runtimeShell}
    printf '%s\n' "$@"
    EOF
    chmod +x "$out/bin/reaper"
    cp "$out/bin/reaper" "$out/Applications/Reaper.app/Contents/MacOS/REAPER"
    echo icon > "$out/Applications/Reaper.app/Contents/Resources/main.icns"
    cat > "$out/Applications/Reaper.app/Contents/Info.plist" <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <plist version="1.0"><dict>
    <key>CFBundleIdentifier</key><string>com.cockos.reaper</string>
    <key>CFBundleExecutable</key><string>REAPER</string>
    <key>CFBundleIconFile</key><string>main.icns</string>
    </dict></plist>
    EOF
  '';
  # Exercise both module branches with runnable fixtures on the build host.
  # This checks bundle construction and launcher behavior without running REAPER.
  evaluate = darwin:
    lib.evalModules {
      specialArgs = {
        pkgs =
          pkgs
          // {
            stdenv =
              pkgs.stdenv
              // {
                hostPlatform =
                  pkgs.stdenv.hostPlatform
                  // {
                    isDarwin = darwin;
                    isLinux = !darwin;
                  };
              };
          };
        lib = lib // {hm.dag.entryAfter = after: data: {inherit after data;};};
      };
      modules = [
        ../modules
        {
          options = {
            assertions = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              default = [];
            };
            warnings = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
            };
            home.username = lib.mkOption {
              type = lib.types.str;
              default = "test";
            };
            home.packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [];
            };
            home.activation = lib.mkOption {
              type = lib.types.attrsOf lib.types.unspecified;
              default = {};
            };
            xdg.configHome = lib.mkOption {
              type = lib.types.str;
              default = "/unused";
            };
          };

          config.programs.reaper = {
            enable = true;
            basePackage = fixture;
            configPath = "/tmp/managed reaper's config";
            packages = [fixture];
            preferences.plugIns.reascript.python.enable = true;
          };
        }
      ];
    };
  darwin = (evaluate true).config.programs.reaper;
  linux = (evaluate false).config.programs.reaper;
in
  assert darwin.ini.sections.reaper.pythonlibdll64 == "libpython${pkgs.python3.pythonVersion}.dylib";
  assert linux.ini.sections.reaper.pythonlibdll64 == "libpython${pkgs.python3.pythonVersion}.so";
  assert darwin.ini.sections.reaper.pythonlibpath64 == "${pkgs.python3}/lib";
  assert !(lib.hasInfix "DYLD_LIBRARY_PATH" (builtins.readFile ../packages/reaper.nix));
    runCommand "reaper-managed-launcher-tests" {
      nativeBuildInputs = [pkgs.python3];
      DARWIN_WRAPPER = darwin.package;
      LINUX_WRAPPER = linux.package;
      BASE_PACKAGE = fixture;
    } ''
      python3 ${./test_managed_launcher.py}
      touch "$out"
    ''
