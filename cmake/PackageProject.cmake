function(cake_package_project)
  cmake_policy(SET CMP0103 NEW) # disallow multiple calls with the same NAME

  set(_options ARCH_INDEPENDENT # default to false
  )
  set(_oneValueArgs # default to project version:
      VERSION TARGET DEPENDENCIES)
  set(_multiValueArgs)

  cmake_parse_arguments(_PackageProject "${_options}" "${_oneValueArgs}"
                        "${_multiValueArgs}" "${ARGN}")

  # Set default options Define GNU standard installation directories such as
  # CMAKE_INSTALL_DATADIR
  include(GNUInstallDirs)

  # default version to the project version
  if("${_PackageProject_VERSION}" STREQUAL "")
    set(_PackageProject_VERSION ${PROJECT_VERSION})
  endif()

  set(DEPENDENCY_INJECT ${_PackageProject_DEPENDENCIES})

  get_target_property(type ${_PackageProject_TARGET} TYPE)
  if(${type} MATCHES ".*_LIBRARY")
    configure_package_config_file(
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/templates/Config.cmake.in
      "${CMAKE_BINARY_DIR}/${_PackageProject_TARGET}Config.cmake"
      INSTALL_DESTINATION
        "${CMAKE_INSTALL_LIBDIR}/cmake/${_PackageProject_TARGET}")

    write_basic_package_version_file(
      "${CMAKE_BINARY_DIR}/${_PackageProject_TARGET}ConfigVersion.cmake"
      VERSION "${_PackageProject_VERSION}"
      COMPATIBILITY "SameMajorVersion")

    install(
      FILES "${CMAKE_BINARY_DIR}/${_PackageProject_TARGET}Config.cmake"
            "${CMAKE_BINARY_DIR}/${_PackageProject_TARGET}ConfigVersion.cmake"
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_PackageProject_TARGET})

    install(
      EXPORT ${_PackageProject_TARGET}
      FILE ${_PackageProject_TARGET}Targets.cmake
      NAMESPACE ${_PackageProject_TARGET}::
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_PackageProject_TARGET})
  endif()

  install(
    TARGETS ${_PackageProject_TARGET}
    EXPORT ${_PackageProject_TARGET}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} FILE_SET public_headers
    PUBLIC_HEADER
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
      FILE_SET cxx_modules
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_PackageProject_TARGET}
      # CXX_MODULES_BMI DESTINATION ${CMAKE_INSTALL_LIBDIR}/bmi
  )
endfunction()
