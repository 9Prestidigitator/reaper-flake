{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption literalExpression types optional hm optionalString;
  cfg = config.programs.reaper;
in {
  imports = [
    ./sws.nix
    ./reapack.nix
  ];

  options.programs.reaper = {
    enable = mkEnableOption ''
      Declarative configuration options for the digital audio workstation REAPER.
    '';

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../packages/reaper.nix {
        pythonSupport = cfg.pythonSupport.enable;
        python3 = cfg.pythonSupport.package;
        waylandSwellSupport = cfg.experimental.swell-wayland.enable;
        swell-wayland =
          if pkgs.stdenv.hostPlatform.isLinux
          then pkgs.callPackage ../packages/swell-wayland.nix {}
          else null;
      };
      defaultText = literalExpression "inputs.reaper-flake.packages.${pkgs.system}.reaper";
      description = "REAPER package to use.";
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
          using the module's default `programs.reaper.package`.
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
