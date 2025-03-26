cmake_minimum_required(VERSION 3.23)

if(DEFINED _CAKE_WAS_INIT)
  message("######################################################")
  message("Cake was already included")
  message("######################################################")
  message(FATAL_ERROR "Quitting configuration")
endif()

cmake_minimum_required(VERSION 3.23)

macro(_cake_subdir_list result curdir)
  file(
    GLOB children
    RELATIVE ${curdir}
    ${curdir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${curdir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set(${result} ${dirlist})
endmacro()

function(cake_log msg)
  message(STATUS "${msg}")
endfunction()

function(cake_error msg)
  message("######################################################")
  message("${msg}")
  message("######################################################")
  message(FATAL_ERROR "Quitting configuration")
endfunction()

macro(_cake_cleanup_args)
  set(cake_argn ${ARGN})
  list(REMOVE_ITEM cake_argn ${options})

  foreach(oneValue ${oneValueArgs})
    if(ARGS_${oneValue})

      list(
        FIND
        cake_argn
        ${oneValue}
        oneValueIndex)

      list(REMOVE_AT cake_argn ${oneValueIndex})
      list(REMOVE_AT cake_argn ${oneValueIndex})
    endif()
  endforeach()

  foreach(multiValue ${multiValueArgs})
    if(ARGS_${multiValue})

      list(
        FIND
        cake_argn
        ${multiValue}
        multiValueIndex)

      list(REMOVE_AT cake_argn ${multiValueIndex})

      foreach(ignored ${ARGS_${multiValue}})
        list(REMOVE_AT cake_argn ${multiValueIndex})
      endforeach()
    endif()
  endforeach()

endmacro()

function(_cake_add_folder_impl)
  set(options RECURSIVE)
  set(oneValueArgs FOLDER ROOT)
  set(multiValueArgs)
  cmake_parse_arguments(
    ARGS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  _cake_cleanup_args(${ARGN})

  if(NOT ARGS_FOLDER)
    cake_error("Missing 'FOLDER' argument")
  endif()

  if(NOT ARGS_ROOT)
    cake_error("Missing 'FOLDER' argument")
  endif()

  cmake_path(
    APPEND
    ARGS_ROOT
    ${ARGS_FOLDER}
    OUTPUT_VARIABLE
    ARGS_FOLDER)

  set(FOLDER_TO_ADD )
  set(LIBS )
  set(FOLDER_TO_CHECK )

  # Find all folders that we need to add
  list(APPEND FOLDER_TO_CHECK "${ARGS_FOLDER}")
  while(FOLDER_TO_CHECK)
    list(POP_FRONT FOLDER_TO_CHECK CURRENT_FOLDER)
    if(EXISTS ${CURRENT_FOLDER}/CMakeLists.txt)
      list(APPEND FOLDER_TO_ADD "${CURRENT_FOLDER}")
      cmake_path(GET CURRENT_FOLDER FILENAME libname)
      if(${libname} IN_LIST LIBS)
        cake_error("Duplicate target found: ${libname}")
      endif()
      list(APPEND LIBS "${libname}")
    elseif(ARGS_RECURSIVE)
      _cake_subdir_list(subdirs ${CURRENT_FOLDER})
      foreach(subdir ${subdirs})
        list(APPEND FOLDER_TO_CHECK "${CURRENT_FOLDER}/${subdir}")
      endforeach()
    endif()
  endwhile()

  # Build dependency list from folders to add
  set(UNKNOWN_DEPS )
  foreach(folder ${FOLDER_TO_ADD})
    cmake_path(GET folder FILENAME libname)

    set("DEPS_${libname}" )

    # Find all dependency files
    file(
      GLOB_RECURSE DEPENDENCY_FILES CONFIGURE_DEPENDS
      LIST_DIRECTORIES false
      ${folder}/Dependencies.cmake)

    foreach(dep_file ${DEPENDENCY_FILES})
      file(STRINGS "${dep_file}" deps)
      foreach(line ${deps})
        set(whitespace "[ \t\r\n]*")
        string(REGEX MATCH "^${whitespace}find_package${whitespace}\\(${whitespace}([a-zA-Z0-9_-]+)" match "${line}")
        if(match)
          if(${CMAKE_MATCH_1} IN_LIST LIBS)
            list(APPEND "DEPS_${libname}" "${CMAKE_MATCH_1}")
          elseif(NOT ${CMAKE_MATCH_1} IN_LIST UNKNOWN_DEPS)
            list(APPEND UNKNOWN_DEPS "${CMAKE_MATCH_1}")
          endif()
        endif()
      endforeach()
    endforeach()
  endforeach()

  # Now that we have all deps, start adding folders in the correct order
  while(FOLDER_TO_ADD)
    set(ADDED_TARGETS )

    # Find targets without any other dependencies
    foreach(candidate ${FOLDER_TO_ADD})
      cmake_path(GET candidate FILENAME candidate_libname)

      if(NOT DEPS_${candidate_libname})
        cake_log("Adding target: ${candidate_libname}")
        add_subdirectory(${candidate})
        list(REMOVE_ITEM FOLDER_TO_ADD ${candidate})
        list(APPEND ADDED_TARGETS ${candidate_libname})
      endif()
    endforeach()

    # Remove added dependencies from dependency lists
    foreach(candidate ${FOLDER_TO_ADD})
      cmake_path(GET candidate FILENAME candidate_libname)
      foreach(added ${ADDED_TARGETS})
        list(REMOVE_ITEM DEPS_${candidate_libname} ${added})
      endforeach()
    endforeach()

    if(NOT ADDED_TARGETS)
      cake_log("Failed to add any new target. Dumping remaining info")
      foreach(folder ${FOLDER_TO_ADD})
        cmake_path(GET folder FILENAME libname)
        cake_log("Remaining non-resolved dependencies for ${folder}:")
        cake_log("    ${DEPS_${libname}}")
      endforeach()
      cake_log("Unknown targets, ignored: ${UNKNOWN_DEPS}")
      cake_error("Failed to figure out dependencies")
    endif()
  endwhile()
endfunction()

function(cake_add_folder)
  if(NOT _CAKE_WAS_INIT)
    cake_error("Please call 'cake_init()' first")
  endif()

  set(options RECURSIVE)
  set(oneValueArgs FOLDER)
  set(multiValueArgs)
  cmake_parse_arguments(
    ARGS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  if(NOT ARGS_FOLDER)
    cake_error("Missing 'FOLDER' argument")
  endif()

  if(ARGS_RECURSIVE)
    set(ARGS RECURSIVE)
  endif()

  _cake_add_folder_impl(
    FOLDER
    ${ARGS_FOLDER}
    ROOT
    ${CMAKE_CURRENT_LIST_DIR}
    ${ARGS})

endfunction()

function(cake_init)
  if(_CAKE_WAS_INIT)
    return()
  endif()

  include(CMakePackageConfigHelpers)
  include(GNUInstallDirs)

  # Opinonated Settings of Cake
  # Heavily inspired by: https://github.com/cpp-best-practices/cmake_template
  if(NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 23)
  endif()
  set(CMAKE_CXX_EXTENSIONS OFF)
  include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/PreventInSourceBuilds.cmake)
  include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ProjectOptions.cmake)
  _cake_setup_options()
  _cake_global_options()
  _cake_local_options()

  target_compile_features(cake_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

  option(BUILD_TESTING "Build Unit Tests" OFF)

  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY
      ${CMAKE_BINARY_DIR}/bin
      CACHE PATH "Where to place executables")

  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY
      ${CMAKE_BINARY_DIR}/lib
      CACHE PATH "Where to place libs")

  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY
      ${CMAKE_BINARY_DIR}/lib
      CACHE PATH "Where to place libs")

  if(WIN32)
    set(CMAKE_PDB_OUTPUT_DIRECTORY
        ${CMAKE_BINARY_DIR}/bin
        CACHE PATH "Where to place PDB files")
    set(CMAKE_PDB_OUTPUT_DIRECTORY_DEBUG
        ${CMAKE_BINARY_DIR}/bin
        CACHE PATH "Where to place PDB files")
    set(CMAKE_PDB_OUTPUT_DIRECTORY_RELEASE
        ${CMAKE_BINARY_DIR}/bin
        CACHE PATH "Where to place PDB files")
  endif()

  if(BUILD_TESTING)
    enable_testing()
  endif()

  # Dependencies
  list(PREPEND CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}")
  set(CMAKE_PREFIX_PATH
      "${CMAKE_PREFIX_PATH}"
      PARENT_SCOPE)

  list(PREPEND CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR}")
  set(CMAKE_MODULE_PATH
      "${CMAKE_PREFIX_PATH}"
      PARENT_SCOPE)

  set(_CAKE_WAS_INIT
      1
      PARENT_SCOPE)
endfunction()

macro(_cake_add_common_parts TARGET_NAME)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Dependencies.cmake")
    include(${CMAKE_CURRENT_SOURCE_DIR}/Dependencies.cmake)
  endif()

  target_link_libraries(${TARGET_NAME} PRIVATE cake_options)
  target_link_libraries(${TARGET_NAME} PRIVATE cake_warnings)

  # Auto reference Public and Private Headers + Generated Files
  get_target_property(type ${TARGET_NAME} TYPE)
  if(${type} STREQUAL "INTERFACE_LIBRARY")
    target_include_directories(
      ${TARGET_NAME}
      INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>)
  else()
    target_include_directories(
      ${TARGET_NAME}
      PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>)
  endif()

  if(PROJECT_IS_TOP_LEVEL)
    if(BUILD_TESTING)
      if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/test)
        add_subdirectory(test)
      else()
        cake_log("${TARGET_NAME} has no tests")
      endif()
    endif()
  endif()

  get_target_property(type ${TARGET_NAME} TYPE)
  if(${type} MATCHES ".*_LIBRARY")
    configure_package_config_file(
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/templates/Config.cmake.in
      "${CMAKE_BINARY_DIR}/${TARGET_NAME}Config.cmake"
      INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}")
  endif()

