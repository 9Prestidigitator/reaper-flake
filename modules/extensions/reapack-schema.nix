{
  programs.reaper.schema.sources = {
    "reapack.ini" = {
      format = "ini";
      adapter = "ini";
      adapters = ["reapack"];
    };

    "ReaPack/reaper-flake-state.json" = {
      format = "json";
      adapter = "reapack-packages";
    };
  };
}
