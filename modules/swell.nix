{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep filterAttrs genAttrs mapAttrsToList mkEnableOption mkIf mkMerge mkOption types;
  cfg = config.programs.reaper.swell.colortheme;

  colorType =
    (types.addCheck types.str (value: builtins.match "#[0-9A-Fa-f]{6}" value != null))
    // {
      description = "hex color in #RRGGBB format";
    };

  fontParameters = [
    "default_font_face"
  ];
  numericParameters = [
    "default_font_size"
    "menubar_height"
    "menubar_font_size"
    "menubar_spacing_width"
    "menubar_margin_width"
    "scrollbar_width"
    "scrollbar_min_thumb_height"
    "combo_height"
  ];
  colorParameters = [
    "_3dface"
    "_3dshadow"
    "_3dhilight"
    "_3ddkshadow"
    "button_bg"
    "button_text"
    "button_text_disabled"
    "button_shadow"
    "button_hilight"
    "checkbox_text"
    "checkbox_text_disabled"
    "checkbox_fg"
    "checkbox_inter"
    "checkbox_bg"
    "scrollbar"
    "scrollbar_fg"
    "scrollbar_bg"
    "edit_cursor"
    "edit_bg"
    "edit_bg_disabled"
    "edit_text"
    "edit_text_disabled"
    "edit_bg_sel"
    "edit_text_sel"
    "edit_hilight"
    "edit_shadow"
    "info_bk"
    "info_text"
    "menu_bg"
    "menu_shadow"
    "menu_hilight"
    "menu_text"
    "menu_text_disabled"
    "menu_bg_sel"
    "menu_text_sel"
    "menu_scroll"
    "menu_scroll_arrow"
    "menu_submenu_arrow"
    "menubar_bg"
    "menubar_text"
    "menubar_text_disabled"
    "menubar_bg_sel"
    "menubar_text_sel"
    "trackbar_track"
    "trackbar_mark"
    "trackbar_knob"
    "progress"
    "label_text"
    "label_text_disabled"
    "combo_text"
    "combo_text_disabled"
    "combo_bg"
    "combo_bg2"
    "combo_shadow"
    "combo_hilight"
    "combo_arrow"
    "combo_arrow_press"
    "listview_bg"
    "listview_bg_sel"
    "listview_text"
    "listview_text_sel"
    "listview_bg_sel_inactive"
    "listview_text_sel_inactive"
    "listview_grid"
    "listview_hdr_arrow"
    "listview_hdr_shadow"
    "listview_hdr_hilight"
    "listview_hdr_bg"
    "listview_hdr_text"
    "treeview_text"
    "treeview_bg"
    "treeview_bg_sel"
    "treeview_text_sel"
    "treeview_bg_sel_inactive"
    "treeview_text_sel_inactive"
    "treeview_arrow"
    "tab_shadow"
    "tab_hilight"
    "tab_text"
    "focusrect"
    "group_text"
    "group_shadow"
    "group_hilight"
    "focus_hilight"
  ];
  orderedParameters = fontParameters ++ numericParameters ++ colorParameters;

  settingOptions =
    genAttrs fontParameters (name:
      mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Liberation Sans";
        description = "SWELL colortheme `${name}` parameter.";
      })
    // genAttrs numericParameters (name:
      mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 13;
        description = "SWELL colortheme `${name}` parameter.";
      })
    // genAttrs colorParameters (name:
      mkOption {
        type = types.nullOr colorType;
        default = null;
        example = "#d1d1d1";
        description = "SWELL colortheme `${name}` parameter.";
      });

  stylixColors = config.lib.stylix.colors or null;
  stylixFont = config.stylix.fonts.sansSerif.name or "Sans";
  stylixColor = name: "#${stylixColors.${name}}";
  stylixSettings =
    if stylixColors == null
    then {}
    else {
      default_font_face = stylixFont;
      default_font_size = 13;
      menubar_height = 17;
      menubar_font_size = 12;
      menubar_spacing_width = 8;
      menubar_margin_width = 6;
      scrollbar_width = 14;
      scrollbar_min_thumb_height = 4;
      combo_height = 20;
      _3dface = stylixColor "base01";
      _3dshadow = stylixColor "base00";
      _3dhilight = stylixColor "base02";
      _3ddkshadow = stylixColor "base00";
      button_bg = stylixColor "base01";
      button_text = stylixColor "base05";
      button_text_disabled = stylixColor "base03";
      button_shadow = stylixColor "base00";
      button_hilight = stylixColor "base02";
      checkbox_text = stylixColor "base05";
      checkbox_text_disabled = stylixColor "base03";
      checkbox_fg = stylixColor "base05";
      checkbox_inter = stylixColor "base0A";
      checkbox_bg = stylixColor "base00";
      scrollbar = stylixColor "base01";
      scrollbar_fg = stylixColor "base03";
      scrollbar_bg = stylixColor "base00";
      edit_cursor = stylixColor "base05";
      edit_bg = stylixColor "base00";
      edit_bg_disabled = stylixColor "base01";
      edit_text = stylixColor "base05";
      edit_text_disabled = stylixColor "base03";
      edit_bg_sel = stylixColor "base0A";
      edit_text_sel = stylixColor "base00";
      edit_hilight = stylixColor "base02";
      edit_shadow = stylixColor "base00";
      info_bk = stylixColor "base00";
      info_text = stylixColor "base05";
      menu_bg = stylixColor "base00";
      menu_shadow = stylixColor "base01";
      menu_hilight = stylixColor "base02";
      menu_text = stylixColor "base05";
      menu_text_disabled = stylixColor "base03";
      menu_bg_sel = stylixColor "base0A";
      menu_text_sel = stylixColor "base00";
      menu_scroll = stylixColor "base01";
      menu_scroll_arrow = stylixColor "base05";
      menu_submenu_arrow = stylixColor "base05";
      menubar_bg = stylixColor "base01";
      menubar_text = stylixColor "base04";
      menubar_text_disabled = stylixColor "base03";
      menubar_bg_sel = stylixColor "base0A";
      menubar_text_sel = stylixColor "base00";
      trackbar_track = stylixColor "base00";
      trackbar_mark = stylixColor "base02";
      trackbar_knob = stylixColor "base0A";
      progress = stylixColor "base0A";
      label_text = stylixColor "base05";
      label_text_disabled = stylixColor "base03";
      combo_text = stylixColor "base05";
      combo_text_disabled = stylixColor "base03";
      combo_bg = stylixColor "base00";
      combo_bg2 = stylixColor "base00";
      combo_shadow = stylixColor "base00";
      combo_hilight = stylixColor "base02";
      combo_arrow = stylixColor "base05";
      combo_arrow_press = stylixColor "base0A";
      listview_bg = stylixColor "base00";
      listview_bg_sel = stylixColor "base0A";
      listview_text = stylixColor "base05";
      listview_text_sel = stylixColor "base00";
      listview_bg_sel_inactive = stylixColor "base02";
      listview_text_sel_inactive = stylixColor "base05";
      listview_grid = stylixColor "base01";
      listview_hdr_arrow = stylixColor "base05";
      listview_hdr_shadow = stylixColor "base00";
      listview_hdr_hilight = stylixColor "base02";
      listview_hdr_bg = stylixColor "base01";
      listview_hdr_text = stylixColor "base05";
      treeview_text = stylixColor "base05";
      treeview_bg = stylixColor "base00";
      treeview_bg_sel = stylixColor "base0A";
      treeview_text_sel = stylixColor "base00";
      treeview_bg_sel_inactive = stylixColor "base02";
      treeview_text_sel_inactive = stylixColor "base05";
      treeview_arrow = stylixColor "base05";
      tab_shadow = stylixColor "base00";
      tab_hilight = stylixColor "base02";
      tab_text = stylixColor "base05";
      focusrect = stylixColor "base05";
      group_text = stylixColor "base05";
      group_shadow = stylixColor "base01";
      group_hilight = stylixColor "base02";
      focus_hilight = stylixColor "base0A";
    };

  presetSettings =
    if cfg.preset == "stylix"
    then stylixSettings
    else {};
  packageSwellColorTheme =
    if builtins.isAttrs cfg.preset
    then cfg.preset.reaperSwellColorTheme or null
    else null;
  packagePreset = packageSwellColorTheme != null;
  userSettings = filterAttrs (_: value: value != null) cfg.settings;
  finalSettings = presetSettings // userSettings;
  overrideFile = pkgs.writeText "reaper-swell-colortheme-overrides" (
    concatStringsSep "\n" (mapAttrsToList (name: value: "${name} ${toString value}") userSettings)
    + "\n"
  );
  packageColorThemeSource =
    if packagePreset
    then "${cfg.preset}/share/reaper/${packageSwellColorTheme}"
    else null;
  renderedSettings =
    map
    (name: "${name} ${toString finalSettings.${name}}")
    (builtins.filter (name: builtins.hasAttr name finalSettings) orderedParameters);
