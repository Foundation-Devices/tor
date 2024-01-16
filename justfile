# SPDX-FileCopyrightText: 2022 Foundation Devices Inc.
#
# SPDX-License-Identifier: GPL-3.0-or-later

generate:
    dart run ffigen

format:
    cargo fmt --manifest-path rust/Cargo.toml && \
    dart format . && \
    flutter analyze
