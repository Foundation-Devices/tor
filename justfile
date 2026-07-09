# SPDX-FileCopyrightText: 2022 Foundation Devices Inc.
#

# SPDX-License-Identifier: MIT
format:
    cargo fmt --manifest-path rust/Cargo.toml && \
    dart format . && \
    flutter analyze

codegen:
    flutter_rust_bridge_codegen generate
    dart format .
    cargo fmt --manifest-path rust/Cargo.toml
    if [ "$(uname -s)" = "Darwin" ]; then \
        scripts/build_apple_xcframework.sh release; \
    else \
        echo "Skipping Apple xcframework build on $(uname -s)"; \
    fi
