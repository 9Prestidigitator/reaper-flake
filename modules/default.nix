{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrsToList mkEnableOption mkIf mkMerge mkOption literalExpression types optional hm optionalString;

  cfg = config.programs.reaper;
  reaperLib = import ./lib {inherit lib;};

  # Base Reaper package that comes with this flake
  defaultBaseReaperPackage = pkgs.callPackage ../packages/reaper.nix {
    pythonSupport = cfg.preferences.plugIns.reascript.python.enable;
    python3 = cfg.preferences.plugIns.reascript.python.package;
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

  currentFilePredicate = fileNames:
    concatStringsSep "\n" (map (fileName: ''
        [ "$file_name" = ${lib.escapeShellArg fileName} ] && return 0
      '')
      fileNames);
in {
  imports = [
    ./ini.nix
    ./line-files.nix

    ./resources.nix
    ./swell.nix
    ./themes.nix

    ./actions.nix

    ./extensions/sws.nix
    ./extensions/reapack.nix

    ./layout

    ./preferences/windows.nix
    ./preferences/general
    ./preferences/project
    ./preferences/appearance
    ./preferences/editing-behavior
    ./preferences/media
    ./preferences/plugins.nix
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
          pythonSupport = config.programs.reaper.preferences.plugIns.reascript.python.enable;
          python3 = config.programs.reaper.preferences.plugIns.reascript.python.package;
        }
      '';
      description = "Unwrapped REAPER package to use.";
    };

    # Want to put the default path in a place that doesn't automatically overwrite the original REAPER configuration path
    configPath = mkOption {
      type = types.str;
      default = "${config.xdg.configHome}/reaper-flake";
      defaultText = literalExpression ''"''${config.xdg.configHome}/reaper-flake"'';
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

    experimental.swell-wayland.enable = mkEnableOption "EXTREMELY EXPERIMENTAL AND BROKEN: Reaper on native wayland.";
  };

  config = mkMerge [
    {
      _module.args.reaperLib = reaperLib;
      _module.args.reaperBitfield = reaperLib.reaperBitfield;
      _module.args.reaperLayout = reaperLib.reaperLayout;
      _module.args.reaperWindows = reaperLib.reaperWindows;
      _module.args.reaperMouse = reaperLib.reaperMouse;
      _module.args.reaperAppearance = reaperLib.reaperAppearance;
      _module.args.reaperActions = reaperLib.reaperActions;
      _module.args.reaperGeneral = reaperLib.reaperGeneral;
    }
    (mkIf cfg.enable {
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

          write_ini() {
            file_name=$1
            payload=$2
            target_ini="$reaper_resource_path/$file_name"
            state_ini="$reaper_resource_path/.nix-managed/$file_name"
            mkdir -p "$(dirname "$target_ini")" "$(dirname "$state_ini")"
            ${cfg.ini.writerPackage}/bin/write-config "$target_ini" "$state_ini" "$payload"
          }

          merge_line_file() {
            file_name=$1
            generated_lines=$2
            target_file="$reaper_resource_path/$file_name"
            state_file="$reaper_resource_path/.nix-managed/$file_name"
            tmp_without_old="$(mktemp)"
            tmp_merged="$(mktemp)"

            mkdir -p "$(dirname "$target_file")" "$(dirname "$state_file")"
            if [ ! -e "$target_file" ]; then
              touch "$target_file"
            fi

            if [ -e "$state_file" ]; then
              remove_managed_line_file_entries "$file_name" "$state_file" "$target_file" "$tmp_without_old"
            else
              cp "$target_file" "$tmp_without_old"
            fi

            ${pkgs.gawk}/bin/awk 'FNR == NR { seen[$0] = 1; print; next } !($0 in seen) { seen[$0] = 1; print }' "$tmp_without_old" "$generated_lines" > "$tmp_merged"
            install -m 0644 "$tmp_merged" "$target_file"
            install -m 0644 "$generated_lines" "$state_file"
            rm -f "$tmp_without_old" "$tmp_merged"
          }

          remove_managed_line_file_entries() {
            file_name=$1
            state_file=$2
            target_file=$3
            output_file=$4

            if [ "$file_name" = "reaper-kb.ini" ]; then
              ${pkgs.gawk}/bin/awk 'FNR == NR { old[$0] = 1; if ($1 == "SCR") oldScr[$3, $4] = 1; next } ($0 in old) { next } ($1 == "SCR" && (($3, $4) in oldScr)) { next } { print }' "$state_file" "$target_file" > "$output_file"
            else
              ${pkgs.gawk}/bin/awk 'FNR == NR { old[$0] = 1; next } !($0 in old)' "$state_file" "$target_file" > "$output_file"
            fi
          }

          is_current_ini_file() {
            file_name=$1
            ${currentFilePredicate (builtins.attrNames cfg.ini.generatedPayloadFiles)}
            return 1
          }

          is_current_line_file() {
            file_name=$1
            ${currentFilePredicate (builtins.attrNames cfg.lineFiles.generatedFiles)}
            return 1
          }

          ${concatStringsSep "\n" (mapAttrsToList (fileName: payload: ''
              write_ini ${lib.escapeShellArg fileName} ${lib.escapeShellArg payload}
            '')
            cfg.ini.generatedPayloadFiles)}

          ${concatStringsSep "\n" (mapAttrsToList (fileName: generatedFile: ''
              merge_line_file ${lib.escapeShellArg fileName} ${lib.escapeShellArg generatedFile}
            '')
            cfg.lineFiles.generatedFiles)}

          cleanup_stale_ini_files() {
            state_root="$reaper_resource_path/.nix-managed"
            [ -d "$state_root" ] || return 0

            find "$state_root" -type f -name '*.ini' -print | while IFS= read -r state_ini; do
              rel_path=''${state_ini#"$state_root"/}

              [ "$rel_path" = "reaper-kb.ini" ] && continue
              is_current_ini_file "$rel_path" && continue

              target_ini="$reaper_resource_path/$rel_path"
              if [ ! -e "$target_ini" ]; then
                rm -f "$state_ini"
                continue
              fi

              ${cfg.ini.writerPackage}/bin/write-config "$target_ini" "$state_ini" ${lib.escapeShellArg cfg.ini.emptyPayloadFile} --remove-empty-state
            done
          }

          cleanup_stale_line_files() {
            state_root="$reaper_resource_path/.nix-managed"
            [ -d "$state_root" ] || return 0

            find "$state_root" -type f -print | while IFS= read -r state_file; do
              rel_path=''${state_file#"$state_root"/}

              case "$rel_path" in
                *.ini)
                  [ "$rel_path" = "reaper-kb.ini" ] || continue
                  ;;
              esac

              is_current_line_file "$rel_path" && continue

              target_file="$reaper_resource_path/$rel_path"
              if [ -e "$target_file" ]; then
                tmp_without_old="$(mktemp)"
                remove_managed_line_file_entries "$rel_path" "$state_file" "$target_file" "$tmp_without_old"
                install -m 0644 "$tmp_without_old" "$target_file"
                rm -f "$tmp_without_old"
              fi

              rm -f "$state_file"
            done
          }

          cleanup_stale_ini_files
          cleanup_stale_line_files

          install_resource_file() {
            file_name=$1
            source_file=$2
            target_file="$reaper_resource_path/$file_name"

            mkdir -p "$(dirname "$target_file")"
            install -m 0644 "$source_file" "$target_file"
          }

          link_resource_file() {
            file_name=$1
            source_file=$2
            backup_extension=$3
            target_file="$reaper_resource_path/$file_name"

            mkdir -p "$(dirname "$target_file")"
            if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
              if [ ! -f "$target_file" ]; then
                echo "Refusing to replace existing non-regular REAPER resource: $target_file" >&2
                exit 1
              elif [ -n "$backup_extension" ]; then
                backup_file="$target_file.$backup_extension"
                if [ -e "$backup_file" ]; then
                  echo "Refusing to overwrite existing REAPER resource backup: $backup_file" >&2
                  exit 1
                fi
                mv "$target_file" "$backup_file"
              else
                echo "Refusing to replace existing non-symlink REAPER resource: $target_file" >&2
                exit 1
              fi
            fi

            ln -sfn "$source_file" "$target_file"
          }

          ${concatStringsSep "\n" (mapAttrsToList (fileName: generatedFile: ''
              install_resource_file ${lib.escapeShellArg fileName} ${lib.escapeShellArg generatedFile}
            '')
            cfg.resourceFiles.files)}

          ${concatStringsSep "\n" (mapAttrsToList (fileName: sourceFile: ''
              link_resource_file ${lib.escapeShellArg fileName} ${lib.escapeShellArg sourceFile} ${lib.escapeShellArg (
                if cfg.resourceLinks.backupFileExtension == null
                then ""
                else cfg.resourceLinks.backupFileExtension
              )}
            '')
            cfg.resourceLinks.files)}
        '';
      };
    })
  ];
}
