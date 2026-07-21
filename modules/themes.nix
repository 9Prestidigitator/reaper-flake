{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep hasSuffix listToAttrs mkIf mkMerge mkOption nameValuePair types;

  cfg = config.programs.reaper;
  themeCfg = cfg.theme;

  themeFileName = source: builtins.unsafeDiscardStringContext (baseNameOf (toString source));
  colorThemeLinks = listToAttrs (map (source: nameValuePair "ColorThemes/${themeFileName source}" source) themeCfg.colorThemes);
  colorThemeNames = map themeFileName themeCfg.colorThemes;
in {
  options.programs.reaper.theme = {
    active = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Smooth_6.ReaperThemeZip";
      description = ''
        File name of the active theme in REAPER's `ColorThemes` directory.
        Theme packages and `colorThemes` both make their theme files available
        there. Set this to `null` to leave REAPER's current theme unchanged.
      '';
    };

    colorThemes = mkOption {
      type = types.listOf types.path;
      default = [];
      example = lib.literalExpression "[ ./MyTheme.ReaperThemeZip ]";
      description = ''
        `.ReaperThemeZip` files to link directly into REAPER's `ColorThemes`
        directory. Each source may be a local path, a fetched fixed-output
        derivation, or any other Nix path-producing expression.
      '';
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      example = lib.literalExpression "[ inputs.reaper-flake.packages.${pkgs.system}.smooth6-theme ]";
      description = ''
        Theme packages following the reaper-flake theme-resource convention:
        REAPER resources under `share/reaper` and optional fonts under
        `share/fonts`. Resources are linked into REAPER's resource directory;
        fonts are installed through `home.packages`.
      '';
    };

    includeSwellColorThemes = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether theme-package `libSwell*.colortheme` resources are linked into
        REAPER's resource directory. Disabled by default so
        `programs.reaper.swell.colortheme` remains the final SWELL theme layer.
      '';
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = builtins.all (source: hasSuffix ".ReaperThemeZip" (themeFileName source)) themeCfg.colorThemes;
          message = "programs.reaper.theme.colorThemes entries must be .ReaperThemeZip files.";
        }
        {
          assertion = builtins.length colorThemeNames == builtins.length (lib.unique colorThemeNames);
          message = "programs.reaper.theme.colorThemes entries must have unique file names.";
        }
        {
          assertion = themeCfg.active == null || baseNameOf themeCfg.active == themeCfg.active;
          message = "programs.reaper.theme.active must be a file name, not a path.";
        }
      ];

      home.packages = themeCfg.packages;
      programs.reaper.resourceLinks.files = colorThemeLinks;
    }
    (mkIf (themeCfg.active != null) {
      programs.reaper.ini.sections.reaper.lastthemefn5 = "${cfg.configPath}/ColorThemes/${themeCfg.active}";
    })
    (mkIf (themeCfg.packages != []) {
      home.activation.reaperThemePackages = lib.hm.dag.entryAfter ["reaper"] ''
        reaper_resource_path=${lib.escapeShellArg cfg.configPath}
        include_swell_colorthemes=${
          if themeCfg.includeSwellColorThemes
          then "1"
          else "0"
        }

        link_theme_resources() {
          src=$1
          dst=$2

          [ -d "$src" ] || return 0
          mkdir -p "$dst"

          find "$src" -mindepth 1 -print | while IFS= read -r src_path; do
            rel_path=''${src_path#"$src"/}
            dst_path="$dst/$rel_path"

            if [ -d "$src_path" ]; then
              mkdir -p "$dst_path"
            elif [ "$include_swell_colorthemes" -ne 1 ] && [[ "$rel_path" == libSwell*.colortheme ]]; then
              # Remove an old package link from a previous activation without
              # taking over a regular user-managed SWELL colortheme.
              [ ! -L "$dst_path" ] || rm -f "$dst_path"
            elif [ -e "$dst_path" ] && [ ! -L "$dst_path" ]; then
              :
            else
              mkdir -p "$(dirname "$dst_path")"
              ln -sfn "$src_path" "$dst_path"
            fi
          done
        }

        ${concatMapStringsSep "\n" (themePackage: ''
            link_theme_resources ${lib.escapeShellArg "${themePackage}/share/reaper"} "$reaper_resource_path"
          '')
          themeCfg.packages}
      '';
    })
  ];
}
