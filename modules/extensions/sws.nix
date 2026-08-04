{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep literalExpression mkEnableOption mkIf mkOption types;
  cfg = config.programs.reaper.extensions.sws;

  colorType =
    (types.addCheck types.str (value: builtins.match "#[0-9A-Fa-f]{6}" value != null))
    // {
      description = "hex color in #RRGGBB format";
    };

  configuredColors =
    if cfg.colors == null
    then []
    else cfg.colors;

  colorTable = concatMapStringsSep ",\n  " (color: ''"${builtins.substring 1 6 color}"'') configuredColors;

  colorsScript = pkgs.writeText "reaper-flake-sws-colors.lua" ''
    local colors = {
      ${colorTable}
    }

    local attempts = 0
    local max_attempts = 300

    local function apply_colors()
      if not reaper.APIExists("CF_SetCustomColor") then
        attempts = attempts + 1
        if attempts < max_attempts then
          reaper.defer(apply_colors)
        end
        return
      end

      for index = 0, 15 do
        local hex = colors[index + 1]
        local native_color = 0

        if hex then
          local red = tonumber(hex:sub(1, 2), 16)
          local green = tonumber(hex:sub(3, 4), 16)
          local blue = tonumber(hex:sub(5, 6), 16)
          native_color = reaper.ColorToNative(red, green, blue)
        end

        reaper.CF_SetCustomColor(index, native_color)
      end
    end

    apply_colors()
  '';
in {
  options.programs.reaper.extensions.sws = {
    enable = mkEnableOption "Enable SWS Extensions in the config";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../../packages/sws {};
      defaultText = literalExpression "inputs.reaper-flake.packages.${pkgs.system}.sws";
      description = "Package that provides SWS files under `UserPlugins` and `Scripts`.";
    };

    colors = mkOption {
      type = types.nullOr (types.listOf colorType);
      default = null;
      example = ["#F5E0E6" "#F2CDCD" "#F5C2E7" "#CBA6F7"];
      description = ''
        SWS custom color palette in slot order. At most 16 colors may be
        specified. Missing trailing slots are cleared. Set this to an empty
        list to clear all slots, or to `null` to leave the palette unmanaged.

        The palette is applied after SWS loads when REAPER starts. This option
        is forward-only and is not currently imported by `reaper2nix`.
      '';
    };
  };

  config = mkIf (cfg.colors != null) {
    assertions = [
      {
        assertion = cfg.enable;
        message = "programs.reaper.extensions.sws.colors requires programs.reaper.extensions.sws.enable = true.";
      }
      {
        assertion = builtins.length configuredColors <= 16;
        message = "programs.reaper.extensions.sws.colors accepts at most 16 colors.";
      }
    ];

    programs.reaper = {
      resourceFiles.files."Scripts/reaper-flake/sws-colors.lua" = colorsScript;
      lineFiles.files."Scripts/__startup.lua" = [
        ''pcall(dofile, reaper.GetResourcePath() .. "/Scripts/reaper-flake/sws-colors.lua")''
      ];
    };
  };
}
