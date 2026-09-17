# Transport controls

`programs.reaper.windows.transport` configures the persistent settings in the transport controls context menu. Options default to `null`, leaving settings unmanaged until configured.

```nix
programs.reaper.windows.transport = {
  showPlayrateControl = true;
  showTimeSignature = true;
  showPlayStateAsText = true;
  centerTransportControls = true;
  flashOnPossibleAudioDeviceUnderrun = true;

  automaticallyScrollViewDuringPlayback = true;
  continuousScrolling = false;
  smoothSeeking = false;
  chaseMidiNoteOnCcPitch = true;
  stopPlaybackAtEndOfLoopIfRepeatDisabled = false;

  recordMode = "normal";
  timeDisplay = {
    primary = "measuresBeats";
    secondary = "minutesSeconds";
  };
};
```

## Playback and display

| Option | Context-menu setting |
| --- | --- |
| `automaticallyScrollViewDuringPlayback` | Automatically scroll view during playback |
| `continuousScrolling` | Continuous scrolling |
| `smoothSeeking` | Smooth seeking (seeks at end of measure) |
| `chaseMidiNoteOnCcPitch` | Chase MIDI note-on/CC/PC/pitch in project playback |
| `stopPlaybackAtEndOfLoopIfRepeatDisabled` | Stop playback at end of loop if repeat is disabled |
| `flashOnPossibleAudioDeviceUnderrun` | Flash transport yellow on possible audio device underrun |
| `showPlayrateControl` | Show playrate control |
| `showTimeSignature` | Show time signature |
| `showPlayStateAsText` | Show play state as text |
| `centerTransportControls` | Center transport controls |

Smooth seeking enables REAPER's existing seeking policy; it does not change the configured measure count or marker/region seeking behavior. Shared bitfields preserve unrelated preferences, including scrolling while recording and transport home/end navigation.

## Record mode and time display

These settings write **defaults for new projects**. They do not overwrite settings saved inside existing projects or project templates.

`recordMode` accepts `normal`, `timeSelectionAutoPunch`, or `selectedItemsAutoPunch`.

`timeDisplay.primary` accepts `ruler`, `minutesSeconds`, `measuresBeats`, `seconds`, `samples`, `hoursMinutesSecondsFrames`, or `absoluteFrames`. `timeDisplay.secondary` accepts the same units except `ruler`, plus `none`.

The two units are managed together because REAPER stores them in one integer. When `primary = "ruler"`, `secondary` must be `"none"`; REAPER then follows the project's ruler display. When a `timeDisplay` submodule is declared, these are also its defaults. Setting `timeDisplay = null` leaves it unmanaged.

## Docking and visibility

Use the existing [layout options](layout.md) for placement and visibility:

```nix
{ reaperWindows, ... }: {
  programs.reaper.layout.transport = {
    visible = true; # false corresponds to Hide Transport
    docked = true;
    dockPosition = reaperWindows.transport.topOfMainWindow;
  };
}
```

For the transport, `layout.transport.docked = true` selects main-window docking. The dock-position helpers are `belowArranger`, `aboveRuler`, `bottomOfMainWindow`, and `topOfMainWindow`.

REAPER's separate “Dock transport in docker” mode uses additional flags. It can be configured through the existing layout escape hatch, alongside a named docker assignment:

```nix
programs.reaper.layout = {
  docks.bottom = { id = 0; position = "bottom"; };
  transport = {
    visible = true;
    docked = false; # disable main-window docking
    dock = "bottom";
  };
  rawSections.reaper.transport_dock_pos = 768;
};
```

Leave `layout.transport.dockPosition` unset with this recipe, since it writes the same INI key. This Docker encoding was verified with REAPER 7.80.

Momentary commands such as jumping to a marker and starting playback remain actions rather than configuration options. The collapsed Playrate and External Timecode Synchronization submenus are outside this option set.

## Importing

```console
reaper2nix --options programs.reaper.windows.transport /path/to/reaper-resource-directory
```

Mappings and time-display encodings were checked against an isolated REAPER 7.80 instance using its transport actions. In particular, primary and secondary time units include legacy combined encodings as well as separate high-byte secondary units.
