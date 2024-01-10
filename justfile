generate:
    flutter pub run build_runner build --delete-conflicting-outputs

format:
    cargo fmt --manifest-path rust/Cargo.toml && \
    dart format . && \
    flutter analyze
