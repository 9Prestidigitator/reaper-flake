<p align="center">
  <img src="https://www.reaper.fm/v5img/logo.jpg" alt="REAPER logo" width="220">
</p>

<h1 align="center">reaper-flake</h1>

<p align="center">
  REAPER packages and Home Manager configuration, patched into a Nix flake.
</p>

<p align="center">
  <a href="https://www.reaper.fm/"><img alt="REAPER 7.74" src="https://img.shields.io/badge/REAPER-7.74-2b9bd8?style=for-the-badge"></a>
  <a href="https://reapack.com/"><img alt="ReaPack 1.2.6" src="https://img.shields.io/badge/ReaPack-1.2.6-69c72f?style=for-the-badge"></a>
  <a href="https://www.sws-extension.org/"><img alt="SWS 2.14.0.7" src="https://img.shields.io/badge/SWS-2.14.0.7-bb6b5b?style=for-the-badge"></a>
</p>

## Track List

| Track            | Version    | Output                            |
| ---------------- | ---------- | --------------------------------- |
| REAPER           | `7.74`     | `packages.reaper`                 |
| ReaPack          | `1.2.6`    | `packages.reapack`                |
| SWS              | `2.14.0.7` | `packages.sws`                    |
| Reapertips Theme | `1.90`     | `packages.reapertips-theme`       |
| SWELL Wayland    | `1.1.0w`   | `packages.swell-wayland` on Linux |

Package derivations are originally from nixpkgs with updated hashes and small tweaks.

## Home Manager

Declare REAPER, seed its resource path, and link extensions from Nix-built packages.

> [!NOTE]
> If you are using something like impermanence or preservation you will want to persist the specified configPath manually. This is because REAPER has a stateful configuration model.

### Example

```nix
{
  config,
  inputs,
  reaperAppearance,
  reaperMouse,
  reaperWindows,
  ...
}: let
  mouse = reaperMouse;
  appearance = reaperAppearance;
in {
  imports = [inputs.reaper-flake.homeModules.reaper];

  programs.reaper = {
    enable = true;
    configPath = "${config.xdg.configHome}/HOME-REAPER";

    extensions = {
      reapack.enable = true;
      sws.enable = true;
    };

    preferences = {
      appearance.zoomScrollOffset = {
        verticalZoomCenter = appearance.zoomScrollOffset.zoomCenter.vertical.lastSelectedTrack;
        maximumVerticalZoom = 0.80;
        envelopeLaneVerticalZoom = 0.4;
        horizontalZoomCenter = appearance.zoomScrollOffset.zoomCenter.horizontal.mouseCursor;
        limitHorizontalZoomScrollToProjectStart = false;

        verticalScrollStep = {
          unit = appearance.zoomScrollOffset.verticalScrollStep.units.trackHeight;
          trackHeight = 0.5;
          arrangeViewHeight = 0.1;
        };

        overlappingMediaItems = {
          offset = 100;
          drawAsOpaque = false;
          arrangeInCreationOrder = false;
        };
      };

      windows = {
        transportDockPosition = reaperWindows.transport.topOfMainWindow;
        mixer.show = false;
      };

      mouse = {
        importedContexts = [
          mouse.contexts.arrange.middleDrag
          mouse.contexts.midiPianoRoll.leftClick
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
        vst.searchPaths = ["~/Document/VSTs"];
        clap.searchPaths = ["~/Downloads/claps"];
        lv2 = {
          searchPaths = ["~/.lv2-experimental"];
          enableUserPaths = false;
        };
      };
    };
  };
}
```

> [!NOTE]
> If you are using the raw default package exposed by the flake you have to specify the configuration path when launching REAPER: `reaper -cfgfile ~/.config/reaper-flake/reaper.ini`.

## Roadmap

Continue studying Reaper configuration model to allow for options I use most to be set. Found this [site](https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html) as a good reference.

## Inspirations

- [plasma-manager](https://github.com/nix-community/plasma-manager)
- [audio.nix](https://github.com/polygon/audio.nix)