in {
  options.programs.reaper.swell.colortheme = {
    enable = mkEnableOption "managed REAPER SWELL color theme";

    fileName = mkOption {
      type = types.str;
      default = "libSwell.colortheme";
      description = "REAPER resource-path file name for the generated SWELL color theme.";
    };

    preset = mkOption {
      type = types.oneOf [
        (types.enum ["none" "stylix"])
        types.package
      ];
      default = "none";
      example = "stylix";
      description = ''
        Base SWELL color theme. Use `"stylix"` for the Stylix-derived theme or
        provide a reaper-flake theme package with a
        `reaperSwellColorTheme` passthru attribute. Values in `settings`
        override keys in either generated or packaged colorthemes.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        options = settingOptions;
      };
      default = {};
      description = ''
        Low-level `libSwell.colortheme` parameters. Attribute names match SWELL
        colortheme keys exactly.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
      {
        assertion = cfg.preset != "stylix" || stylixColors != null;
        message = "programs.reaper.swell.colortheme.preset = \"stylix\" requires Stylix to provide config.lib.stylix.colors.";
      }
      {
        assertion = !builtins.isAttrs cfg.preset || packageSwellColorTheme != null;
        message = "programs.reaper.swell.colortheme.preset package must provide a reaperSwellColorTheme passthru attribute.";
      }
      ];
    }

    {
      programs.reaper.resourceFiles.files.${cfg.fileName} =
        if packagePreset
        then pkgs.runCommand "reaper-${cfg.fileName}" {} ''
          ${pkgs.gawk}/bin/awk -v overrides=${lib.escapeShellArg overrideFile} '
            BEGIN {
              while ((getline line < overrides) > 0) {
                key = line;
                sub(/^[[:space:]]*/, "", key);
                sub(/[[:space:]].*$/, "", key);
                value = line;
                sub(/^[^[:space:]]+[[:space:]]+/, "", value);
                order[++orderCount] = key;
                replacement[key] = value;
              }
              close(overrides);
            }

            {
              key = $0;
              sub(/^[[:space:]]*/, "", key);
              sub(/[[:space:]].*$/, "", key);

              if (key in replacement && $0 !~ /^[[:space:]]*[;#]/) {
                comment = "";
                commentPosition = index($0, ";");
                if (commentPosition > 0) {
                  comment = substr($0, commentPosition);
                }
                print key " " replacement[key] (comment == "" ? "" : " " comment);
                used[key] = 1;
              } else {
                print;
              }
            }

            END {
              for (idx = 1; idx <= orderCount; idx++) {
                key = order[idx];
                if (!(key in used)) {
                  print key " " replacement[key];
                }
              }
            }
          ' ${lib.escapeShellArg packageColorThemeSource} > "$out"
        ''
        else pkgs.writeText "reaper-${cfg.fileName}" (concatStringsSep "\n" renderedSettings + "\n");
    }
  ]);
}
