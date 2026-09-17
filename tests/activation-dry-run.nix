{
  lib,
  pkgs,
  runCommand,
}: let
  fixture = runCommand "reaper-activation-fixture" {} ''
    mkdir -p "$out/opt/REAPER/InstallData" "$out/share/reaper/Data" "$out/UserPlugins"
    echo seed > "$out/opt/REAPER/InstallData/seed.txt"
    echo theme > "$out/share/reaper/Data/theme.txt"
    echo plugin > "$out/UserPlugins/reapack.so"
  '';
  evaluated = lib.evalModules {
    specialArgs = {
      inherit pkgs;
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
          installPackage = false;
          package = fixture;
          configPath = "/REAPER_TEST_ROOT";
          activation.allowRunning = true;
          ini.sections.reaper.test = "managed";
          lineFiles.files."Scripts/test.lua" = ["managed line"];
          resourceFiles.files."generated.txt" = pkgs.writeText "generated-resource" "generated";
          resourceLinks.files."linked.txt" = pkgs.writeText "linked-resource" "linked";
          theme.packages = [fixture];
          extensions.reapack = {
            enable = true;
            package = fixture;
            synchronizeOnActivation = true;
          };
        };
      }
    ];
  };
  activation = pkgs.writeText "reaper-test-activation.json" (builtins.toJSON
    (map (name: evaluated.config.home.activation.${name}.data)
      ["reaper" "reaperThemePackages" "reaperReapack"]));
in
  runCommand "reaper-activation-dry-run-tests" {
    nativeBuildInputs = [pkgs.python3];
    ACTIVATION_ENTRIES = activation;
    TEST_SHELL = pkgs.runtimeShell;
  } ''
    python3 ${./test_activation_dry_run.py} -v
    touch "$out"
  ''
