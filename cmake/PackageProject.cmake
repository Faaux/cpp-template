function(cake_package_project)
  cmake_policy(SET CMP0103 NEW) # disallow multiple calls with the same NAME

  set(_options ARCH_INDEPENDENT # default to false
  )
  set(_oneValueArgs
      # default to the project_name:
      NAME
      COMPONENT
      # default to project version:
      VERSION
      # default to semver
      COMPATIBILITY)
  set(_multiValueArgs # recursively found for the current folder if not specified
      TARGETS)

  cmake_parse_arguments(
    _PackageProject
    "${_options}"
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")

  # Set default options
  # Define GNU standard installation directories such as CMAKE_INSTALL_DATADIR
  include(GNUInstallDirs)

  # set default packaged targets
  if(NOT _PackageProject_TARGETS)
    get_all_installable_targets(_PackageProject_TARGETS)
    message(
      STATUS "package_project: considering ${_PackageProject_TARGETS} as the exported targets")
  endif()

  # default to the name of the project or the given name
  if("${_PackageProject_NAME}" STREQUAL "")
    set(_PackageProject_NAME ${PROJECT_NAME})
  endif()

  set(_PackageProject_NAMESPACE "${_PackageProject_NAME}::")
  set(_PackageProject_EXPORT ${_PackageProject_NAME})

  # default version to the project version
  if("${_PackageProject_VERSION}" STREQUAL "")
    set(_PackageProject_VERSION ${PROJECT_VERSION})
  endif()

  # default compatibility to SameMajorVersion
  if("${_PackageProject_COMPATIBILITY}" STREQUAL "")
    set(_PackageProject_COMPATIBILITY "SameMajorVersion")
  endif()

  foreach(TARGET_NAME ${_PackageProject_TARGETS})
    get_target_property(type ${TARGET_NAME} TYPE)
    if(${type} MATCHES ".*_LIBRARY")
      configure_package_config_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/templates/Config.cmake.in
        "${CMAKE_BINARY_DIR}/${TARGET_NAME}Config.cmake"
        INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}")

      write_basic_package_version_file(
        "${CMAKE_BINARY_DIR}/${TARGET_NAME}ConfigVersion.cmake"
        VERSION "${_PackageProject_VERSION}"
        COMPATIBILITY ${_PackageProject_COMPATIBILITY})

      install(FILES "${CMAKE_BINARY_DIR}/${TARGET_NAME}Config.cmake"
                    "${CMAKE_BINARY_DIR}/${TARGET_NAME}ConfigVersion.cmake"
              DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME})

      install(
        EXPORT ${_PackageProject_EXPORT}
        FILE ${TARGET_NAME}Targets.cmake
        NAMESPACE ${_PackageProject_NAMESPACE}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME})
    endif()
  endforeach()

  install(
    TARGETS ${_PackageProject_TARGETS}
    EXPORT ${_PackageProject_EXPORT}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} FILE_SET public_headers
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

endfunction()
