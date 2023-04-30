# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(tor_library VERSION 0.0.1)

add_library(tor SHARED
  "tor.c"
)

set_target_properties(tor PROPERTIES
  PUBLIC_HEADER tor.h
  OUTPUT_NAME "tor"
)

target_compile_definitions(tor PUBLIC DART_SHARED_LIB)

#add_custom_target(
#        tor_rust
#        COMMAND cargo build --manifest-path ../../src/tor-ffi/Cargo.toml
#)
#
#add_dependencies(tor tor_rust)

#add_library(tor SHARED "tor-ffi/src/lib.rs")
#
#set_target_properties(tor PROPERTIES
#  PUBLIC_HEADER tor.h
#  OUTPUT_NAME "tor"
#)
#
#target_compile_definitions(tor PUBLIC DART_SHARED_LIB)
#
#add_custom_target(
#        tor_rust
#        COMMAND cargo build
#)
#add_dependencies(tor tor_rust)