{
  pkgs,
  reaperActions,
  ...
}: let
  toggleClickScript = pkgs.writeText "toggle-click.lua" ''
    reaper.Main_OnCommand(40364, 0)
  '';

  toggleSelectedTrackFxScript = pkgs.writeText "toggle-selected-track-fx.lua" ''
    local track_count = reaper.CountSelectedTracks(0)
    if track_count == 0 then
      reaper.MB("Select at least one track first.", "Toggle selected track FX", 0)
      return
    end

    local enable_fx = false
    for index = 0, track_count - 1 do
      local track = reaper.GetSelectedTrack(0, index)
      if reaper.GetMediaTrackInfo_Value(track, "I_FXEN") == 0 then
        enable_fx = true
        break
      end
    end

    reaper.Undo_BeginBlock()
    for index = 0, track_count - 1 do
      local track = reaper.GetSelectedTrack(0, index)
      reaper.SetMediaTrackInfo_Value(track, "I_FXEN", enable_fx and 1 or 0)
    end
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock(
      (enable_fx and "Enable" or "Bypass") .. " FX on selected tracks",
      -1
    )
  '';

  createRegionScript = pkgs.writeText "create-region-from-time-selection.lua" ''
    local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if end_time <= start_time then
      reaper.MB("Create a time selection first.", "Create region", 0)
      return
    end

    local accepted, name = reaper.GetUserInputs("Create region", 1, "Region name:,extrawidth=160", "")
    if not accepted then return end

    reaper.Undo_BeginBlock()
    reaper.AddProjectMarker2(0, true, start_time, end_time, name, -1, 0)
    reaper.UpdateTimeline()
    reaper.Undo_EndBlock("Create region from time selection", -1)
  '';
in {
  programs.reaper.actions = {
    scripts = [
      {
        path = "User/toggle-click.lua";
        source = toggleClickScript;
        commandId = "RS_toggle_click";
        description = "Custom: toggle click";
      }
      {
        path = "User/toggle-selected-track-fx.lua";
        source = toggleSelectedTrackFxScript;
        commandId = "RS_toggle_selected_track_fx";
        description = "Custom: toggle FX bypass on selected tracks";
      }
      {
        path = "User/create-region-from-time-selection.lua";
        source = createRegionScript;
        commandId = "RS_create_region_from_time_selection";
        description = "Custom: create named region from time selection";
      }
    ];

    customActions = [
      {
        name = "Stop and save project";
        commandId = "CA_stop_and_save_project";
        actions = [
          1016 # Transport: Stop
          40026 # File: Save project
        ];
        showInActionsMenu = true;
      }
    ];

    keyBindings = with reaperActions;
      bindings [
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
        (shortcut {
          shortcut = "Ctrl+Alt+B";
          command = "RS_toggle_selected_track_fx";
          actionName = "Custom: toggle FX bypass on selected tracks";
        })
        (shortcut {
          shortcut = "Ctrl+Alt+R";
          command = "RS_create_region_from_time_selection";
          actionName = "Custom: create named region from time selection";
        })
        (shortcut {
          shortcut = "Ctrl+Alt+S";
          command = "CA_stop_and_save_project";
          actionName = "Custom: stop and save project";
        })

        (globalShortcut {
          shortcut = "Ctrl+Alt+Space";
          command = commands.transport.stop;
          scope = "global";
          actionName = "Transport: Stop";
        })
        (globalShortcut {
          shortcut = "Shift+M";
          command = 40716;
          actionName = "Toggle midi editor";
          scope = "global";
        })
      ];
  };
}