endmacro()

function(_cake_assign_source_group)
  foreach(_source IN ITEMS ${ARGN})
    if(IS_ABSOLUTE "${_source}")
      file(
        RELATIVE_PATH
        _source_rel
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${_source}")
    else()
      set(_source_rel "${_source}")
    endif()
    get_filename_component(_source_path "${_source_rel}" PATH)
    string(
      REPLACE "/"
              "\\"
              _source_path_msvc
              "${_source_path}")
    source_group("${_source_path_msvc}" FILES "${_source}")
  endforeach()
endfunction()

function(cake_add_executable TARGET_NAME)
  if(NOT _CAKE_WAS_INIT)
    cake_error("Please call 'cake_init()' first")
  endif()

  set(options)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(
    ARGS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  _cake_cleanup_args()

  file(
    GLOB_RECURSE PUBLIC_HEADERS CONFIGURE_DEPENDS
    LIST_DIRECTORIES false
    include/*.h include/*.hpp)
  _cake_assign_source_group(${PUBLIC_HEADERS})

  file(
    GLOB_RECURSE SOURCES CONFIGURE_DEPENDS
    LIST_DIRECTORIES false
    src/*.h src/*.hpp src/*.cpp)
  _cake_assign_source_group(${SOURCES})

  file(
    GLOB_RECURSE CXX_SOURCES CONFIGURE_DEPENDS
    LIST_DIRECTORIES false
    src/*.ixx)
  _cake_assign_source_group(${CXX_SOURCES})

  add_executable(${TARGET_NAME} ${cake_argn} ${PUBLIC_HEADERS} ${SOURCES})

  if(CXX_SOURCES)
    target_sources(
      ${TARGET_NAME}
      PUBLIC FILE_SET
             CXX_MODULES
             FILES
             ${CXX_SOURCES})
  endif()

  # Set RPATH for Linux
  set_target_properties(${TARGET_NAME} PROPERTIES INSTALL_RPATH "$ORIGIN/${CMAKE_INSTALL_LIBDIR}")

  _cake_add_common_parts(${TARGET_NAME})
endfunction()

function(cake_add_library TARGET_NAME)
  if(NOT _CAKE_WAS_INIT)
    cake_error("Please call 'cake_init()' first")
  endif()

  set(options)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(
    ARGS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  _cake_cleanup_args()

  file(
    GLOB_RECURSE PUBLIC_HEADERS CONFIGURE_DEPENDS
    LIST_DIRECTORIES false
    include/*.h include/*.hpp)
  _cake_assign_source_group(${PUBLIC_HEADERS})

  file(
    GLOB_RECURSE SOURCES CONFIGURE_DEPENDS
    LIST_DIRECTORIES false
    src/*.h src/*.hpp src/*.cpp)
  _cake_assign_source_group(${SOURCES})

  file(
    GLOB_RECURSE CXX_SOURCES CONFIGURE_DEPENDS
    LIST_DIRECTORIES false
    src/*.ixx)
  _cake_assign_source_group(${CXX_SOURCES})

  add_library(${TARGET_NAME} ${cake_argn} ${PUBLIC_HEADERS} ${SOURCES})
  add_library(${TARGET_NAME}::${TARGET_NAME} ALIAS ${TARGET_NAME})

  if(CXX_SOURCES)
    target_sources(
      ${TARGET_NAME}
      PUBLIC FILE_SET
             CXX_MODULES
             FILES
             ${CXX_SOURCES})
  endif()

  target_sources(
    ${TARGET_NAME}
    PUBLIC FILE_SET
           public_headers
           TYPE
           HEADERS
           BASE_DIRS
           include
           FILES
           ${PUBLIC_HEADERS})

  _cake_add_common_parts(${TARGET_NAME})

  get_target_property(type ${TARGET_NAME} TYPE)
  if(${type} STREQUAL "INTERFACE_LIBRARY")
    target_include_directories(${TARGET_NAME} INTERFACE $<INSTALL_INTERFACE:include>)
  else()
    target_include_directories(${TARGET_NAME} PUBLIC $<INSTALL_INTERFACE:include>)
  endif()
endfunction()
