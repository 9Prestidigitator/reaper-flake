# Large Example

```nix
{
  config,
  inputs,
  reaperActions,
  reaperAppearance,
  reaperGeneral,
  reaperLayout,
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

    swell.colortheme = {
      enable = true;

      # Use "stylix" here to use stylix theme, given stylix is imported
      preset = "reapertips";

      settings = {
        default_font_face = "Liberation Sans";
        default_font_size = 13;
        menubar_height = 17;
        scrollbar_width = 14;
        focus_hilight = "#d1a660";
      };
    };

    layout = {
      dockers = {
        main = {
          id = reaperLayout.dock.mainDocker;
          position = "main";
        };

        left = {
          id = 1;
          position = "left";
          size = 320;
          preference = "0.85531396 1";
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
        docker = "main";
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
        docker = "main";
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
        docker = "main";
        dockPosition = reaperWindows.transport.topOfMainWindow;
      };

      dockedWindows = {
        explorer.docker = "left";
      };

      dockPreferences = {
        navigator = reaperLayout.dock.mainDocker;
      };

      rawSections = {
        reaper_explorer = {
          window_x = 80;
          window_y = 80;
          window_w = 900;
          window_h = 420;
        };
      };
    };

    preferences = {
      general = {
        languagePack = "";

        startupSettings = {
          openProjectOnStartup = reaperGeneral.openProjectOnStartup.newProjectIgnoreDefaultTemplate;
          automaticallyCheckForNewVersions = false;
          createNewProjectTabWhenOpeningMedia = true;
          showSplashScreenOnStartup = false;
          skipAnimation = true;
          checkForMultipleInstancesWhenLaunching = true;
          checkForMultipleInstancesWhenLaunchingWithProjectMedia = true;
        };

        recentProjectList = {
          maximumProjects = 50;
          displayProjectTitle = false;
          display = reaperGeneral.recentProjectListDisplay.fullPath;
          addLoadedProjects = true;
          addSaveCopyProjects = true;
          removeOldProjectWhenSavingNewVersion = false;
        };

        warnWhenMemoryUseReachesMegabytes = 0;
        preventOsScreensaverWhenAudioActiveOrRendering = true;

        filenameAutoIncrement = {
          suffix = "-001";
          ensureAutoIncrementedFilenamesHaveHigherNumberThanSimilarNamedFiles = false;
          treatUnderscoreAndDashAsInterchangeable = true;
        };

        unloadProjectsInBackgroundWhenQuitting = false;

        advancedUiSystemTweaks = {
          customSplashScreenImage = "/home/user/Pictures/reaper-splash.png";
          uiScale = 1.0;
          fontSizeAdjustment = 1.0;
          allowSnapGridRoutingWindowsToStayOpen = false;
          allowKeyboardCommandsEvenWhenMouseEditing = false;
          modalWindowPositioning = reaperGeneral.modalWindowPositioning.lastWindowPosition;
        };
      };

      project.backups = {
        whenSaving = {
          # These top-level save-backup modes are mutually exclusive.
          preservePreviousVersionAsRppBak = false;
          preserveAllPreviousVersionsInOneRppBak = false;
          preservePreviouslySavedVersionOfProjectAsRppBak = {
            enable = true;
            saveTimestampedBackupsToProjectBackupsSubdirectory = true;

            limitAutoSavedBackupsToMostRecent = {
              enable = true;
              count = 50;
              unit = "copies";
            };
          };
        };

        autoSave = {
          autoSaveToTimestampedFileInProjectDirectory = {
            enable = true;
            saveBackupsToProjectAutoSavesSubdirectory = true;

            limitAutoSavedBackupsToMostRecent = {
              enable = true;
              count = 50;
              unit = "copies";
            };
          };

          autoSaveToTimestampedFileInAdditionalDirectory = {
            enable = false;
            path = "/tmp/reaper-projects";

            limitAutoSavedBackupsToMostRecent = {
              enable = false;
              count = 50;
              mode = "copiesForCurrentProject";
            };
          };

          autoSaveToProjectFile = false;
          autoSaveUnsavedProjectsToTemporaryFile = true;

          autoSaveInterval = {
            minutes = 10;
            mode = "whenNotRecording";
          };

          autoSavePathForUnsavedProjects.path = "/tmp/reaper-unsaved";
        };
      };

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

        rulerGrid = {
          rulerLabelSpacing = null;
          gridLines = null;
          markerLines = null;
          showInArrangeView = null;

          divideArrangeViewVerticallyWhenRulerDisplaysTimeFramesOrSamples = {
            enable = false;
            shadeEvery = null;
          };
          divideArrangeViewVerticallyWhenRulerDisplaysBeats = {
            enable = false;
            shadeEvery = null;
          };
        };
      };

      editingBehavior = {
        mouseModifiers = {
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
      };

      plugIns = {
        nixSystemPaths = {
          enable = true;
          root = "/run/current-system/sw";
        };

        reascript.python.enable = true;

        vst = {
          searchPaths = ["~/Documents/VSTs"];
          enableUserPaths = true;
        };
        clap = {
          searchPaths = ["~/Documents/CLAP"];
          enableUserPaths = true;
        };
        lv2 = {
          searchPaths = ["~/.lv2-experimental"];
          enableUserPaths = false;
        };
      };

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
          groupFxParametersWithInserts = true;
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
