include(CMakeDependentOption)
include(CheckCXXCompilerFlag)

macro(_cake_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
     AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
     AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(_cake_setup_options)
  option(_cake_ENABLE_HARDENING "Enable hardening" ON)
  option(_cake_ENABLE_COVERAGE "Enable coverage reporting" OFF)

  _cake_supports_sanitizers()

  option(_cake_ENABLE_IPO "Enable IPO/LTO" OFF)
  option(_cake_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
  option(_cake_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
  option(_cake_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
  option(_cake_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
  option(_cake_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
  option(_cake_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
  option(_cake_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
  option(_cake_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
  option(_cake_ENABLE_CACHE "Enable ccache" ON)

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      _cake_ENABLE_IPO
      _cake_WARNINGS_AS_ERRORS
      _cake_ENABLE_USER_LINKER
      _cake_ENABLE_SANITIZER_ADDRESS
      _cake_ENABLE_SANITIZER_LEAK
      _cake_ENABLE_SANITIZER_UNDEFINED
      _cake_ENABLE_SANITIZER_THREAD
      _cake_ENABLE_SANITIZER_MEMORY
      _cake_ENABLE_CACHE)
  endif()

endmacro()

macro(_cake_global_options)
  if(_cake_ENABLE_IPO)
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/InterproceduralOptimization.cmake)
    _cake_enable_ipo()
  endif()

  _cake_supports_sanitizers()
endmacro()

macro(_cake_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    cake_log("Including Standard Project Settings")
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/StandardProjectSettings.cmake)
  endif()

  add_library(cake_warnings INTERFACE)
  add_library(cake_options INTERFACE)

  # Set MSVC compile options to be C++ conform
  if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(cake_options INTERFACE /permissive-)
    target_compile_options(cake_options INTERFACE /Zc:__cplusplus)
    target_compile_options(cake_options INTERFACE /Zc:inline)
    target_compile_options(cake_options INTERFACE /Zc:externConstexpr)
    target_compile_options(cake_options INTERFACE /Zc:preprocessor)
  endif()

  include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CompilerWarnings.cmake)
  _cake_set_project_warnings(
    cake_warnings
    ${_cake_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(_cake_ENABLE_USER_LINKER)
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Linker.cmake)
    _cake_configure_linker(cake_options)
  endif()

  include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Sanitizers.cmake)
  _cake_enable_sanitizers(
    cake_options
    ${_cake_ENABLE_SANITIZER_ADDRESS}
    ${_cake_ENABLE_SANITIZER_LEAK}
    ${_cake_ENABLE_SANITIZER_UNDEFINED}
    ${_cake_ENABLE_SANITIZER_THREAD}
    ${_cake_ENABLE_SANITIZER_MEMORY})

  set_target_properties(cake_options PROPERTIES UNITY_BUILD ${_cake_ENABLE_UNITY_BUILD})

  if(_cake_ENABLE_CACHE)
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Cache.cmake)
    _cake_enable_cache()
  endif()

  if(_cake_ENABLE_COVERAGE)
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Tests.cmake)
    _cake_enable_coverage(cake_options)
  endif()

  if(CMAKE_GENERATOR MATCHES "Visual Studio")
    add_compile_options(/MP)
    target_compile_options(cake_options INTERFACE /MP)
  endif()

endmacro()
