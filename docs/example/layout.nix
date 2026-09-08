{
  reaperLayout,
  reaperWindows,
  ...
}: {
  programs.reaper = {
    windows = {
      tcpHelpBar = {
        informationDisplay = reaperWindows.tcpHelpBar.informationDisplay.cpuRamUseTimeSinceLastSave;
        showMouseEditingHelp = true;
      };

      performanceMeter.cpuUtilizationDisplay =
        reaperWindows.performanceMeter.cpuUtilizationDisplay.allCoresFullyUtilized;

      mixer = {
        showFolders = true;
        showNormalTopLevelTracks = true;
        showTracksThatAreInFolders = true;
        showTracksThatHaveReceives = true;
        scrollViewWhenTracksActivated = true;
        autoArrangeTracks = true;
        groupFoldersToLeft = false;
        groupTracksThatHaveReceivesToLeft = false;
        clickableIconForFolderTracksToShowHideChildren = false;
        showMultipleRowsWhenSizePermits = true;
        showMaximumRowsEvenWhenTracksWouldFitInFewerRows = false;
        showFxInserts = true;
        showFxParameters = true;
        showSends = true;
        groupSendsWithFxInserts = false;
        allowEmptySlotsInFxLists = true;
        allowReoarderingEmptySlotsInTcpMcpSendLists = true;
        showTrackIconsInMixer = true;
        showIconForLastTrackInFolder = true;
        master = {
          showInMixer = true;
          showOnRightSide = false;
        };
      };
    };

    layout = {
      docks = {
        bottom = {
          id = 3;
          position = "bottom";
          size = 320;
          selectedPanel = "mixer";
        };

        left = {
          id = 2;
          position = "left";
          size = 395;
          selectedPanel = "explorer";
        };
      };

      mainWindow = {
        position = {
          x = 0;
          y = 0;
        };
        size = {
          width = 1600;
          height = 900;
        };
        state = reaperLayout.windowState.normal;
      };

      mixer = {
        visible = true;
        docked = true;
        dock = "bottom";
        tabOrder = 0.0;
        position = {
          x = 0;
          y = 580;
        };
        size = {
          width = 1600;
          height = 320;
        };
        maximized = false;
      };

      masterMixer = {
        visible = false;
        docked = true;
        dock = "bottom";
        tabOrder = 0.5;
        position = {
          x = 80;
          y = 80;
        };
        size = {
          width = 260;
          height = 500;
        };
      };

      transport = {
        visible = true;
        docked = true;
        dock = "bottom";
        tabOrder = 1.0;
        dockPosition = reaperWindows.transport.topOfMainWindow;
      };

      panels = {
        explorer = {
          id = "explorer";
          section = "reaper_sexplorer";
          keyStyle = "window";
          visible = true;
          docked = true;
          dock = "left";
          tabOrder = 0.5;
          raw = {
            peak_height = 80;
            volume = 4096;
          };
        };

        navigator = {
          id = "navigator";
          keyStyle = "simple";
          dock = "bottom";
          tabOrder = 0.75;
        };
      };

      rawSections.reaper_routing = {
        window_x = 80;
        window_y = 80;
        window_w = 900;
        window_h = 420;
      };
    };
  };
}
