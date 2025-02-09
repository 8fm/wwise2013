project(AkMP3Source)

set(SRC_FILES
    "AkFXSrcMP3Params.cpp"
    "Win32/AkFXSrcMP3.cpp"
    "Win32/AkMP3TagReader.cpp"
)

add_library(${PROJECT_NAME} STATIC ${SRC_FILES})

target_include_directories(${PROJECT_NAME} PRIVATE
    "."
    "../../../../../include"
)

target_link_libraries(${PROJECT_NAME})
