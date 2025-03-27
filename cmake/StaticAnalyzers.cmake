macro(_cake_enable_iwyu)
  find_program(INCLUDE_WHAT_YOU_USE include-what-you-use)
  if(INCLUDE_WHAT_YOU_USE)
    set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE
        ${INCLUDE_WHAT_YOU_USE}
        CACHE PATH "IWYU Executable")
  else()
    message(WARNING "include-what-you-use requested but executable not found")
  endif()
endmacro()
