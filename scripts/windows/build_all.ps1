# !/bin/pwsh

Write-Output "WARNING: building from Windows not confirmed working."

rustup target add x86_64-pc-windows-msvc

git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg.exe install openssl:x64-windows-static
cd ..

$env:OPENSSL_DIR = "${pwd}\installed\x64-windows-static"
$env:OPENSSL_STATIC = 'Yes'
[System.Environment]::SetEnvironmentVariable('OPENSSL_DIR', $env:OPENSSL_DIR, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('OPENSSL_STATIC', $env:OPENSSL_STATIC, [System.EnvironmentVariableTarget]::User)

New-Item -ItemType Directory -Force -Path build
$env:COMMIT = $(git log -1 --pretty=format:"%H")
$env:VERSIONS_FILE = "..\..\lib\git_versions.dart"
$env:EXAMPLE_VERSIONS_FILE = "..\..\lib\git_versions_example.dart"
Copy-Item $env:EXAMPLE_VERSIONS_FILE -Destination $env:VERSIONS_FILE -Force
$env:OS = "WINDOWS"
(Get-Content $env:VERSIONS_FILE).replace('WINDOWS_VERSION = ""', "WINDOWS_VERSION = ""${env:COMMIT}""") | Set-Content $env:VERSIONS_FILE
Copy-Item "..\..\native\tor-ffi\*" -Destination "build\rust" -Force -Recurse
cd build\rust
if (Test-Path 'env:IS_ARM ') {
    Write-Output "Building arm version"
    cargo build --target aarch64-pc-windows-msvc --release --lib

    New-Item -ItemType Directory -Force -Path target\aarch64-pc-windows-msvc\release
    Copy-Item "target\aarch64-pc-windows-msvc\release\libepic_cash_wallet.so" -Destination "target\aarch64-pc-windows-gnu\release\" -Force
} else {
    Write-Output "Building x86_64 version"
    New-Item -ItemType Directory -Force -Path target\x86_64-pc-windows-msvc\release

    cargo build --target x86_64-pc-windows-msvc --release --lib
}

# Return to /scripts/windows
cd ..
cd ..
