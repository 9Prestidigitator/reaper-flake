<p align="center">
  <img src="https://www.reaper.fm/v5img/logo.jpg" alt="REAPER logo" width="220">
</p>

<h1 align="center">reaper-flake</h1>

<p align="center">
  REAPER packages and Home Manager configuration, patched into a Nix flake.
</p>

<p align="center">
  <a href="https://www.reaper.fm/"><img alt="REAPER 7.75" src="https://img.shields.io/badge/REAPER-7.75-2b9bd8?style=for-the-badge"></a>
  <a href="https://reapack.com/"><img alt="ReaPack 1.2.6" src="https://img.shields.io/badge/ReaPack-1.2.6-69c72f?style=for-the-badge"></a>
  <a href="https://www.sws-extension.org/"><img alt="SWS 2.14.0.7" src="https://img.shields.io/badge/SWS-2.14.0.7-bb6b5b?style=for-the-badge"></a>
</p>

## Track List

| Track            | Version    | Output                            |
| ---------------- | ---------- | --------------------------------- |
| REAPER           | `7.75`     | `packages.reaper`                 |
| ReaPack          | `1.2.6`    | `packages.reapack`                |
| SWS              | `2.14.0.7` | `packages.sws`                    |
| Reapertips Theme | `1.90`     | `packages.reapertips-theme`       |
| SWELL Wayland    | `1.1.0w`   | `packages.swell-wayland` on Linux |

Most package derivations are originally from nixpkgs with updated hashes and small tweaks.

The SWELL wayland derivation was inspired by this [post](https://forum.cockos.com/showthread.php?t=305832).

## Home Manager

Declare REAPER, seed its resource path, and link extensions from Nix-built packages.

> [!NOTE]
> If you are using something like impermanence or preservation you will want to persist the specified configPath manually. This is because REAPER has a stateful configuration model.

### Example

```nix
{
  config,
  inputs,
  reaperActions,
  reaperAppearance,
  reaperMouse,
  reaperWindows,
  ...
}: {
  imports = [inputs.reaper-flake.homeModules.reaper];

  programs.reaper = {
    enable = true;
    configPath = "${config.xdg.configHome}/HOME-REAPER";

    extensions = {
      reapack.enable = true;
      sws.enable = true;
    };

    preferences = {
      appearance = {
        trackControlPanels = {
          setTrackLabelBackgroundToCustomTrackColors = true;
          tintTrackPanelBackgrounds = false;
          alignTcpControlsWhenTrackIconsOrFixedItemLanesAreUsed = true;

          showFxInserts = true;
          showSends = true;
          groupSendsWithFxInserts = false;
          groupFxParametersWithInserts = true;

          trackGroupingIndicators = reaperAppearance.trackControlPanels.trackGroupingIndicators.ribbons;
          folderCollapseButtonCyclesTrackHeights =
            reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights.normalSmallCollapsed;
          fixedLaneCollapseButtonChangesDisplay =
            reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay.bigSmallLanes;

          volumeFaderRange = {
            minimum = -72;
            maximum = 12;
          };
          volumeFaderShape = reaperAppearance.trackControlPanels.volumeFaderShape.default;
          panFaderUnitDisplay = reaperAppearance.trackControlPanels.panFaderUnitDisplay.percent100;
        };

        zoomScrollOffset = {
          verticalZoomCenter = reaperAppearance.zoomScrollOffset.zoomCenter.vertical.lastSelectedTrack;
          maximumVerticalZoom = 0.80;
          envelopeLaneVerticalZoom = 0.4;
          horizontalZoomCenter = reaperAppearance.zoomScrollOffset.zoomCenter.horizontal.mouseCursor;
          limitHorizontalZoomScrollToProjectStart = false;
          disableMousewheelVerticalZoomForTracksThatArePinnedInArrangeView = true;

          verticalScrollStep = {
            unit = reaperAppearance.zoomScrollOffset.verticalScrollStep.units.trackHeight;
            trackHeight = 0.5;
            arrangeViewHeight = 0.1;
          };

          overlappingMediaItems = {
            offset = 100;
            drawAsOpaque = false;
            arrangeInCreationOrder = false;
          };
        };
      };

      windows = {
        transportDockPosition = reaperWindows.transport.topOfMainWindow;
        mixer.show = false;
      };

      mouse = {
        importedContexts = with reaperMouse; [
          contexts.arrange.middleDrag
          contexts.midiPianoRoll.leftClick
        ];

        contexts = with reaperMouse; merge [
          # Arrange view middle-drag: hand scroll/pan.
          (set contexts.arrange.middleDrag modifiers.none (mouse 7))

          # MIDI piano roll single-click: insert a note.
          # This uses REAPER's action text until this flake has named mouse-action enums.
          (set contexts.midiPianoRoll.leftClick modifiers.none (mouse 4))
        ];
      };

      plugIns = {
        reascript.python.enable = true;

        vst.searchPaths = ["~/Document/VSTs"];
        clap.searchPaths = ["~/Downloads/claps"];
        lv2 = {
          searchPaths = ["~/.lv2-experimental"];
          enableUserPaths = false;
        };
      };
    };

    actions = {
      scripts = [
        {
          path = "User/toggle-click.lua";
          source = ./scripts/toggle-click.lua;
          commandId = "RS_toggle_click";
          description = "Custom: toggle click";
        }
      ];

      keyBindings = with reaperActions; bindings [
        (shortcut {
          shortcut = "Space";
          command = commands.transport.play;
          actionName = "Transport: Play";
        })

        (shortcut {
          shortcut = "Ctrl+Alt+C";
          command = "RS_toggle_click";
          actionName = "Custom: toggle click";
        })

        (globalShortcut {
          shortcut = "Ctrl+Alt+Space";
          command = commands.transport.stop;
          scope = "global";
          actionName = "Transport: Stop";
        })
      ];
    };
  };
}
```

The default configuration path is `~/.config/reaper-flake` instead of `~/.config/REAPER` to avoid overwriting original GUI configurations, this can be changed with `programs.reaper.configPath`.

When removing an option from your configuration that was instantiated with the flake, the the module will automatically clean up the option in the ini. Reseting it to whatever the default reaper value. That is the purpose of the `.nix-managed` directory in the config directory. For bitfields it will just clean the managed bit mask.

> [!NOTE]
> If you are using the raw default package exposed by the flake you have to specify the configuration path when launching REAPER: `reaper -cfgfile ~/.config/reaper-flake/reaper.ini`.

## Roadmap

Continue studying Reaper configuration model to allow for options I use most to be set. Found this [site](https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html) as a good reference.

## Inspirations

- [plasma-manager](https://github.com/nix-community/plasma-manager)
- [audio.nix](https://github.com/polygon/audio.nix)
