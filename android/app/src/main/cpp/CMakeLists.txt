cmake_minimum_required(VERSION 3.18.1)
project(eloqui_native C CXX)

# Native library for llama.cpp, whisper.cpp, piper FFI bridges
add_library(
    eloqui_native
    SHARED
    eloqui_native.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    eloqui_native
    ${log-lib}
)
