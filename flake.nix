# SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
#
# SPDX-License-Identifier: MIT
{
  description = "tor - Flutter plugin for managing a Tor proxy via arti";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # shortcut: remove this pin once NixOS/nixpkgs#567033 reaches nixpkgs-unstable.
    nixpkgs-flutter.url = "github:r-ryantm/nixpkgs/20e5b575be4b254021b1a8af2f5ae50d58b492c2";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-flutter,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        flutterSdk = (import nixpkgs-flutter { inherit system; }).flutter;
        appleXcrun = pkgs.writeShellScriptBin "xcrun" ''
          exec /usr/bin/xcrun "$@"
        '';
        appleCodesign = pkgs.writeShellScriptBin "codesign" ''
          exec /usr/bin/codesign "$@"
        '';

        rustToolchain = pkgs.rust-bin.stable."1.91.0".default;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              # Flutter (includes its matching Dart SDK)
              flutterSdk

              # Rust (pinned to rust-toolchain)
              rustToolchain

              # Native build tools
              cmake
              ninja
              pkg-config

              # For ffigen (libclang)
              libclang
              llvmPackages.libclang

              # Just (task runner)
              just

              # Useful for Rust development
              cargo-ndk
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              # C++ toolchain for Flutter Linux builds
              gcc
              glibc

              # Linux desktop build deps (GTK runner)
              gtk3
              pcre2
              util-linux
              libselinux
              libsepol
              libthai
              libdatrie
              libxkbcommon
              libxdmcp
              lerc
              libdeflate
              at-spi2-core
              dbus
              libepoxy
            ];

          shellHook =
            ''
              export FLUTTER_ROOT="${flutterSdk}"
              export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
            ''
            + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              # Use GCC for compiling C/C++ code (Flutter/CMake)
              export CC="${pkgs.gcc}/bin/gcc"
              export CXX="${pkgs.gcc}/bin/g++"
              # Ensure linker can find C runtime and C++ libraries
              export LIBRARY_PATH="${pkgs.glibc}/lib:${pkgs.gcc.cc.lib}/lib:$LIBRARY_PATH"
              export LD_LIBRARY_PATH="${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH"
            ''
            + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
              export PATH="${appleXcrun}/bin:${appleCodesign}/bin:$PATH"
            '';
        };
      }
    );
}
