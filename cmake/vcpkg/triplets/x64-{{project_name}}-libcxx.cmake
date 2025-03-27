set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LOAD_VCVARS_ENV ON)

set(VCPKG_C_FLAGS "-stdlib=libc++")
set(VCPKG_CXX_FLAGS "-stdlib=libc++")

if(NOT WIN32)
  set(VCPKG_CMAKE_SYSTEM_NAME Linux)
else()
  message(FATAL_ERROR "Not supported on Windows")
endif()
