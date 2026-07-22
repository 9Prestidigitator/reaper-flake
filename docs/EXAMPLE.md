# Large Example

```nix
{
  config,
  inputs,
  pkgs,
  reaperActions,
  reaperAppearance,
  reaperGeneral,
  reaperLayout,
  reaperMenus,
  reaperMouse,
  reaperWindows,
  ...
}: {
  imports = [inputs.reaper-flake.homeModules.reaper];

  programs.reaper = {
    enable = true;
    configPath = "${config.xdg.configHome}/HOME-REAPER";

    menus = {
      "${reaperMenus.sections.mainFile}" = {
        # `title` renames the menu-bar entry. An `&` defines its mnemonic.
        title = "&File";
        entries = [
          {action = 40023; label = "&New project";}
          {action = 40859; label = "New project tab";}
          reaperMenus.divider
          (reaperMenus.submenu "Project &templates" [
            {action = 40394; label = "Save project as template...";}
            {action = 48000; label = "(project template list)";}
          ])
          reaperMenus.divider
          {action = 40004; label = "&Quit";}
        ];
      };

      # Context-menu titles are stored for REAPER's Customize menus/toolbars
      # editor only; they are not rendered in the context-menu popup.
      "${reaperMenus.sections.rulerArrangeContext}" = {
        title = "Arrange context";
        entries = [{action = 40023; label = "New project";}];
      };

      "${reaperMenus.toolbars.main}" = {
        entries = [
          {action = 40023; label = "New project...";}
          {action = 40025; label = "Open project...";}
          {action = 40026; label = "Save project";}
          {action = 40021; label = "Project settings...";}
          {action = 40029; label = "Undo";}
          {action = 40030; label = "Redo";}
          {action = 40364; label = "Enable Metronome";}
          {action = 42616; label = "Marquee selection"; toolbarFlags = 1;}
          reaperMenus.divider
          {action = 40041; label = "Enable auto-crossfade";}
          {action = 1156; label = "Enable item and track media/razor edit grouping";}
          {action = 40070; label = "Move envelope points with media items";}
          {action = 1162; label = "Toggle ripple editing"; toolbarFlags = 1;}
          {action = 40145; label = "Show arrange view grid";}
          {action = 1157; label = "Enable snapping";}
          {action = 1135; label = "Enable locking";}
          {action = 42618; label = "Razor editing"; toolbarFlags = 1;}
        ];
      };
    };

    extensions = {
      reapack = {
        enable = true;

        repositories = [
          {
            name = "ReaTeam Scripts";
            url = "https://github.com/ReaTeam/ReaScripts/raw/master/index.xml";
            installNewPackages = "always";
          }
          {
            name = "ReaTeam Extensions";
            url = "https://github.com/ReaTeam/Extensions/raw/master/index.xml";
          }
        ];

        installNewPackagesWhenSynchronizing = false;
        enablePrereleasesGlobally = false;
        promptToUninstallObsoletePackages = true;
        browser.expandSynonyms = true;

        network = {
          verifyPeer = true;
          refreshIndexCacheAfterSeconds = 86400;
          fallbackProxy = "ask";
        };

        # Synchronize repositories automatically after Home Manager activation.
        synchronizeOnActivation = true;
      };
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

    theme = {
      # The active file name, from ColorThemes.
      active = "Smooth_6.ReaperThemeZip";

      # Link individual theme archives from any Nix path-producing expression.
      colorThemes = [
        ./themes/MyTheme.ReaperThemeZip
      ];

      # Theme packages contribute ColorThemes plus other REAPER resources such
      # as scripts. Their fonts are installed through home.packages.
      packages = [
        inputs.reaper-flake.packages.${pkgs.system}.smooth6-theme
        inputs.reaper-flake.packages.${pkgs.system}.reapertips-theme
      ];

      # Theme-provided SWELL colorthemes are ignored by default, keeping
      # programs.reaper.swell.colortheme authoritative.
      includeSwellColorThemes = false;
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
          useLargeNonToolWindowFrames = false;

          cpuAffinity = {
            enable = false;
            cpuIndexes = [0 2 4 6];
            preventOsRelocatingWorkerThreads = false;
          };

          processWorkingSet = {
            enable = false;
            minimum = 0;
            maximum = 0;
          };
        };

        undo = {
          maximumUndoMemory = 256;
          includeSelection = {
            item = true;
            time = false;
            cursorPosition = false;
            track = true;
            envelopePoint = false;
            midiEvents = false;
          };
          keepNewestStateWhenApproachingMemoryLimit = true;
          storeMultipleRedoPathsWhenPossible = false;
          saveHistoryWithProjectFiles = true;
          allowLoadingHistory = true;
          showLastUndoPointInMenuBar = true;
        };

        paths = {
          defaultProjectSavePath = "/home/user/Projects/REAPER";
          defaultRenderPath = "Renders";
          defaultRecordingPath = "/home/user/Music/Recordings";
          doNotCopyOrMoveMediaFromTheFollowingPaths = [
            "/home/user/Downloads/samplepack"
            "/mnt/samples"
          ];
          peakCache = {
            storeAllInAlternatePath = true;
            alternatePath = "/home/user/.cache/reaper-peaks";
            useAlternatePathForPaths = "/mnt/samples";
          };
        };

        keyboardMultitouch = {
          useAlternateKeyboardSectionWhenRecording = true;
          commitChangesToEditFieldsAfterOneSecond = true;
          preventAltKeyFocusingMainMenu = true;
          allowSpaceKeyForNavigationInWindows = true;
          sendSpaceKeyFromPluginTextFieldsToMainWindow = true;
          momentaryKeyboardSectionOverrideTimeoutMilliseconds = 1000;

          multitouch = {
            swipe = {
              enable = true;
              suppressInertia = false;
              reverse = false;
              gearing = 1.0;
            };
            zoom = {
              enable = true;
              suppressInertia = false;
              reverse = false;
              gearing = 1.0;
            };
            rotate = {
              enable = true;
              suppressInertia = false;
              reverse = false;
              gearing = 1.0;
            };
            reverseVerticalScroll = false;
            reverseHorizontalScroll = false;
            ignoreNewGestureAfterGestureMilliseconds = 150;
            ignoreScrollAfterGestureMilliseconds = 150;
          };
        };
      };

      project = {
        defaultProjectTemplate = "/home/user/.config/REAPER/ProjectTemplates/default.RPP";
        promptToSaveOnNewProject = true;
        openPropertiesOnNewProject = false;

        projectLoading = {
          lookForProjectMediaInProjectDirectoryBeforeQualifiedPath = true;
          promptWhenFilesAreNotFound = true;
          showLoadStatusAndSplash = true;
        };

        projectSaving = {
          saveFileReferencesWithRelativePathnames = true;
          defaultSaveAsWildcardPattern = "$project";
          saveNewVersionSuffix = "_001";
        };

        backups = {
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

        trackSendDefaults = {
          trackVolumeFaderGain = 0.0; # dB
          mainParentSend = true;
          visibleEnvelopes = {
            preFxVolume = false;
            preFxPan = false;
            volume = true;
            pan = false;
            mute = false;
          };
          envelopePointShape = "linear";
          automationMode = "trimRead";
          armNewEnvelopes = false;
          trackHeightInNewProjects = "medium";
          showInMixer = true;
          freeItemPositioning = false;
          fixedItemLanes = true;

          fixedLaneDefaults = {
            laneSize = "bigLanes";
            showPlayOnlyOneLane = false;
            hideLaneButtons = false;
            mediaItemsInHigherNumberedLanesMaskPlaybackOfLowerNumberedLanes = false;
            allowEditingSourceMediaWhileComping = false;
            createCompAreasForNewRecordingWhileComping = true;
            newRecordingBehavior = "newRecordingAddsLanesNewLanesPlayExclusively";
            automaticallyDeleteEmptyLanesAtBottomOfTrack = true;
          };

          trackMeterDisplay = {
            display = "stereoPeaks";
            lufsMeasuresFirstTwoChannelsOnlyIgnoreSidechain = false;
            displayGainReductionForPlugInsThatSupportIt = true;
          };

          recordArm = false;
          recordConfig = {
            monitorInput = "monitorInput";
            monitorTrackMediaWhenRecording = false;
            preservePdcDelayedMonitoringInRecordedItems = false;
            record = "recordInputAudioOrMidi";
            input = -1; # Input: None; device and MIDI values are hardware-dependent.
            automaticRecordArmWhenTrackSelected = false;
          };

          newVolumeEnvelopes = {
            scaling = "volumeFader";
            warnWhenChangingScalingChangesEnvelopeSound = true;
          };

          sendsTrackHardwareOutputs = {
            sendGain = 0.0; # dB
            hardwareOutputGain = 0.0; # dB
            sendHardwareOutputMode = "postFaderPostPan";
            sendsSendMidiByDefault = true;
            sendsSendAudioByDefault = true;
          };
        };
      };

      appearance = {
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

      rawSections = {
        reaper_routing = {
          window_x = 80;
          window_y = 80;
          window_w = 900;
          window_h = 420;
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
