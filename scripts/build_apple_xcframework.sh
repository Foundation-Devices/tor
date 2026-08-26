#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
# SPDX-License-Identifier: MIT

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CRATE_DIR="$ROOT_DIR/rust"
CRATE_NAME="rust_lib_tor"
BUILD_MODE="${1:-release}"
BUILD_DIR="$ROOT_DIR/build/apple-xcframework"
CARGO_TARGET_DIR="$BUILD_DIR/cargo"
IOS_MIN_VERSION="13.0"
MACOS_MIN_VERSION="10.15"

case "$BUILD_MODE" in
  release)
    PROFILE_DIR="release"
    CARGO_PROFILE_ARGS=(--release)
    ;;
  debug)
    PROFILE_DIR="debug"
    CARGO_PROFILE_ARGS=()
    ;;
  *)
    echo "Usage: $0 [release|debug]" >&2
    exit 64
    ;;
esac

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 69
  fi
}

configure_apple_toolchain() {
  if [ "$(uname -s)" != "Darwin" ]; then
    return
  fi

  if [ ! -x /usr/bin/xcrun ]; then
    return
  fi

  # Nix's Darwin shell points SDKROOT/DEVELOPER_DIR at a macOS-only SDK and
  # shadows Apple's xcrun. Cross-compiling iOS needs Xcode's real SDK lookup.
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
  unset SDKROOT
  unset DEVELOPER_DIR
  unset CC CXX AR RANLIB LD NM STRIP OBJCOPY OBJDUMP AS
  unset CC_FOR_TARGET CXX_FOR_TARGET AR_FOR_TARGET RANLIB_FOR_TARGET
  unset LD_FOR_TARGET NM_FOR_TARGET STRIP_FOR_TARGET OBJCOPY_FOR_TARGET
  unset OBJDUMP_FOR_TARGET AS_FOR_TARGET
  unset NIX_CC NIX_CC_FOR_TARGET NIX_BINTOOLS NIX_BINTOOLS_FOR_TARGET
  unset NIX_CFLAGS_COMPILE NIX_CFLAGS_COMPILE_FOR_TARGET
  unset NIX_LDFLAGS NIX_LDFLAGS_FOR_TARGET

  local nix_wrapper_var
  for nix_wrapper_var in ${!NIX_CC_WRAPPER_@} ${!NIX_BINTOOLS_WRAPPER_@} ${!NIX_PKG_CONFIG_WRAPPER_@}; do
    unset "$nix_wrapper_var"
  done

  unset CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH CMAKE_PREFIX_PATH
  unset NIXPKGS_CMAKE_PREFIX_PATH
  unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH OBJC_INCLUDE_PATH
  unset LIBRARY_PATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH
  unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR
  unset PKG_CONFIG PKG_CONFIG_FOR_TARGET
  unset PKG_CONFIG_ALLOW_CROSS PKG_CONFIG_ALL_STATIC PKG_CONFIG_ALL_DYNAMIC

  export IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN_VERSION"
  export MACOSX_DEPLOYMENT_TARGET="$MACOS_MIN_VERSION"
}

target_has_core() {
  local target_libdir="$1"

  for file in "$target_libdir"/libcore-*.rlib; do
    if [ -f "$file" ]; then
      return 0
    fi
  done

  return 1
}

ensure_rust_target() {
  local target="$1"
  local target_libdir
  target_libdir="$(rustc --print target-libdir --target "$target")"

  if target_has_core "$target_libdir"; then
    return
  fi

  local sysroot
  sysroot="$(rustc --print sysroot)"
  if [[ "$sysroot" == *".rustup/toolchains/"* ]] && command -v rustup >/dev/null 2>&1; then
    rustup target add "$target"
    if target_has_core "$target_libdir"; then
      return
    fi
  fi

  echo "Rust target '$target' is not installed for the active rustc:" >&2
  echo "  $(command -v rustc)" >&2
  echo >&2
  echo "If using direnv/Nix, run 'direnv reload .' so the flake-provided Rust toolchain includes Apple targets." >&2
  echo "If using rustup, run 'rustup target add $target'." >&2
  exit 69
}

build_target() {
  local target="$1"
  ensure_rust_target "$target"
  CARGO_TARGET_DIR="$CARGO_TARGET_DIR" cargo build \
    --manifest-path "$CRATE_DIR/Cargo.toml" \
    -p "$CRATE_NAME" \
    "${CARGO_PROFILE_ARGS[@]}" \
    --target "$target"
}

dylib_for_target() {
  local target="$1"
  echo "$CARGO_TARGET_DIR/$target/$PROFILE_DIR/lib$CRATE_NAME.dylib"
}

merge_dylibs() {
  local output="$1"
  shift

  if [ "$#" -eq 1 ]; then
    cp "$1" "$output"
  else
    lipo -create "$@" -output "$output"
  fi
  install_name_tool -id "@rpath/$CRATE_NAME.framework/$CRATE_NAME" "$output"
}

