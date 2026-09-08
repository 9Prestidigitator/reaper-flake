{
  reaperAppearance,
  reaperGeneral,
  reaperMouse,
  ...
}: {
  programs.reaper.preferences = {
    controlOscWeb = {
      controlSurfaceDisplayUpdateFrequency = 15;
      warnWhenErrorsOpeningSurfaceMidiDevices = true;
      closeControlSurfaceDevicesWhenStoppedAndNotActiveApplication = false;
      closeControlSurfaceDevicesWhenRendering = true;

      controlSurfaces = [
        {
          mode = "mackieControlUniversal";
          # Native zero-based MIDI device indexes; -1 means none.
          midiInput = 0;
          midiOutput = 0;
          surfaceOffsetTracks = 0;
          sizeTweak = 9;
          mapF1F8ToGoToMarkers = true;
        }
        {
          mode = "oscOpenSoundControl";
          deviceName = "Tablet";
          patternConfig = "";
          oscMode = "configureDeviceIpAndLocalPort";
          deviceIp = "192.0.2.10";
          devicePort = 9000;
          localListenPort = 8000;
          allowBindingMessagesToReaperActionsAndFxLearn = true;
        }
        {
          mode = "webBrowserInterface";
          runWebServerOnPort = {
            enable = true;
            port = 8080;
          };
          usernamePassword = "reaper:change-me";
          defaultInterface = "index.html";
        }
      ];
    };

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

      advancedUiSystemTweaks = {
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
        defaultProjectSavePath = "~/Projects/REAPER";
        defaultRenderPath = "Renders";
        defaultRecordingPath = "~/Music/Recordings";
        doNotCopyOrMoveMediaFromTheFollowingPaths = [
          "~/Downloads/samplepack"
          "/mnt/samples"
        ];
        peakCache = {
          storeAllInAlternatePath = true;
          alternatePath = "~/.cache/reaper-peaks";
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
          swipe.enable = true;
          zoom.enable = true;
          rotate.enable = true;
          reverseVerticalScroll = false;
          reverseHorizontalScroll = false;
          ignoreNewGestureAfterGestureMilliseconds = 150;
          ignoreScrollAfterGestureMilliseconds = 150;
        };
      };
    };

    project = {
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
          autoSaveToProjectFile = false;
          autoSaveUnsavedProjectsToTemporaryFile = true;
          autoSaveInterval = {
            minutes = 10;
            mode = "whenNotRecording";
          };
        };
      };

      trackSendDefaults = {
        trackVolumeFaderGain = 0.0;
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
        fixedItemLanes = true;

        fixedLaneDefaults = {
          laneSize = "bigLanes";
          showPlayOnlyOneLane = false;
          hideLaneButtons = false;
          createCompAreasForNewRecordingWhileComping = true;
          newRecordingBehavior = "newRecordingAddsLanesNewLanesPlayExclusively";
          automaticallyDeleteEmptyLanesAtBottomOfTrack = true;
        };

        trackMeterDisplay = {
          display = "stereoPeaks";
          displayGainReductionForPlugInsThatSupportIt = true;
        };

        recordArm = false;
        recordConfig = {
          monitorInput = "monitorInput";
          record = "recordInputAudioOrMidi";
          input = -1;
          automaticRecordArmWhenTrackSelected = false;
        };

        sendsTrackHardwareOutputs = {
          sendGain = 0.0;
          hardwareOutputGain = 0.0;
          sendHardwareOutputMode = "postFaderPostPan";
          sendsSendMidiByDefault = true;
          sendsSendAudioByDefault = true;
        };
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

    editingBehavior.mouseModifiers = {
      importedContexts = with reaperMouse; [
        contexts.arrange.middleDrag
        contexts.midiPianoRoll.leftClick
      ];

      contexts = with reaperMouse;
        merge [
          (set contexts.arrange.middleDrag modifiers.none (mouse 7))
          (set contexts.midiPianoRoll.leftClick modifiers.none (mouse 4))
        ];
    };

    # Nix and conventional user plug-in paths are appended by default.
    plugIns = {
      reascript.python.enable = true;
      vst.searchPaths = ["~/Documents/VSTs"];
      clap.searchPaths = ["~/Documents/CLAP"];
      lv2 = {
        searchPaths = ["~/.lv2-experimental"];
        enableNixPaths = false;
        enableUserPaths = false;
      };
    };
  };
}
