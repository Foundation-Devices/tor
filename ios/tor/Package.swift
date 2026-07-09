// swift-tools-version: 5.9
//
// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
// SPDX-License-Identifier: MIT

import PackageDescription

let package = Package(
    name: "tor",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "tor", targets: ["tor"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "tor",
            dependencies: [
                .target(name: "rust_lib_tor"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/tor"
        ),
        .binaryTarget(
            name: "rust_lib_tor",
            path: "rust_lib_tor.xcframework"
        )
    ]
)
