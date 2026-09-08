{reaperMenus, ...}: {
  programs.reaper.menus = {
    "${reaperMenus.sections.mainFile}" = {
      # An ampersand defines the menu mnemonic.
      title = "&File";
      entries = [
        {
          action = 40023;
          label = "&New project";
        }
        {
          action = 40859;
          label = "New project tab";
        }
        reaperMenus.divider
        (reaperMenus.submenu "Project &templates" [
          {
            action = 40394;
            label = "Save project as template...";
          }
          {
            action = 48000;
            label = "(project template list)";
          }
        ])
        reaperMenus.divider
        {
          action = 40004;
          label = "&Quit";
        }
      ];
    };

    "${reaperMenus.sections.rulerArrangeContext}" = {
      # Context-menu titles only appear in the customization window.
      title = "Arrange context";
      entries = [
        {
          action = 40023;
          label = "New project";
        }
      ];
    };

    "${reaperMenus.toolbars.main}".entries = [
      {
        action = 40023;
        label = "New project...";
      }
      {
        action = 40025;
        label = "Open project...";
      }
      {
        action = 40026;
        label = "Save project";
      }
      reaperMenus.divider
      {
        action = 40364;
        label = "Enable metronome";
      }
      {
        action = 42616;
        label = "Marquee selection";
        toolbarFlags = 1;
      }
      {
        action = 42618;
        label = "Razor editing";
        toolbarFlags = 1;
      }
    ];
  };
}
