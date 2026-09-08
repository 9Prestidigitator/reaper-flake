{
  reaperAppearance,
  reaperGeneral,
  reaperMouse,
  ...
}: {
  programs.reaper.preferences = {
    general = {
      startupSettings = {
        openProjectOnStartup = reaperGeneral.openProjectOnStartup.prompt;

        # REAPER itself is updated by Nix.
        automaticallyCheckForNewVersions = false;
        createNewProjectTabWhenOpeningMedia = true;
        showSplashScreenOnStartup = false;
        skipAnimation = true;
        checkForMultipleInstancesWhenLaunching = true;
        checkForMultipleInstancesWhenLaunchingWithProjectMedia = true;
      };

      recentProjectList = {
        maximumProjects = 50;
        displayProjectTitle = true;
        display = reaperGeneral.recentProjectListDisplay.fileNameAndFullPath;
        addLoadedProjects = true;
        addSaveCopyProjects = true;
        removeOldProjectWhenSavingNewVersion = true;
      };

      preventOsScreensaverWhenAudioActiveOrRendering = true;

      filenameAutoIncrement = {
        suffix = "_001";
        ensureAutoIncrementedFilenamesHaveHigherNumberThanSimilarNamedFiles = true;
        treatUnderscoreAndDashAsInterchangeable = true;
      };

      advancedUiSystemTweaks = {
        uiScale = 1.0;
        fontSizeAdjustment = 1.0;
        allowSnapGridRoutingWindowsToStayOpen = true;
        allowKeyboardCommandsEvenWhenMouseEditing = false;
        modalWindowPositioning = reaperGeneral.modalWindowPositioning.lastWindowPosition;
        useLargeNonToolWindowFrames = false;
      };

      undo = {
        maximumUndoMemory = 512;
        includeSelection = {
          item = true;
          time = true;
          cursorPosition = false;
          track = false;
          envelopePoint = false;
          midiEvents = false;
        };
        keepNewestStateWhenApproachingMemoryLimit = true;
        storeMultipleRedoPathsWhenPossible = true;

        # Embedded undo histories can make projects and autosaves very large.
        saveHistoryWithProjectFiles = false;
        allowLoadingHistory = false;
        showLastUndoPointInMenuBar = true;
      };

      paths = {
        # Choose a real location for your own setup.
        defaultProjectSavePath = "~/REAPER Projects";
        defaultRenderPath = "Renders";

        # Peak files are disposable waveform caches. Keep them out of project,
        # media, and sample-library directories.
        peakCache = {
          storeAllInAlternatePath = true;
          alternatePath = "~/.cache/reaper-peaks";
        };
      };

      keyboardMultitouch = {
        useAlternateKeyboardSectionWhenRecording = true;
        commitChangesToEditFieldsAfterOneSecond = true;
        preventAltKeyFocusingMainMenu = true;
        allowSpaceKeyForNavigationInWindows = true;
        sendSpaceKeyFromPluginTextFieldsToMainWindow = false;
      };
    };

    project = {
      # Establish a project directory before recording or importing media.
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
            minutes = 5;
            mode = "whenNotRecording";
          };
        };
      };

      trackSendDefaults = {
        # Kenny Gioia uses -6 dB as the example for useful starting headroom.
        trackVolumeFaderGain = -6.0;
        mainParentSend = true;
        visibleEnvelopes = {
          preFxVolume = false;
          preFxPan = false;
          volume = false;
          pan = false;
          mute = false;
        };
        envelopePointShape = "linear";
        automationMode = "trimRead";
        armNewEnvelopes = false;
        newVolumeEnvelopes = {
          scaling = "volumeFader";
          warnWhenChangingScalingChangesEnvelopeSound = true;
        };
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
          allowEditingSourceMediaWhileComping = false;
          mediaItemsInHigherNumberedLanesMaskPlaybackOfLowerNumberedLanes = false;
        };

        trackMeterDisplay = {
          display = "stereoPeaks";
          displayGainReductionForPlugInsThatSupportIt = true;
          lufsMeasuresFirstTwoChannelsOnlyIgnoreSidechain = true;
        };

        recordArm = false;
        recordConfig = {
          monitorInput = "monitorInput";
          record = "recordInputAudioOrMidi";
          input = -1;
          automaticRecordArmWhenTrackSelected = false;
          monitorTrackMediaWhenRecording = false;
          preservePdcDelayedMonitoringInRecordedItems = false;
        };

        sendsTrackHardwareOutputs = {
          sendGain = 0.0;
          hardwareOutputGain = 0.0;
          sendHardwareOutputMode = "postFaderPostPan";
          sendsSendMidiByDefault = true;
          sendsSendAudioByDefault = true;
        };
      };

      itemFadeDefaults = {
        defaultFadeInFadeOutLength = 0.01;
        defaultCrossfadeLength = 0.01;
        defaultFadeInFadeOutShape = "logarithmic";
        defaultCrossfadeShape = "equalGain";

        # Preserve transients in imported samples, but protect edits and newly
        # recorded audio against clicks.
        importedMediaItems.fadeInFadeOut = false;
        recordedMediaItems = {
          fadeInFadeOut = true;
          overlap = "respectToolbarAutoCrossfadeButton";
        };
        splitMediaItems = {
          fadeInFadeOut = true;
          overlap = "respectToolbarAutoCrossfadeButton";
          overlapCrossfadePosition = "center";
        };
        fixedLaneCompAreas = true;
        trimContentBehindMediaEditsEnabled = "respectToolbarAutoCrossfadeButton";
        trimContentBehindRazorEditsEnabled = "respectToolbarAutoCrossfadeButton";
        limitSplitCreatedFadeCrossfadeTo = {
          enable = true;
          pixels = 50;
        };
        applyFadeInFadeOutCrossfadePreferencesToMidiItems = false;
        defaultStretchMarkerFadeSizeForNewItem = 2.5;
      };

      # Audio recordings and one-shot samples should not unexpectedly repeat;
      # MIDI and deliberately glued items remain convenient to extend as loops.
      itemLoopDefaults = {
        loopSourceFor = {
          importedItems = false;
          midiItems = true;
          recordedItems = false;
          gluedItems = true;
        };
        timeSelectionAutoPunchAudioRecordingCreatesLoopableSelection = false;
      };
    };

    audio = {
      closeAudioDeviceWhenStoppedAndApplicationIsInactive = false;
      closeAudioDeviceWhenInactiveAndTracksAreRecordArmed = false;
      closeAudioDeviceWhenStoppedAndActive = false;
      warnWhenUnableToOpenAudioDevices = true;
      warnWhenUnableToOpenMidiDevices = true;
      warnWhenEnabledMidiDevicesAreNotPresent = true;

      # Keep record-armed monitoring responsive in projects with latent or
      # oversampled mixing FX. Raise the threshold if the transitions are too
      # aggressive for a particular workflow.
      autoBypassFxOnRecordArmAffectedTracksWhosePdcExceeds = {
        enable = true;
        ms = 5.0;
      };
      onlyBypassWhileActuallyRecording = false;
      temporarilyBypassOversamplingOnRecordArmAffectedTrack = true;
      autoBypassFxEvenWhenFxConfigurationOpen = false;
      stopProcessingAudioWhileWarningOfFailedDiskWrites = true;
    };

    appearance = {
      tooltips = {
        uiElements = true;
        itemsEnvelopes = true;
        envsOnHover = true;
        peakAndLoudnessValueWhenMouseIsOverMediaItems = true;
        delay = 250;
      };
      fasterTextRendering = true;
      antialiasedFadesAndEnvelopes = true;
      horizontalGridLinesInAutomationLanes = true;
      filledAutomationEnvelopes = true;
      filledEnvelopesWhenDrawnOverMedia = false;
      envelopePointSizeScaling = 1.25;
      scaleNonSelectedPoint = 0.8;
      hightlightEditCursorOverLastSelectedTrack = true;
      showGuideLinesWhenEditing = true;
      solidEdgeOnTimeSelectionHighlight = true;
      solidEdgeOnLoopSelection = true;
      displayVerticalLineAtMousePosition = {
        enable = true;
        snap = "respectToolbarSnapButton";
      };
      playCursorWidth = 2;
      hideDockerTabsWhenSingleWindowAndSmallerThanPixels = 300;

      trackControlPanels = {
        setTrackLabelBackgroundToCustomTrackColors = true;
        tintTrackPanelBackgrounds = false;
        alignTcpControlsWhenTrackIconsOrFixedItemLanesAreUsed = true;
        showFxInserts = true;
        showSends = true;
        groupSendsWithFxInserts = false;
        groupFxParametersWithInserts = true;
        allowReorderingEmptySlotsInTcpMcpFxLists = true;
        trackGroupingIndicators = reaperAppearance.trackControlPanels.trackGroupingIndicators.ribbons;
        folderCollapseButtonCyclesTrackHeights =
          reaperAppearance.trackControlPanels.folderCollapseButtonCyclesTrackHeights.normalSmallCollapsed;
        fixedLaneCollapseButtonChangesDisplay =
          reaperAppearance.trackControlPanels.fixedLaneCollapseButtonChangesDisplay.bigSmallLanes;
        volumeFaderRange = {
          minimum = -72;
          maximum = 12;
        };
        volumeFaderShape = reaperAppearance.trackControlPanels.volumeFaderShape.maxPrecisionAt0Db;
      };

      zoomScrollOffset = {
        verticalZoomCenter = reaperAppearance.zoomScrollOffset.zoomCenter.vertical.lastSelectedTrack;
        maximumVerticalZoom = 1.0;
        envelopeLaneVerticalZoom = 0.5;
        horizontalZoomCenter = reaperAppearance.zoomScrollOffset.zoomCenter.horizontal.mouseCursor;
        limitHorizontalZoomScrollToProjectStart = true;
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
      moveEditCursorOn = {
        timeSelectionChange = true;
        razorEditChange = true;
        pastingInsertingMedia = true;
        clickingFixedLaneCompArea = true;
      };
      moveEditCursorToEndOfRecordedItemsOnRecordStop = false;
      linkLoopPointsToTimeSelection = true;
      clearLoopPointsOnClickInRuler = false;
      clearTimeSelectionWhenEditCursorMovesOnClickInArrangeView = false;
      minimumTimeSelectionLoopRazorEditLength = 5;

      midiEditor = {
        flashMidiEditorKeysOnTrackInput = true;
        horizontalGridLinesInCcLanes = true;
        eventsPerQuarterNoteWhenDrawingCcLanes = {
          value = 32;
          zoomDependent = true;
        };
        defaultShapeForCcSegment = {
          shape = "linear";
          reduceCcEventsWhenDrawing = true;
        };
        displayEmptySpaceAtTopBottomOfCcLanes = true;
        preventMouseEditsOfSingleCcEventsFromMovingPastOtherEvents = true;
        oneMidiEditorPer = "project";
        behaviorForOpenItemsInBuiltInMidiEditor = "openAllMidiInTheProject";
        whenUsingOneMidiEditorPerProject = {
          activeMidiItemFollowsSelectionChangesInArrangeView = {
            enable = true;
            type = "mediaItem";
          };
          selectionIsLinkedToVisibility = false;
          selectionIsLinkedToEditability = true;
          closeEditorWhenTheActiveItemIsDeletedInTheArrangeView = false;
        };
        makeAllMidiItemsEditableByDefaultIfTheyAreVisibleInTheEditor = false;
        avoid = {
          settingItemsOnOtherTracksEditable = true;
          settingItemsOnNonPlayingLanesVisible = true;
        };
        doubleClickOutsideTheBoundsOfAnyMediaItemToExtendTheNearestMedia = true;
        opacityOfInactiveSecondaryItem = 0.25;
        editableSecondaryItems = 0.75;
      };

      # Middle-drag hand scrolling and single-click MIDI-note insertion
      mouseModifiers = {
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
    };

    media = {
      setMediaItemsOfflineWhenApplicationIsNotActive = false;
      duplicateTakeFxWhenSplittingItems = false;
      tailLengthWhenUsingApplyFxToItemMs = 1000;
      takeFxTailLengthMs = 2000;
    };

    # Lua is built into REAPER; Python support enables the other major
    # ReaScript ecosystem without hard-coding user-specific plug-in paths.
    plugIns.reascript.python.enable = true;
  };
}
