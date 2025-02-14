project(CommunicationCentral)

add_definitions(-DPROXYCENTRAL_CONNECTED)
if (MSVC)
    add_compile_options(/wd4355)
endif()

set(SRC_FILES
    "CodeBase/CommandChannel.cpp"
    "CodeBase/Communication.cpp"
    "CodeBase/CommunicationCentral.cpp"
    "CodeBase/DiscoveryChannel.cpp"
    "CodeBase/IncomingChannel.cpp"
    "CodeBase/NetworkCaptureWriter.cpp"
    "CodeBase/NotificationChannel.cpp"
    "../Common/ConsoleDiscoveryMessage.cpp"
    "../Common/IPConnectorPorts.cpp"
    "../Common/Serializer.cpp"
)

if (WIN32)
#    set(SYSTEM_INC "Win32")
    list(APPEND SRC_FILES
        "PC/GameSocket.cpp"
        "PC/GameSocketAddr.cpp"
        "PC/Network.cpp"
        "PC/stdafx.cpp"
    )
else()
#    set(SYSTEM_INC "Linux")
    list(APPEND SRC_FILES
        "POSIX/GameSocket.cpp"
        "POSIX/Network.cpp"
    )
endif()

add_library(${PROJECT_NAME} STATIC ${SRC_FILES})

target_include_directories(${PROJECT_NAME} PRIVATE
    "PC"
    "../Common"
    "CodeBase"
    "../../../../include"
    "../../SoundEngineProxy/Remote/CodeBase"
    "../../SoundEngineProxy/Common"
    "../../AkAudiolib/PC"
    "../../AkAudiolib/Common"
)

target_link_libraries(${PROJECT_NAME})

target_precompile_headers(${PROJECT_NAME}
    PRIVATE
    "PC/stdafx.h"
)
