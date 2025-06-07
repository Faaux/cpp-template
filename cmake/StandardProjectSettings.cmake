# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(
    STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
  set(CMAKE_BUILD_TYPE
      RelWithDebInfo
      CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui, ccmake
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
                                               "MinSizeRel" "RelWithDebInfo")
endif()

# Generate compile_commands.json to make it easier to work with clang based
# tools
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Enhance error reporting and compiler messages
if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
  if(WIN32)
    # On Windows cuda nvcc uses cl and not clang
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-fcolor-diagnostics>
                        $<$<COMPILE_LANGUAGE:CXX>:-fcolor-diagnostics>)

    # https://learn.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=msvc-170
    add_definitions(-D_WIN32_WINNT=0x0A00)
  else()
    add_compile_options(-fcolor-diagnostics)
    if(_cake_ENABLE_FULL_STATIC)
      add_compile_options(-static)
      add_link_options(-static -static-libstdc++ -static-libgcc)
    endif()
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  if(WIN32)
    # On Windows cuda nvcc uses cl and not gcc
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-fdiagnostics-color=always>
                        $<$<COMPILE_LANGUAGE:CXX>:-fdiagnostics-color=always>)

    # https://learn.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=msvc-170
    add_definitions(-D_WIN32_WINNT=0x0A00)
  else()
    add_compile_options(-fdiagnostics-color=always)
    if(_cake_ENABLE_FULL_STATIC)
      add_compile_options(-static)
      add_link_options(-static -static-libstdc++ -static-libgcc)
    endif()
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND MSVC_VERSION GREATER 1900)
  add_compile_options(/diagnostics:column)

  # https://learn.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=msvc-170
  add_definitions(-D_WIN32_WINNT=0x0A00)
else()
  message(
    STATUS
      "No colored compiler diagnostic set for '${CMAKE_CXX_COMPILER_ID}' compiler."
  )
endif()

# run vcvarsall when msvc is used
include("${CMAKE_CURRENT_LIST_DIR}/VCEnvironment.cmake")
run_vcvarsall()
