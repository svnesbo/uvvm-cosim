cmake_minimum_required(VERSION 3.15)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(uvvm-cosim-json-rpc VERSION 0.0.1 DESCRIPTION "UVVM Co-simulation JSON-RPC server for use with VHDL VHPI")

# Build one target from subdir
# https://stackoverflow.com/a/57999204
add_subdirectory(thirdparty/json-rpc-cxx EXCLUDE_FROM_ALL)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(NVC_PATH "/opt/nvc")

add_library(uvvm-cosim-vhpi SHARED src/cpp/uvvm_cosim_vhpi.cpp)
add_dependencies(uvvm-cosim-vhpi json-rpc-cxx)
target_link_libraries(uvvm-cosim-vhpi PUBLIC json-rpc-cxx)
target_include_directories(uvvm-cosim-vhpi PRIVATE thirdparty/json-rpc-cxx/include ${NVC_PATH}/include)
set_property(TARGET uvvm-cosim-vhpi PROPERTY POSITION_INDEPENDENT_CODE ON)

add_custom_target(nvc_sim
                  DEPENDS uvvm-cosim-vhpi
                  COMMAND nvc -a ${CMAKE_SOURCE_DIR}/test/vhpi_testbench.vhd
                  COMMAND nvc -e tb
                  COMMAND nvc -r --load ./libuvvm-cosim-vhpi.so tb)
