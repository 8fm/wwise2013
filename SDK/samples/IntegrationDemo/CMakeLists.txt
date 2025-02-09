project(IntegrationDemo)

set(SRC_FILES
    "Common/Helpers.cpp"
    "Common/IntegrationDemo.cpp"
    "Common/SoundInputBase.cpp"
    "Common/SoundInputMgrBase.cpp"
    "DemoPages/BaseMenuPage.cpp"
    "DemoPages/DemoBGM.cpp"
    "DemoPages/DemoDialogueMenu.cpp"
    "DemoPages/DemoDynamicDialogue.cpp"
    "DemoPages/DemoExternalSources.cpp"
    "DemoPages/DemoFootstepsManyVariables.cpp"
    "DemoPages/DemoInteractiveMusic.cpp"
    "DemoPages/DemoLocalization.cpp"
    "DemoPages/DemoMarkers.cpp"
    "DemoPages/DemoMicrophone.cpp"
    "DemoPages/DemoMotion.cpp"
    "DemoPages/DemoMusicCallbacks.cpp"
    "DemoPages/DemoPositioning.cpp"
    "DemoPages/DemoRTPCCarEngine.cpp"
    "MenuSystem/ButtonControl.cpp"
    "MenuSystem/Control.cpp"
    "MenuSystem/Menu.cpp"
    "MenuSystem/MessagePage.cpp"
    "MenuSystem/MovableChip.cpp"
    "MenuSystem/MultiplayerPage.cpp"
    "MenuSystem/NumericControl.cpp"
    "MenuSystem/Page.cpp"
    "MenuSystem/ToggleControl.cpp"
    "MenuSystem/UniversalInput.cpp"
    "../SoundEngine/Common/AkFilePackage.cpp"
    "../SoundEngine/Common/AkFileLocationBase.cpp"
    "../SoundEngine/Common/AkFilePackageLUT.cpp"
)

set(INTEGRATION_LIBS
    AkTremoloFX
    AkMemoryMgr
    AkMotionGenerator
    AkSineSource
    AkStereoDelayFX
    AkGuitarDistortionFX
    AkSoundEngine
    AkRoomVerbFX
    AkParametricEQFX
    AkToneSource
    AkFlangerFX
    AkCompressorFX
    AkAudioInputSource
    AkMusicEngine
    AkDelayFX
    AkPitchShifterFX
    AkSilenceSource
    AkGainFX
    AkVorbisDecoder
    AkTimeStretchFX
    AkMatrixReverbFX
    AkMeterFX
    AkStreamMgr
    AkHarmonizerFX
    AkPeakLimiterFX
    AkExpanderFX
)

if (NOT ${GAME_CONFIG} STREQUAL "Final") # CommunicationCentral
    list(APPEND INTEGRATION_LIBS CommunicationCentral)
endif()

if (WIN32)
    set(STDAFX_H "Windows/stdafx.h")
    set(SYSTEM_INC
        "Windows"
        "../SoundEngine/Win32"
        "../../../dxsdk(June2010)/Include"
    )
    list(APPEND SRC_FILES
        "../SoundEngine/Win32/AkDefaultIOHookBlocking.cpp"
        "Windows/stdafx.cpp"
        "Windows/Drawing.cpp"
        "Windows/InputMgr.cpp"
        "Windows/Main.cpp"
        "Windows/Platform.cpp"
        "Windows/SoundInput.cpp"
        "Windows/SoundInputMgr.cpp"
    )
    list(APPEND INTEGRATION_LIBS
        AkMP3Source
        AkRumble
        dxguid
        ws2_32
        dinput8
        XInput
        d3d9
        D3dx9
        Winmm
    )
else()
    set(STDAFX_H "Linux/stdafx.h")
    set(SYSTEM_INC
        "Linux"
        "../SoundEngine/POSIX"
        "FreetypeRenderer"
    )
    list(APPEND SRC_FILES
        "../SoundEngine/POSIX/AkDefaultIOHookBlocking.cpp"
        "Linux/Drawing.cpp"
        "Linux/InputMgr.cpp"
        "Linux/Main.cpp"
        "Linux/SoundInput.cpp"
        "Linux/SoundInputMgr.cpp"
        "FreetypeRenderer/FreetypeGraphicRenderer.cpp"
    )
    list(APPEND INTEGRATION_LIBS
        SDL2
    )
endif()

add_executable(${PROJECT_NAME} WIN32 ${SRC_FILES})

target_include_directories(${PROJECT_NAME} PRIVATE
    ${SYSTEM_INC}
    "../../include"
    "../SoundEngine/Common"
    "Common"
    "MenuSystem"
    "DemoPages"
)

if (WIN32)
    target_link_directories(${PROJECT_NAME} PRIVATE
        "../../../dxsdk(June2010)/Lib/${GAME_PLATFORM}"
    )
    target_link_libraries(${PROJECT_NAME} ${INTEGRATION_LIBS})
else()
    target_link_libraries(${PROJECT_NAME}
        "$<LINK_GROUP:RESCAN,${INTEGRATION_LIBS}>"
    )
endif()

target_precompile_headers(${PROJECT_NAME}
    PRIVATE
    ${STDAFX_H}
)
