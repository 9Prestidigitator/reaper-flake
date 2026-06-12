{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption literalExpression types optional hm optionalString;

  cfg = config.programs.reaper;

  # Base Reaper package that comes with this flake
  defaultBaseReaperPackage = pkgs.callPackage ../packages/reaper.nix {
    pythonSupport = cfg.pythonSupport.enable;
    python3 = cfg.pythonSupport.package;
    waylandSwellSupport = cfg.experimental.swell-wayland.enable;
    swell-wayland =
      if pkgs.stdenv.hostPlatform.isLinux
      then pkgs.callPackage ../packages/swell-wayland.nix {}
      else null;
  };

  # Parallel Reaper hm-package that uses the home-managed configuration
  # directory by default
  homeWrappedReaperPackage = pkgs.symlinkJoin {
    name = "${cfg.basePackage.pname or "REAPER"}-config-wrapper";
    paths = [cfg.basePackage];
    postBuild = ''
      mkdir -p "$out/bin"
      rm -f "$out/bin/reaper"
      cat > "$out/bin/reaper" <<'EOF'
      #!${pkgs.runtimeShell}
      has_cfgfile=0
      for arg in "$@"; do
        case "$arg" in
          -cfgfile|--cfgfile|-cfgfile=*|--cfgfile=*)
            has_cfgfile=1
            ;;
        esac
      done

      if [ "$has_cfgfile" -eq 1 ]; then
        exec ${lib.escapeShellArg "${cfg.basePackage}/bin/reaper"} "$@"
      else
        exec ${lib.escapeShellArg "${cfg.basePackage}/bin/reaper"} -cfgfile ${lib.escapeShellArg "${cfg.configPath}/reaper.ini"} "$@"
      fi
      EOF
      chmod +x "$out/bin/reaper"
    '';
    meta = cfg.basePackage.meta or {};
  };
in {
  imports = [
    ./sws.nix
    ./reapack.nix
    # ./ini.nix
  ];

  options.programs.reaper = {
    enable = mkEnableOption ''
      Declarative configuration options for the digital audio workstation REAPER.
    '';

    package = mkOption {
      type = types.package;
      default = homeWrappedReaperPackage;
      defaultText = literalExpression ''
        config.programs.reaper.basePackage wrapper that launches REAPER with
        -cfgfile config.programs.reaper.configPath/reaper.ini unless -cfgfile is
        supplied
      '';
      description = "REAPER package that is installed to home.packages.";
    };
    
    basePackage = mkOption {
      type = types.package;
      default = defaultBaseReaperPackage;
      defaultText = literalExpression ''
        inputs.reaper-flake.packages.${pkgs.system}.reaper.override {
          pythonSupport = config.programs.reaper.pythonSupport.enable;
          python3 = config.programs.reaper.pythonSupport.package;
        }
      '';
      description = "Unwrapped REAPER package to use.";
    };

    configPath = mkOption {
      type = types.str;
      default = "${config.xdg.configHome}/REAPER";
      defaultText = literalExpression ''"''${config.xdg.configHome}/REAPER"'';
    };

    installPackage = mkOption {
      type = types.bool;
      default = true;
      description = "Install `programs.reaper.package` into `home.packages`; useful outside NixOS system package management.";
    };

    stockResources.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to seed REAPER's stock first-run resources from `$out/opt/REAPER/InstallData`.
      '';
    };

    pythonSupport = {
      enable = mkEnableOption "Python support in REAPER";

      package = mkOption {
        type = types.package;
        default = pkgs.python3;
        defaultText = literalExpression "pkgs.python3";
        description = ''
          Python package made available to REAPER for Python ReaScripts when
          using the module's default `programs.reaper.package` (BROKEN).
        '';
      };
    };

    experimental.swell-wayland.enable = mkEnableOption "EXTREMELY EXPERIMENTAL AND BROKEN: Reaper on native wayland.";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.experimental.swell-wayland.enable || pkgs.stdenv.hostPlatform.isLinux;
        message = "Swell on wayland is a Linux only feature.";
      }
    ];

    home = {
      packages = optional cfg.installPackage cfg.package;

      activation.reaper = hm.dag.entryAfter ["writeBoundary"] ''
        reaper_resource_path=${lib.escapeShellArg cfg.configPath}
        mkdir -p "$reaper_resource_path"

        # Seeds initial REAPER resource path by copying files that are not
        # present in configured resource path.
        copy_seed_tree() {
          src=$1
          dst=$2

          [ -d "$src" ] || return 0
          mkdir -p "$dst"

          find "$src" -mindepth 1 -print | while IFS= read -r src_path; do
            rel_path=''${src_path#"$src"/}
            dst_path="$dst/$rel_path"

            if [ -d "$src_path" ]; then
              mkdir -p "$dst_path"
            elif [ -e "$dst_path" ] && [ ! -L "$dst_path" ]; then
              :
            else
              mkdir -p "$(dirname "$dst_path")"
              install -m 0644 "$src_path" "$dst_path"
            fi
          done
        }

        ${optionalString cfg.stockResources.enable ''
          copy_seed_tree ${lib.escapeShellArg "${cfg.package}/opt/REAPER/InstallData"} "$reaper_resource_path"
        ''}

        link_tree() {
          src=$1
          dst=$2

          [ -d "$src" ] || return 0
          mkdir -p "$dst"

          # Link immutable package resources without taking over user-created files.
          find "$src" -mindepth 1 -print | while IFS= read -r src_path; do
            rel_path=''${src_path#"$src"/}
            dst_path="$dst/$rel_path"

            if [ -d "$src_path" ]; then
              mkdir -p "$dst_path"
            elif [ -e "$dst_path" ] && [ ! -L "$dst_path" ]; then
              :
            else
              mkdir -p "$(dirname "$dst_path")"
              ln -sfn "$src_path" "$dst_path"
            fi
          done
        }

        ${optionalString cfg.extensions.reapack.enable ''
          link_tree ${lib.escapeShellArg "${cfg.extensions.reapack.package}/UserPlugins"} "$reaper_resource_path/UserPlugins"
        ''}

        ${optionalString cfg.extensions.sws.enable ''
          link_tree ${lib.escapeShellArg "${cfg.extensions.sws.package}/UserPlugins"} "$reaper_resource_path/UserPlugins"
          link_tree ${lib.escapeShellArg "${cfg.extensions.sws.package}/Scripts"} "$reaper_resource_path/Scripts"
        ''}

      '';
    };
  };
}
