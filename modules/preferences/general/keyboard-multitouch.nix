{
  config,
  lib,
  reaperLib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (reaperLib) reaperBitfield reaperTypes;
  cfg = config.programs.reaper.preferences.general.keyboardMultitouch;
  gestureGearing = types.addCheck reaperTypes.number (value: value >= 1.0);
in {
  options.programs.reaper.preferences.general.keyboardMultitouch = {
    commitChangesToEditFieldsAfterOneSecond = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER commits changes to supported edit fields after one second without typing.";
    };

    useAlternateKeyboardSectionWhenRecording = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether REAPER uses the alternate keyboard section while recording.";
    };

    preventAltKeyFocusingMainMenu = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether pressing Alt is prevented from focusing REAPER's main menu.";
    };

    allowSpaceKeyForNavigationInWindows = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether the space key can be used for navigation in REAPER windows.";
    };

    sendSpaceKeyFromPluginTextFieldsToMainWindow = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = true;
      description = "Whether pressing space in a plug-in text field is sent to REAPER's main window.";
    };

    momentaryKeyboardSectionOverrideTimeoutMilliseconds = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      example = 1000;
      description = "Timeout for momentary keyboard-section overrides, in milliseconds.";
    };

    multitouch = {
      swipe = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether multitouch swipe gestures are enabled.";
        };
        suppressInertia = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether inertia is suppressed for multitouch swipe gestures.";
        };
        reverse = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether multitouch swipe direction is reversed.";
        };
        gearing = mkOption {
          type = types.nullOr gestureGearing;
          default = null;
          example = 1.0;
          description = "Gearing multiplier for multitouch swipe gestures.";
        };
      };

      zoom = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether multitouch zoom gestures are enabled.";
        };
        suppressInertia = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether inertia is suppressed for multitouch zoom gestures.";
        };
        reverse = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether multitouch zoom direction is reversed.";
        };
        gearing = mkOption {
          type = types.nullOr gestureGearing;
          default = null;
          example = 1.0;
          description = "Gearing multiplier for multitouch zoom gestures.";
        };
      };

      rotate = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Whether multitouch rotate gestures are enabled.";
        };
        suppressInertia = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether inertia is suppressed for multitouch rotate gestures.";
        };
        reverse = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = false;
          description = "Whether multitouch rotate direction is reversed.";
        };
        gearing = mkOption {
          type = types.nullOr gestureGearing;
          default = null;
          example = 1.0;
          description = "Gearing multiplier for multitouch rotate gestures.";
        };
      };

      reverseVerticalScroll = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether vertical scrolling is reversed.";
      };

      reverseHorizontalScroll = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Whether horizontal scrolling is reversed.";
      };

      ignoreNewGestureAfterGestureMilliseconds = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 150;
        description = "Milliseconds to ignore a new gesture after a multitouch gesture.";
      };

      ignoreScrollAfterGestureMilliseconds = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 150;
        description = "Milliseconds to ignore scrolling after a multitouch gesture.";
      };
    };
  };

  config.programs.reaper.ini.sections.reaper =
    lib.optionalAttrs (cfg.momentaryKeyboardSectionOverrideTimeoutMilliseconds != null) {
      kbd_override_len = cfg.momentaryKeyboardSectionOverrideTimeoutMilliseconds;
    }
    // lib.optionalAttrs (cfg.multitouch.swipe.gearing != null) {multitouch_swipe_gear = cfg.multitouch.swipe.gearing;}
    // lib.optionalAttrs (cfg.multitouch.zoom.gearing != null) {multitouch_zoom_gear = cfg.multitouch.zoom.gearing;}
    // lib.optionalAttrs (cfg.multitouch.rotate.gearing != null) {multitouch_rotate_gear = cfg.multitouch.rotate.gearing;}
    // lib.optionalAttrs (cfg.multitouch.ignoreNewGestureAfterGestureMilliseconds != null) {
      multitouch_ignore_ms = cfg.multitouch.ignoreNewGestureAfterGestureMilliseconds;
    }
    // lib.optionalAttrs (cfg.multitouch.ignoreScrollAfterGestureMilliseconds != null) {
      multitouch_ignorewheel_ms = cfg.multitouch.ignoreScrollAfterGestureMilliseconds;
    };

  config.programs.reaper.ini.bitfields.reaper = reaperBitfield.entries {
    kbd_usealt = [
      {
        optionPath = "preferences.general.keyboardMultitouch.useAlternateKeyboardSectionWhenRecording";
        gui = "Use alternate keyboard section when recording";
        option = cfg.useAlternateKeyboardSectionWhenRecording;
        bit = 1;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.commitChangesToEditFieldsAfterOneSecond";
        gui = "Commit changes to some edit fields after 1 second of no typing";
        option = cfg.commitChangesToEditFieldsAfterOneSecond;
        bit = 2;
        inverted = true;
      }
    ];

    mousewheelmode = [
      {
        optionPath = "preferences.general.keyboardMultitouch.preventAltKeyFocusingMainMenu";
        gui = "Prevent ALT key from focusing main menu";
        option = cfg.preventAltKeyFocusingMainMenu;
        bit = 16;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.allowSpaceKeyForNavigationInWindows";
        gui = "Allow space key to be used for navigation in various windows";
        option = cfg.allowSpaceKeyForNavigationInWindows;
        bit = 128;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.sendSpaceKeyFromPluginTextFieldsToMainWindow";
        gui = "When space key is pressed in plug-in text fields, send to main window";
        option = cfg.sendSpaceKeyFromPluginTextFieldsToMainWindow;
        bit = 512;
      }
    ];

    multitouch = [
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.swipe.enable";
        gui = "Enable multitouch swipe";
        option = cfg.multitouch.swipe.enable;
        bit = 1;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.zoom.enable";
        gui = "Enable multitouch zoom";
        option = cfg.multitouch.zoom.enable;
        bit = 2;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.rotate.enable";
        gui = "Enable multitouch rotate";
        option = cfg.multitouch.rotate.enable;
        bit = 4;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.swipe.suppressInertia";
        gui = "Suppress inertia for multitouch swipe";
        option = cfg.multitouch.swipe.suppressInertia;
        bit = 8;
        inverted = true;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.zoom.suppressInertia";
        gui = "Suppress inertia for multitouch zoom";
        option = cfg.multitouch.zoom.suppressInertia;
        bit = 16;
        inverted = true;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.rotate.suppressInertia";
        gui = "Suppress inertia for multitouch rotate";
        option = cfg.multitouch.rotate.suppressInertia;
        bit = 32;
        inverted = true;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.swipe.reverse";
        gui = "Reverse multitouch swipe";
        option = cfg.multitouch.swipe.reverse;
        bit = 64;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.zoom.reverse";
        gui = "Reverse multitouch zoom";
        option = cfg.multitouch.zoom.reverse;
        bit = 128;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.rotate.reverse";
        gui = "Reverse multitouch rotate";
        option = cfg.multitouch.rotate.reverse;
        bit = 256;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.reverseVerticalScroll";
        gui = "Reverse vertical scroll";
        option = cfg.multitouch.reverseVerticalScroll;
        bit = 512;
      }
      {
        optionPath = "preferences.general.keyboardMultitouch.multitouch.reverseHorizontalScroll";
        gui = "Reverse horizontal scroll";
        option = cfg.multitouch.reverseHorizontalScroll;
        bit = 1024;
      }
    ];
  };
}
