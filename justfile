# SPDX-FileCopyrightText: 2022 Foundation Devices Inc.
#

# SPDX-License-Identifier: MIT
format:
    cargo fmt --manifest-path rust/Cargo.toml && \
    dart format . && \
    flutter analyze
