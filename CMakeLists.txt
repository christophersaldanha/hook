cmake_minimum_required(VERSION 3.22)

project(hook_dylib)

# Set iOS cross-compilation
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_OSX_SYSROOT iphoneos)
set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Create dylib from hook.mm
add_library(hook SHARED src/hook.mm)

# Remove lib prefix (iOS dynamic libs are just .dylib)
set_target_properties(hook PROPERTIES
  PREFIX ""
  SUFFIX ".dylib"
)
