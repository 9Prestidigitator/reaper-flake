{
  lib,
  pkgs,
  runCommand,
}: let
  reaperLib = import ../modules/lib {inherit lib;};
  evaluate = transport:
    lib.evalModules {
      specialArgs = reaperLib // {inherit pkgs reaperLib;};
      modules = [
        ../modules/ini.nix
        ../modules/windows.nix
        {
          options.assertions = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [];
          };
          config.programs.reaper.windows.transport = transport;
        }
      ];
    };
  flags = value: {
    showPlayrateControl = value;
    showTimeSignature = value;
    showPlayStateAsText = value;
    centerTransportControls = value;
    flashOnPossibleAudioDeviceUnderrun = value;
    automaticallyScrollViewDuringPlayback = value;
    continuousScrolling = value;
    smoothSeeking = value;
    chaseMidiNoteOnCcPitch = value;
    stopPlaybackAtEndOfLoopIfRepeatDisabled = value;
  };
  enabled =
    (evaluate ((flags true)
      // {
        recordMode = "timeSelectionAutoPunch";
        timeDisplay = {
          primary = "measuresBeats";
          secondary = "hoursMinutesSecondsFrames";
        };
      })).config.programs.reaper.ini;
  disabled = (evaluate (flags false)).config.programs.reaper.ini;
  defaults = (evaluate {}).config.programs.reaper.ini;
  invalid = evaluate {
    timeDisplay = {
      primary = "ruler";
      secondary = "seconds";
    };
  };
  codec = reaperLib.reaperWindows.transportControls.timeDisplayCodec;
  # Observed by running REAPER 7.80's primary/secondary time-unit actions.
  samples = [
    {
      primary = "ruler";
      secondary = "none";
      encoded = -1;
    }
    {
      primary = "minutesSeconds";
      secondary = "none";
      encoded = 0;
    }
    {
      primary = "measuresBeats";
      secondary = "none";
      encoded = 2;
    }
    {
      primary = "measuresBeats";
      secondary = "minutesSeconds";
      encoded = 1;
    }
    {
      primary = "minutesSeconds";
      secondary = "measuresBeats";
      encoded = 9;
    }
    {
      primary = "seconds";
      secondary = "minutesSeconds";
      encoded = 259;
    }
    {
      primary = "samples";
      secondary = "minutesSeconds";
      encoded = 260;
    }
    {
      primary = "hoursMinutesSecondsFrames";
      secondary = "minutesSeconds";
      encoded = 261;
    }
    {
      primary = "absoluteFrames";
      secondary = "minutesSeconds";
      encoded = 264;
    }
    {
      primary = "measuresBeats";
      secondary = "seconds";
      encoded = 1026;
    }
    {
      primary = "measuresBeats";
      secondary = "samples";
      encoded = 1282;
    }
    {
      primary = "measuresBeats";
      secondary = "hoursMinutesSecondsFrames";
      encoded = 1538;
    }
    {
      primary = "measuresBeats";
      secondary = "absoluteFrames";
      encoded = 2306;
    }
  ];
in
  assert defaults.sections.reaper == {};
  assert defaults.bitfields == {};
  assert enabled.bitfields.reaper.transflags
  == {
    mask = 143;
    value = 136;
  };
  assert disabled.bitfields.reaper.transflags
  == {
    mask = 143;
    value = 7;
  };
  assert enabled.bitfields.reaper.viewadvance
  == {
    mask = 17;
    value = 17;
  };
  assert disabled.bitfields.reaper.viewadvance
  == {
    mask = 17;
    value = 0;
  };
  assert enabled.bitfields.reaper.rbn
  == {
    mask = 128;
    value = 0;
  };
  assert disabled.bitfields.reaper.rbn
  == {
    mask = 128;
    value = 128;
  };
  assert enabled.bitfields.reaper.smoothseek
  == {
    mask = 1;
    value = 1;
  };
  assert enabled.sections.reaper.stopendofloop == 1;
  assert disabled.sections.reaper.stopendofloop == 0;
  assert enabled.sections.reaper.projrecmode == 2;
  assert enabled.sections.reaper.projtimemode2 == 1538;
  assert builtins.any (entry: !entry.assertion) invalid.config.assertions;
  assert builtins.all (sample: let
    value = removeAttrs sample ["encoded"];
  in
    reaperLib.reaperCodecs.encode codec value
    == sample.encoded
    && reaperLib.reaperCodecs.decode codec sample.encoded == value)
  samples;
    runCommand "reaper-transport-tests" {
      nativeBuildInputs = [pkgs.python3];
      PAYLOAD = enabled.generatedPayloadFiles."reaper.ini";
      SCHEMA = defaults.generatedSchemaFile;
      WRITER = ../scripts/write_config.py;
      IMPORTER = ../scripts/reaper2nix.py;
      SAMPLES = pkgs.writeText "transport-time-samples.json" (builtins.toJSON samples);
    } ''
      python3 - <<'PY'
      import importlib.util, json, os, pathlib, subprocess, sys
      spec = importlib.util.spec_from_file_location("importer", os.environ["IMPORTER"])
      importer = importlib.util.module_from_spec(spec)
      spec.loader.exec_module(importer)
      schema = json.loads(pathlib.Path(os.environ["SCHEMA"]).read_text())
      options = {o["path"]: o for o in schema["options"]}
      codec = options["windows.transport.timeDisplay"]["codec"]
      for sample in json.loads(pathlib.Path(os.environ["SAMPLES"]).read_text()):
          assert importer.decode(codec, str(sample["encoded"])) == {k:v for k,v in sample.items() if k != "encoded"}
      for invalid in ("-2", "6", "65536", "garbage"):
          try:
              importer.decode(codec, invalid)
          except ValueError:
              pass
          else:
              raise AssertionError(invalid)
      target = pathlib.Path("reaper.ini")
      target.write_text("[reaper]\ntransflags=80\nviewadvance=10\nrbn=136\nsmoothseek=2\n")
      subprocess.run([sys.executable, os.environ["WRITER"], str(target), "state.json", os.environ["PAYLOAD"]], check=True)
      result = target.read_text()
      for expected in ("transflags=216", "viewadvance=27", "rbn=8", "smoothseek=3", "projrecmode=2", "projtimemode2=1538"):
          assert expected + "\n" in result, result
      imported = subprocess.check_output([sys.executable, os.environ["IMPORTER"], str(target), "--schema", os.environ["SCHEMA"], "--options", "programs.reaper.windows.transport"], text=True)
      for expected in ('showPlayrateControl = true;', 'chaseMidiNoteOnCcPitch = true;', 'recordMode = "timeSelectionAutoPunch";', 'primary = "measuresBeats";', 'secondary = "hoursMinutesSecondsFrames";'):
          assert expected in imported, imported
      PY
      touch "$out"
    ''
