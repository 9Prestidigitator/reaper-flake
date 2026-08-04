{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) literalExpression mkOption optionalAttrs types mkEnableOption;
  inherit (reaperLib) reaperBitfield reaperTypes reaperPreference reaperCodecs;

  cfg = config.programs.reaper.preferences.audio;
in {
  options.programs.reaper.preferences.audio = {
    closeAudioDeviceWhenStoppedAndApplicationIsInactive = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When enabled, REAPER will share audio devices with other applications by closing the audio hardware not active.";
    };
    closeAudioDeviceWhenInactiveAndTracksAreRecordArmed = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Wehn unchecked and any tracks are record armed, then REAPER will not share audio devices.";
    };
    closeAudioDeviceWhenInactiveAndReWireDevicesAreOpened = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "When unchecked and any tracks are record armed, then REAPER will not share audio devices.";
    };
  };

  config = {
    assertions = [
      {
        assertion =
          cfg.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed
          != true
          || cfg.closeAudioDeviceWhenStoppedAndApplicationIsInactive == true;
        message = ''
          programs.reaper.preferences.audio.closeAudioDeviceWhenInactiveAndTracksAreRecordArmed requires programs.reaper.preferences.audio.closeAudioDeviceWhenStoppedAndApplicationIsInactive to be true.
        '';
      }
    ];
    programs.reaper.ini.contributions =
      reaperPreference.contributions [
      ];
  };
}