write_framework_metadata() {
  local framework_dir="$1"
  local platform_name="$2"
  local minimum_version="$3"
  local bundle_style="${4:-shallow}"
  local info_dir="$framework_dir"

  if [ "$bundle_style" = "versioned" ]; then
    info_dir="$framework_dir/Resources"
  fi

  mkdir -p "$framework_dir/Headers" "$framework_dir/Modules" "$info_dir"
  cat >"$framework_dir/Headers/$CRATE_NAME.h" <<EOF
// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
// SPDX-License-Identifier: MIT
EOF
  cat >"$framework_dir/Modules/module.modulemap" <<EOF
framework module $CRATE_NAME {
  umbrella header "$CRATE_NAME.h"
  export *
  module * { export * }
}
EOF
  cat >"$info_dir/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$CRATE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.foundationdevices.rust-lib-tor</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$CRATE_NAME</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>$CRATE_VERSION</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>$platform_name</string>
  </array>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>MinimumOSVersion</key>
  <string>$minimum_version</string>
</dict>
</plist>
EOF
}

make_framework() {
  local framework_dir="$1"
  local merged_dylib="$2"
  local platform_name="$3"
  local minimum_version="$4"
  local bundle_style="${5:-shallow}"

  rm -rf "$framework_dir"
  if [ "$bundle_style" = "versioned" ]; then
    local version_dir="$framework_dir/Versions/A"
    mkdir -p "$version_dir"
    cp "$merged_dylib" "$version_dir/$CRATE_NAME"
    write_framework_metadata "$version_dir" "$platform_name" "$minimum_version" versioned
    ln -s A "$framework_dir/Versions/Current"
    ln -s Versions/Current/$CRATE_NAME "$framework_dir/$CRATE_NAME"
    ln -s Versions/Current/Headers "$framework_dir/Headers"
    ln -s Versions/Current/Modules "$framework_dir/Modules"
    ln -s Versions/Current/Resources "$framework_dir/Resources"
  else
    mkdir -p "$framework_dir"
    cp "$merged_dylib" "$framework_dir/$CRATE_NAME"
    write_framework_metadata "$framework_dir" "$platform_name" "$minimum_version"
  fi
}

create_xcframework() {
  local output="$1"
  shift

  rm -rf "$output"
  xcodebuild -create-xcframework "$@" -output "$output"
}

configure_apple_toolchain

require_tool cargo
require_tool rustc
require_tool xcrun
require_tool lipo
require_tool install_name_tool
require_tool xcodebuild

CRATE_PACKAGE_ID="$(cargo pkgid --manifest-path "$CRATE_DIR/Cargo.toml")"
CRATE_VERSION="${CRATE_PACKAGE_ID##*@}"
if [ "$CRATE_VERSION" = "$CRATE_PACKAGE_ID" ]; then
  echo "Could not determine $CRATE_NAME version from Cargo metadata" >&2
  exit 70
fi

mkdir -p "$BUILD_DIR/merged" "$BUILD_DIR/frameworks"

APPLE_TARGETS=(
  aarch64-apple-ios
  aarch64-apple-ios-sim
  x86_64-apple-ios
  aarch64-apple-darwin
  x86_64-apple-darwin
)

for target in "${APPLE_TARGETS[@]}"; do
  build_target "$target"
done

IOS_DEVICE_DYLIB="$BUILD_DIR/merged/ios-device/$CRATE_NAME"
IOS_SIM_DYLIB="$BUILD_DIR/merged/ios-simulator/$CRATE_NAME"
MACOS_DYLIB="$BUILD_DIR/merged/macos/$CRATE_NAME"

mkdir -p "$(dirname "$IOS_DEVICE_DYLIB")" "$(dirname "$IOS_SIM_DYLIB")" "$(dirname "$MACOS_DYLIB")"

merge_dylibs "$IOS_DEVICE_DYLIB" "$(dylib_for_target aarch64-apple-ios)"
merge_dylibs "$IOS_SIM_DYLIB" \
  "$(dylib_for_target aarch64-apple-ios-sim)" \
  "$(dylib_for_target x86_64-apple-ios)"
merge_dylibs "$MACOS_DYLIB" \
  "$(dylib_for_target aarch64-apple-darwin)" \
  "$(dylib_for_target x86_64-apple-darwin)"

IOS_DEVICE_FRAMEWORK="$BUILD_DIR/frameworks/ios-device/$CRATE_NAME.framework"
IOS_SIM_FRAMEWORK="$BUILD_DIR/frameworks/ios-simulator/$CRATE_NAME.framework"
MACOS_FRAMEWORK="$BUILD_DIR/frameworks/macos/$CRATE_NAME.framework"

make_framework "$IOS_DEVICE_FRAMEWORK" "$IOS_DEVICE_DYLIB" iPhoneOS "$IOS_MIN_VERSION"
make_framework "$IOS_SIM_FRAMEWORK" "$IOS_SIM_DYLIB" iPhoneSimulator "$IOS_MIN_VERSION"
make_framework "$MACOS_FRAMEWORK" "$MACOS_DYLIB" MacOSX "$MACOS_MIN_VERSION" versioned

create_xcframework "$ROOT_DIR/ios/tor/$CRATE_NAME.xcframework" \
  -framework "$IOS_DEVICE_FRAMEWORK" \
  -framework "$IOS_SIM_FRAMEWORK"

create_xcframework "$ROOT_DIR/macos/tor/$CRATE_NAME.xcframework" \
  -framework "$MACOS_FRAMEWORK"

echo "Wrote:"
echo "  ios/tor/$CRATE_NAME.xcframework"
echo "  macos/tor/$CRATE_NAME.xcframework"
