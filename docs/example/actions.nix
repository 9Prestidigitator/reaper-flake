{
  pkgs,
  reaperActions,
  ...
}: let
  toggleClickScript = pkgs.writeText "toggle-click.lua" ''
    reaper.Main_OnCommand(40364, 0)
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
